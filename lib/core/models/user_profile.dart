class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? phone;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.phone,
    required this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
  });

  // Copy with method for immutable updates
  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? phone,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'phone': phone,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from Firestore Map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      isAnonymous: map['isAnonymous'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, displayName: $displayName, email: $email, isAnonymous: $isAnonymous)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) { return true; }
  
    return other is UserProfile &&
      other.uid == uid &&
      other.displayName == displayName &&
      other.email == email &&
      other.photoUrl == photoUrl &&
      other.phone == phone &&
      other.isAnonymous == isAnonymous;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
      displayName.hashCode ^
      email.hashCode ^
      photoUrl.hashCode ^
      phone.hashCode ^
      isAnonymous.hashCode;
  }
}
