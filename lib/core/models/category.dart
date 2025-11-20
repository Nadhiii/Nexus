import 'package:flutter/material.dart';

/// Represents a user-defined transaction category.
class Category {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final bool isCustom; // To distinguish from default categories

  Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.isCustom = true,
  });

  /// Converts a Category object into a map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
      // Store color as an integer value
      'color_value': color.value,
      'is_custom': isCustom,
    };
  }

  /// Creates a Category object from a Firestore document map.
  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] as String,
      emoji: map['emoji'] as String? ?? '❓', // Fallback to a question mark emoji
      color: Color(map['color_value'] as int),
      isCustom: map['is_custom'] as bool? ?? true,
    );
  }
}
