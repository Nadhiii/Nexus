import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoUtils {
  static final Map<String, String> _bankLogoMap = {
    'hdfc': 'assets/images/banks/hdfc-bank.png',
    'hdfcbank': 'assets/images/banks/hdfc-bank.png',
    'axis': 'assets/images/banks/axis-bank.png',
    'axisbank': 'assets/images/banks/axis-bank.png',
    'sbi': 'assets/images/banks/SBI-bank.png',
    'statebankofindia': 'assets/images/banks/SBI-bank.png',
    'unionbankofindia': 'assets/images/banks/UBI-bank.png',
    'ubi': 'assets/images/banks/UBI-bank.png',
    'federal': 'assets/images/banks/federal-bank.jpeg',
    'federalbank': 'assets/images/banks/federal-bank.jpeg',
    'fi': 'assets/images/banks/fi-bank.svg',
    'fibank': 'assets/images/banks/fi-bank.svg',
    'fimoney': 'assets/images/banks/fi-bank.svg',
    'idfc': 'assets/images/banks/idfc-bank.png',
    'idfcbank': 'assets/images/banks/idfc-bank.png',
    'idfcfirst': 'assets/images/banks/idfc-bank.png',
    'idfcfirstbank': 'assets/images/banks/idfc-bank.png',
    'slice': 'assets/images/banks/Slice-bank.svg',
    'slicebank': 'assets/images/banks/Slice-bank.svg',
    'bob': 'assets/images/banks/bob-bank.png',
    'bobbank': 'assets/images/banks/bob-bank.png',
    'bankofbaroda': 'assets/images/banks/bob-bank.png',
    'jiofinance': 'assets/images/banks/Jio-Finance.png',
    'jio-finance': 'assets/images/banks/Jio-Finance.png',
    'jiofinancebank': 'assets/images/banks/Jio-Finance.png',
    'jio': 'assets/images/banks/Jio-Finance.png',
  };

  static final Map<String, String> _subscriptionLogoMap = {
    'apple-music': 'assets/images/Subscriptions/apple-music.svg',
    'applemusic': 'assets/images/Subscriptions/apple-music.svg',
    'spotify': 'assets/images/Subscriptions/Spotify.png',
    'youtubemusic': 'assets/images/Subscriptions/YouTube-Music.png',
    'youtube-music': 'assets/images/Subscriptions/YouTube-Music.png',
    'netflix': 'assets/images/Subscriptions/netflix.svg',
    'amazon-prime': 'assets/images/Subscriptions/prime-video.svg',
    'primevideo': 'assets/images/Subscriptions/prime-video.svg',
    'amazonprime': 'assets/images/Subscriptions/prime-video.svg',
    'disney': 'assets/images/Subscriptions/jiohotstar.png',
    'appletv': 'assets/images/Subscriptions/Apple-TV.svg',
    'apple-tv': 'assets/images/Subscriptions/Apple-TV.svg',
    'disneyplus': 'assets/images/Subscriptions/jiohotstar.png',
    'disney+': 'assets/images/Subscriptions/jiohotstar.png',
    'hotstar': 'assets/images/Subscriptions/jiohotstar.png',
    'jiohotstar': 'assets/images/Subscriptions/jiohotstar.png',
    'youtube': 'assets/images/Subscriptions/YouTube-Premium.png',
    'youtubepremium': 'assets/images/Subscriptions/YouTube-Premium.png',
    'youtube-premium': 'assets/images/Subscriptions/YouTube-Premium.png',
    'crunchyroll': 'assets/images/Subscriptions/crunchyroll.svg',
    'crunchyrollpremium': 'assets/images/Subscriptions/crunchyroll.svg',
    'googleplay': 'assets/images/Subscriptions/google-play.svg',
    'google-play': 'assets/images/Subscriptions/google-play.svg',
    'play-pass': 'assets/images/Subscriptions/google-play.svg',
    'surfshark': 'assets/images/Subscriptions/Surfshark.png',
    'surfsharkvpn': 'assets/images/Subscriptions/Surfshark.png',
    'github': 'assets/images/Subscriptions/github.svg',
    'git-hub': 'assets/images/Subscriptions/github.svg',
    'git-hub-copilot': 'assets/images/Subscriptions/github.svg',
  };

  static String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String? bankLogoFor(String? bankName) {
    if (bankName == null || bankName.trim().isEmpty) return null;
    final normalized = _normalize(bankName);
    for (final entry in _bankLogoMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String? subscriptionLogoFor(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final normalized = _normalize(name);
    for (final entry in _subscriptionLogoMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static double bankLogoScale(String? bankName) {
    if (bankName == null || bankName.trim().isEmpty) return 1.0;
    final normalized = _normalize(bankName);
    if (normalized.contains('fi') ||
        normalized.contains('fibank') ||
        normalized.contains('fimoney')) {
      return 0.7;
    }
    if (normalized.contains('idfc')) {
      return 1.2;
    }
    if (normalized.contains('sbi') || normalized.contains('statebankofindia')) {
      return 0.6;
    }
    return 1.0;
  }

  static Widget buildLogo(
    String assetPath, {
    double? size,
    BoxFit fit = BoxFit.contain,
  }) {
    final normalizedPath = assetPath.contains('idfc-bak.png')
        ? assetPath.replaceAll('idfc-bak.png', 'idfc-bank.png')
        : assetPath;
    if (normalizedPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        normalizedPath,
        width: size,
        height: size,
        fit: fit,
        // Show a simple fallback while loading (and in many error cases)
        placeholderBuilder: (context) => _svgFallback(normalizedPath, size),
      );
    }
    // Use Image with error handling for PNG/other formats
    return Image.asset(
      normalizedPath,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image load error for $normalizedPath: $error');
        return _svgFallback(normalizedPath, size);
      },
    );
  }

  static Widget _svgFallback(String assetPath, double? size) {
    // Prefer a simple generic placeholder: a circle with initials or an icon
    final basename = assetPath.split('/').last.split('.').first;
    final label = basename.isNotEmpty ? basename[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular((size ?? 24) / 6),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
            fontSize: (size ?? 24) * 0.5,
          ),
        ),
      ),
    );
  }
}
