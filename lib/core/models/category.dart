import 'package:flutter/material.dart';

/// Represents a user-defined transaction category.
class Category {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final bool isCustom; // To distinguish from default categories

  /// True when this is a DEFAULT category (isCustom == false) that has
  /// a user override doc on top of it (name/emoji/color changed from
  /// the built-in definition). Purely a UI hint — never persisted to
  /// Firestore, always recomputed on load by CategoryProvider.
  final bool isModified;

  Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.isCustom = true,
    this.isModified = false,
  });

  /// Converts a Category object into a map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
      // Store color as an integer value
      'color_value': color.toARGB32(),
      'is_custom': isCustom,
    };
  }

  /// Creates a Category object from a Firestore document map.
  factory Category.fromMap(String id, Map<String, dynamic> map, {bool isModified = false}) {
    return Category(
      id: id,
      name: map['name'] as String,
      emoji:
          map['emoji'] as String? ?? '❓', // Fallback to a question mark emoji
      color: Color(map['color_value'] as int),
      isCustom: map['is_custom'] as bool? ?? true,
      isModified: isModified,
    );
  }
}