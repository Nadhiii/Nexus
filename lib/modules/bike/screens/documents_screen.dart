import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/vehicle_management_provider.dart';
import '../../../core/models/bike.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

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
    Future.microtask(() async {
      try {
        if (mounted) {
          await context.read<VehicleManagementProvider>().fetchVehicleDocuments(
            widget.bike.id,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading documents: $e')),
          );
        }
      }
    });
  }

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

        await provider.fetchVehicleDocuments(widget.bike.id);
        if (!mounted) return;
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  DateTime? _getDefaultExpiryDate(String docType) {
    final now = DateTime.now();
    switch (docType) {
      case 'insurance':
        return now.add(const Duration(days: 365));
      case 'pollution':
        return now.add(const Duration(days: 180));
      case 'rc':
        return now.add(const Duration(days: 730));
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
      backgroundColor: AppColors.darkGradient.first,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: AppColors.darkGradient.first,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text('Documents', style: AppTypography.headlineMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: Consumer<VehicleManagementProvider>(
              builder: (context, provider, _) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider.expiringDocuments.isNotEmpty)
                        _buildExpiringWarning(provider.expiringDocuments),
                      if (provider.expiredDocuments.isNotEmpty)
                        _buildExpiredWarning(provider.expiredDocuments),
                      const SizedBox(height: AppSpacing.lg),

                      _buildUploadSection(),
                      const SizedBox(height: AppSpacing.xl2),

                      _buildDocumentCategory(
                        'Registration Certificate (RC)',
                        'rc',
                        provider.rcDocuments,
                        Icons.badge,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildDocumentCategory(
                        'Insurance Policy',
                        'insurance',
                        provider.insuranceDocuments,
                        Icons.health_and_safety,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildDocumentCategory(
                        'Pollution Under Control (PUC)',
                        'pollution',
                        provider.pollutionDocuments,
                        Icons.co2,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            color: AppColors.primaryBlue,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Upload New Document',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _uploadChip('RC', 'rc'),
              _uploadChip('Insurance', 'insurance'),
              _uploadChip('PUC', 'pollution'),
              _uploadChip('Other', 'other'),
            ],
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(color: AppColors.primaryBlue),
            ),
        ],
      ),
    );
  }

  Widget _uploadChip(String label, String docType) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.cardSurface,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      side: BorderSide(color: Colors.white.withOpacity(0.1)),
      onPressed: _isUploading ? null : () => _uploadDocument(docType),
    );
  }

  Widget _buildDocumentCategory(
    String title,
    String docType,
    List documents,
    IconData headerIcon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(headerIcon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (documents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.cardDarkElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              'No documents uploaded yet.',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...documents.map((doc) => _buildDocumentTile(doc)),
      ],
    );
  }

  Widget _buildDocumentTile(dynamic doc) {
    final now = DateTime.now();
    final isExpired = doc.expiryDate != null && doc.expiryDate!.isBefore(now);
    final isExpiring =
        doc.expiryDate != null &&
        doc.expiryDate!.isBefore(now.add(const Duration(days: 30))) &&
        !isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isExpired
              ? AppColors.error.withOpacity(0.5)
              : isExpiring
              ? Colors.orange.withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
        ),
        title: Text(
          doc.fileName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: doc.expiryDate != null
            ? Text(
                'Expires: ${doc.expiryDate.toString().split(' ')[0]}',
                style: TextStyle(
                  fontSize: 11,
                  color: isExpired
                      ? AppColors.error
                      : isExpiring
                      ? Colors.orange
                      : AppColors.textTertiary,
                ),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.remove_red_eye, color: AppColors.primaryBlue),
          onPressed: () => _openDocument(doc.fileUrl),
        ),
      ),
    );
  }

  Widget _buildExpiringWarning(List docs) => _buildAlert(
    '${docs.length} document(s) expiring soon',
    Colors.orange,
    Icons.warning_amber_rounded,
  );
  Widget _buildExpiredWarning(List docs) => _buildAlert(
    '${docs.length} document(s) expired',
    AppColors.error,
    Icons.error_outline,
  );

  Widget _buildAlert(String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
