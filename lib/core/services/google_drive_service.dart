import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleDriveService {
  static const String _vehicleDocumentsFolderName = 'Nexus - Vehicle Documents';
  static const String _challansFolderName = 'Nexus - Challans';

  final GoogleSignIn _googleSignIn;
  String? _vehicleDocumentsFolderId;
  String? _challansFolderId;

  GoogleDriveService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Get authenticated Drive API client
  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final account = await _googleSignIn.authenticate();

      final authorization = await account.authorizationClient.authorizeScopes(
        <String>['https://www.googleapis.com/auth/drive.file'],
      );
      final auth = authorization.authClient(
        scopes: <String>['https://www.googleapis.com/auth/drive.file'],
      );

      return drive.DriveApi(auth);
    } catch (e) {
      print('❌ Error getting Drive API: $e');
      return null;
    }
  }

  /// Ensure folders exist in Google Drive
  Future<void> _ensureFoldersExist(drive.DriveApi driveApi) async {
    try {
      // Check and create Vehicle Documents folder
      final vehicleQuery =
          "name='$_vehicleDocumentsFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final vehicleFileList = await driveApi.files.list(
        q: vehicleQuery,
        spaces: 'drive',
        pageSize: 1,
      );

      if (vehicleFileList.files?.isEmpty ?? true) {
        // Create folder
        final vehicleFolder = drive.File()
          ..name = _vehicleDocumentsFolderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdVehicleFolder = await driveApi.files.create(vehicleFolder);
        _vehicleDocumentsFolderId = createdVehicleFolder.id;
        print('✅ Created Vehicle Documents folder: $_vehicleDocumentsFolderId');
      } else {
        _vehicleDocumentsFolderId = vehicleFileList.files!.first.id;
        print('✅ Found Vehicle Documents folder: $_vehicleDocumentsFolderId');
      }

      // Check and create Challans folder
      final challanQuery =
          "name='$_challansFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final challanFileList = await driveApi.files.list(
        q: challanQuery,
        spaces: 'drive',
        pageSize: 1,
      );

      if (challanFileList.files?.isEmpty ?? true) {
        // Create folder
        final challanFolder = drive.File()
          ..name = _challansFolderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdChallanFolder = await driveApi.files.create(challanFolder);
        _challansFolderId = createdChallanFolder.id;
        print('✅ Created Challans folder: $_challansFolderId');
      } else {
        _challansFolderId = challanFileList.files!.first.id;
        print('✅ Found Challans folder: $_challansFolderId');
      }
    } catch (e) {
      print('❌ Error ensuring folders: $e');
    }
  }

  /// Create a subfolder in a parent folder
  Future<String?> _createSubfolder(
    drive.DriveApi driveApi,
    String parentFolderId,
    String folderName,
  ) async {
    try {
      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [parentFolderId];

      final createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      print('❌ Error creating subfolder: $e');
      return null;
    }
  }

  /// Upload a document file to Google Drive (Vehicle Documents)
  Future<String?> uploadVehicleDocument({
    required File file,
    required String bikeId,
    required String documentType,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      // Ensure folders exist
      await _ensureFoldersExist(driveApi);

      // Create bike subfolder if needed
      final bikeSubfolderName = 'Bike_$bikeId';
      String bikeFolderId =
          await _createSubfolder(
            driveApi,
            _vehicleDocumentsFolderId!,
            bikeSubfolderName,
          ) ??
          _vehicleDocumentsFolderId!;

      // Create document type subfolder
      final docTypeFolder =
          await _createSubfolder(
            driveApi,
            bikeFolderId,
            documentType.toUpperCase(),
          ) ??
          bikeFolderId;

      // Upload file
      final fileName = file.path.split('/').last;
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [docTypeFolder];

      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      print('✅ Document uploaded: ${uploadedFile.name} (${uploadedFile.id})');
      return uploadedFile.id;
    } catch (e) {
      print('❌ Error uploading document: $e');
      return null;
    }
  }

  /// Upload a challan receipt to Google Drive
  Future<String?> uploadChallanReceipt({
    required File file,
    required String bikeId,
    required String challanId,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      // Ensure folders exist
      await _ensureFoldersExist(driveApi);

      // Create bike subfolder if needed
      final bikeSubfolderName = 'Bike_$bikeId';
      String bikeFolderId =
          await _createSubfolder(
            driveApi,
            _challansFolderId!,
            bikeSubfolderName,
          ) ??
          _challansFolderId!;

      // Create challan subfolder
      final challanFolder =
          await _createSubfolder(
            driveApi,
            bikeFolderId,
            'Challan_$challanId',
          ) ??
          bikeFolderId;

      // Upload receipt file
      final fileName = file.path.split('/').last;
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [challanFolder];

      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      print('✅ Challan receipt uploaded: ${uploadedFile.name}');
      return uploadedFile.id;
    } catch (e) {
      print('❌ Error uploading challan receipt: $e');
      return null;
    }
  }

  /// Get Google Drive file URL from file ID
  static String getGoogleDriveFileUrl(String fileId) {
    return 'https://drive.google.com/file/d/$fileId/view';
  }

  /// Get Google Drive preview URL
  static String getGoogleDrivePreviewUrl(String fileId) {
    return 'https://drive.google.com/file/d/$fileId/preview';
  }

  /// Delete a file from Google Drive
  Future<bool> deleteFile(String fileId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      await driveApi.files.delete(fileId);
      print('✅ File deleted: $fileId');
      return true;
    } catch (e) {
      print('❌ Error deleting file: $e');
      return false;
    }
  }

  /// List all documents in a folder
  Future<List<drive.File>> listFilesInFolder(String folderId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return [];

      final query = "parents='$folderId' and trashed=false";
      final fileList = await driveApi.files.list(q: query, spaces: 'drive');

      return fileList.files ?? [];
    } catch (e) {
      print('❌ Error listing files: $e');
      return [];
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
