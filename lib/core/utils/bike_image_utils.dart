class BikeImageUtils {
  /// Map of bike model/name patterns to their image assets
  static final Map<String, String> _bikeImageMap = {
    'himalayan': 'assets/images/Garage/Himalayan.webp',
  };

  /// Normalizes bike image paths to ensure they're in the correct garage subdirectory
  static String? normalizeBikeImagePath(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    // If already has garage subdirectory, return as-is
    if (imagePath.toLowerCase().contains('garage/')) {
      return imagePath;
    }

    // If it's an asset path but missing garage subdirectory, add it
    if (imagePath.startsWith('assets/images/')) {
      return imagePath.replaceFirst('assets/images/', 'assets/images/Garage/');
    }

    // If it's just a filename, prepend the full path with garage subdirectory
    if (!imagePath.startsWith('assets/')) {
      return 'assets/images/Garage/$imagePath';
    }

    return imagePath;
  }

  /// Gets the image path for a bike, with fallback to model-based mapping
  /// If no explicit image is set, tries to find a match based on bike name/model
  static String? getBikeImagePath(
    String? imagePath,
    String? bikeName,
    String? bikeModel,
  ) {
    // First try the explicit image path
    final normalized = normalizeBikeImagePath(imagePath);
    if (normalized != null) return normalized;

    // Fallback: try to find by bike name or model using substring matching
    if (bikeName != null && bikeName.isNotEmpty) {
      final nameNormalized = bikeName.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      // Check if any map key is contained in the normalized name
      for (final mapKey in _bikeImageMap.keys) {
        if (nameNormalized.contains(mapKey)) {
          return _bikeImageMap[mapKey];
        }
      }
    }

    if (bikeModel != null && bikeModel.isNotEmpty) {
      final modelNormalized = bikeModel.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      // Check if any map key is contained in the normalized model
      for (final mapKey in _bikeImageMap.keys) {
        if (modelNormalized.contains(mapKey)) {
          return _bikeImageMap[mapKey];
        }
      }
    }

    return null;
  }
}
