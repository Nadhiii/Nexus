import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/vehicle_management_provider.dart';
import '../../../core/models/bike.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Example screen showing how to upload and manage vehicle documents
class VehicleDocumentsExampleScreen extends StatefulWidget {
  final Bike bike;
  const VehicleDocumentsExampleScreen({super.key, required this.bike});

  @override
  State<VehicleDocumentsExampleScreen> createState() =>
      _VehicleDocumentsExampleScreenState();
}

class _VehicleDocumentsExampleScreenState
    extends State<VehicleDocumentsExampleScreen> {
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Load documents when screen opens
    Future.microtask(() {
      context.read<VehicleManagementProvider>().fetchVehicleDocuments(
        widget.bike.id,
      );
    });
  }

  /// Pick PDF from device and upload
  void _uploadDocument(String documentType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);

        if (!mounted) return;
        setState(() => _isUploading = true);

        final provider = context.read<VehicleManagementProvider>();
        await provider.registerDocument(
          bikeId: widget.bike.id,
          userId: widget.bike.userId,
          documentType: documentType,
          fileName: result.files.first.name,
          expiryDate: _getDefaultExpiryDate(documentType),
          description: 'Uploaded on ${DateTime.now().toString()}',
          fileSizeBytes: file.lengthSync(),
        );

        // Reload documents
        await provider.fetchVehicleDocuments(widget.bike.id);

        if (!mounted) return;
        setState(() => _isUploading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Document uploaded successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Upload failed: $e')));
    }
  }

  DateTime? _getDefaultExpiryDate(String docType) {
    final now = DateTime.now();
    switch (docType) {
      case 'insurance':
        return now.add(const Duration(days: 365)); // 1 year
      case 'pollution':
        return now.add(const Duration(days: 180)); // 6 months
      case 'rc':
        return now.add(const Duration(days: 730)); // 2 years
      default:
        return null;
    }
  }

  void _openDocument(String fileUrl) async {
    try {
      if (await canLaunchUrl(Uri.parse(fileUrl))) {
        await launchUrl(
          Uri.parse(fileUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot open document: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bike.name} - Documents'),
        backgroundColor: AppColors.transparent,
        elevation: 0,
      ),
      body: Consumer<VehicleManagementProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload buttons
                _buildUploadSection(),
                const SizedBox(height: 32),

                // Documents by category
                _buildDocumentCategory(
                  'RC Certificate',
                  'rc',
                  provider.rcDocuments,
                ),
                const SizedBox(height: 24),

                _buildDocumentCategory(
                  'Insurance',
                  'insurance',
                  provider.insuranceDocuments,
                ),
                const SizedBox(height: 24),

                _buildDocumentCategory(
                  'Pollution Certificate',
                  'pollution',
                  provider.pollutionDocuments,
                ),
                const SizedBox(height: 24),

                // Expiring documents warning
                if (provider.expiringDocuments.isNotEmpty)
                  _buildExpiringWarning(provider.expiringDocuments),

                // Expired documents warning
                if (provider.expiredDocuments.isNotEmpty)
                  _buildExpiredWarning(provider.expiredDocuments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      color: AppColors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Documents',
              style: AppTypography.titleLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _uploadButton('RC', 'rc'),
                _uploadButton('Insurance', 'insurance'),
                _uploadButton('Pollution', 'pollution'),
                _uploadButton('PUC', 'puc'),
                _uploadButton('Other', 'other'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadButton(String label, String docType) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : () => _uploadDocument(docType),
      icon: _isUploading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.upload),
      label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
    );
  }

  Widget _buildDocumentCategory(String title, String docType, List documents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        if (documents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No documents uploaded',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          )
        else
          ...documents.map((doc) => _buildDocumentTile(doc)),
      ],
    );
  }

  Widget _buildDocumentTile(dynamic doc) {
    final isExpiring =
        doc.expiryDate != null &&
        doc.expiryDate!.isBefore(DateTime.now().add(Duration(days: 30))) &&
        doc.expiryDate!.isAfter(DateTime.now());
    final isExpired =
        doc.expiryDate != null && doc.expiryDate!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpired
              ? Colors.red.withOpacity(0.5)
              : isExpiring
              ? Colors.orange.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.fileName,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (doc.expiryDate != null)
                  Text(
                    'Expires: ${doc.expiryDate.toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired
                          ? Colors.red
                          : isExpiring
                          ? Colors.orange
                          : AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openDocument(doc.fileUrl),
            tooltip: 'Open in Google Drive',
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringWarning(List documents) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${documents.length} document(s) expiring soon',
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredWarning(List documents) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${documents.length} document(s) expired',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
