import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoUtils {
  static final Map<String, String> _bankLogoMap = {
    'hdfc': 'assets/images/banks/hdfc-bank.svg',
    'hdfcbank': 'assets/images/banks/hdfc-bank.svg',
    'axis': 'assets/images/banks/axis-bank.svg',
    'axisbank': 'assets/images/banks/axis-bank.svg',
    'sbi': 'assets/images/banks/SBI-bank.svg',
    'statebankofindia': 'assets/images/banks/SBI-bank.svg',
    'unionbankofindia': 'assets/images/banks/UBI-bank.svg',
    'ubi': 'assets/images/banks/UBI-bank.svg',
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
  };

  static final Map<String, String> _subscriptionLogoMap = {
    'apple-music': 'assets/images/Subscriptions/apple-music.svg',
    'applemusic': 'assets/images/Subscriptions/apple-music.svg',
    'spotify': 'assets/images/Subscriptions/spotify.svg',
    'youtubemusic': 'assets/images/Subscriptions/YouTube-Music.png',
    'youtube-music': 'assets/images/Subscriptions/YouTube-Music.png',
    'netflix': 'assets/images/Subscriptions/netflix.svg',
    'amazon-prime': 'assets/images/Subscriptions/prime-video.svg',
    'primevideo': 'assets/images/Subscriptions/prime-video.svg',
    'amazonprime': 'assets/images/Subscriptions/prime-video.svg',
    'disney': 'assets/images/Subscriptions/jiohotstar.png',
    'appletv': 'assets/images/subscriptions/Apple-TV.png',
    'apple-tv': 'assets/images/subscriptions/Apple-TV.png',
    'disneyplus': 'assets/images/Subscriptions/jiohotstar.png',
    'disney+': 'assets/images/Subscriptions/jiohotstar.png',
    'hotstar': 'assets/images/Subscriptions/jiohotstar.png',
    'jiohotstar': 'assets/images/Subscriptions/jiohotstar.png',
    'youtube': 'assets/images/subscriptions/YouTube-Premium.png',
    'youtubepremium': 'assets/images/subscriptions/YouTube-Premium.png',
    'youtube-premium': 'assets/images/subscriptions/YouTube-Premium.png',
    'crunchyroll': 'assets/images/subscriptions/crunchyroll.svg',
    'crunchyrollpremium': 'assets/images/subscriptions/crunchyroll.svg',
    'googleplay': 'assets/images/subscriptions/google-play.svg',
    'google-play': 'assets/images/subscriptions/google-play.svg',
    'play-pass': 'assets/images/subscriptions/google-play.svg',
    'surfshark': 'assets/images/subscriptions/Surfshark.svg',
    'surfsharkvpn': 'assets/images/subscriptions/Surfshark.svg',
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
      );
    }
    return Image.asset(normalizedPath, width: size, height: size, fit: fit);
  }
}
