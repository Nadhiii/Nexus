import '../models/transaction.dart';
import '../models/category.dart';

String resolveTransactionDisplayLabel(
  Transaction transaction,
  List<Category> categories, {
  String emptyLabel = 'General',
}) {
  final sourceLabel = _resolveSourceLabel(transaction.metadata);
  if (sourceLabel != null && sourceLabel.isNotEmpty) {
    return sourceLabel;
  }

  final categoryId = transaction.categoryId;
  if (categoryId != null && categoryId.trim().isNotEmpty) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return categoryId;
  }

  return emptyLabel;
}

String resolveCategoryLabel(
  String? categoryIdOrLabel,
  List<Category> categories, {
  String fallback = 'General',
}) {
  if (categoryIdOrLabel == null || categoryIdOrLabel.trim().isEmpty) {
    return fallback;
  }

  for (final category in categories) {
    if (category.id == categoryIdOrLabel) {
      return category.name;
    }
  }

  return categoryIdOrLabel;
}

String? resolveSourceLabelFromMetadata(Map<String, dynamic>? metadata) {
  return _resolveSourceLabel(metadata);
}

String? _resolveSourceLabel(Map<String, dynamic>? metadata) {
  if (metadata == null || metadata.isEmpty) { return null; }

  if (metadata['source'] is String) {
    final source = (metadata['source'] as String).trim().toLowerCase();
    switch (source) {
      case 'garage':
        final bikeName = metadata['bikeName'];
        if (bikeName is String && bikeName.trim().isNotEmpty) {
          return 'Fuel Log • $bikeName';
        }
        return 'Fuel Log';
      case 'subscription':
        final subscriptionName = metadata['subscriptionName'];
        if (subscriptionName is String && subscriptionName.trim().isNotEmpty) {
          return 'Subscription • $subscriptionName';
        }
        return 'Subscription';
      case 'gmail':
        return 'Gmail Import';
      case 'nbox':
        return 'Inbox Auto';
      case 'pdf':
        return 'Imported Transaction';
      default:
        return _titleCase(source);
    }
  }

  if (metadata['importedFromPDF'] == true) {
    return 'Imported Transaction';
  }

  if (metadata['fromTemplate'] == true) {
    final templateName = metadata['templateName'];
    if (templateName is String && templateName.trim().isNotEmpty) {
      return 'Recurring • $templateName';
    }
    return 'Recurring';
  }

  return null;
}

String _titleCase(String value) {
  if (value.isEmpty) { return value; }
  final normalized = value.replaceAll(RegExp(r'[_\-]+'), ' ');
  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}
