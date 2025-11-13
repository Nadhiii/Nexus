import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackupService {
  final GoogleSignIn _googleSignIn;

  BackupService(this._googleSignIn);

  Future<drive.DriveApi?> _getDriveApi() async {
    final googleUser = _googleSignIn.currentUser;
    if (googleUser == null) return null;

    final headers = await googleUser.authHeaders;
    final client = GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  Future<Map<String, dynamic>> getBackupStatus() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return {'isLoggedIn': false};

    final file = await _getBackupFile(driveApi);
    return {
      'isLoggedIn': true,
      'lastBackup': file?.modifiedTime,
      'fileId': file?.id,
    };
  }

  Future<void> createBackup() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('Not signed in to Google');

    final backupData = await _gatherBackupData();
    final backupJson = jsonEncode(backupData);
    final media = drive.Media(Stream.value(utf8.encode(backupJson)), backupJson.length, contentType: 'application/json');

    final file = await _getBackupFile(driveApi);

    if (file != null) {
      await driveApi.files.update(drive.File(), file.id!, uploadMedia: media);
    } else {
      final newFile = drive.File()
        ..name = 'nexus_backup.json'
        ..parents = ['appDataFolder'];
      await driveApi.files.create(newFile, uploadMedia: media);
    }
    await cleanupOldBackups();
  }

  Future<void> restoreFromBackup(String fileId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('Not signed in to Google');

    final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final backupJson = await utf8.decodeStream(media.stream);
    final backupData = jsonDecode(backupJson);

    await _restoreData(backupData);
  }

  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return [];

    final fileList = await driveApi.files.list(spaces: 'appDataFolder', $fields: 'files(id, name, modifiedTime)');
    return fileList.files?.map((f) => {'id': f.id, 'modifiedTime': f.modifiedTime}).toList() ?? [];
  }

  Future<drive.File?> _getBackupFile(drive.DriveApi driveApi) async {
    final fileList = await driveApi.files.list(spaces: 'appDataFolder', $fields: 'files(id, name, modifiedTime)');
    return fileList.files?.isEmpty ?? true ? null : fileList.files!.first;
  }

  Future<Map<String, dynamic>> _gatherBackupData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final collections = ['transactions', 'accounts', 'budgets', 'subscriptions', 'goals', 'debts', 'userProfiles'];
    final backupData = <String, dynamic>{};

    for (final collection in collections) {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).collection(collection).get();
      backupData[collection] = snapshot.docs.map((doc) => doc.data()).toList();
    }
    return backupData;
  }

  Future<void> _restoreData(Map<String, dynamic> backupData) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();

    for (final collectionName in backupData.keys) {
      final collectionRef = FirebaseFirestore.instance.collection('users').doc(userId).collection(collectionName);
      final existingDocs = await collectionRef.get();
      for (final doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      for (final docData in backupData[collectionName]) {
        batch.set(collectionRef.doc(), docData);
      }
    }
    await batch.commit();
  }

  Future<void> cleanupOldBackups() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;

    final fileList = await driveApi.files.list(spaces: 'appDataFolder', orderBy: 'modifiedTime asc');
    if (fileList.files != null && fileList.files!.length > 5) {
      for (var i = 0; i < fileList.files!.length - 5; i++) {
        await driveApi.files.delete(fileList.files![i].id!);
      }
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
