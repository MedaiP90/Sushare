class LocalUser {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? profilePicturePath;
  final int avatarColorValue;
  final DateTime? createdAt;

  LocalUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profilePicturePath,
    required this.avatarColorValue,
    this.createdAt,
  });

  factory LocalUser.fromJson(Map<String, dynamic> json) {
    return LocalUser(
      id: json['id'] as String,
      username: json['username'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      profilePicturePath: json['profilePicturePath'] as String?,
      avatarColorValue: json['avatarColorValue'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'profilePicturePath': profilePicturePath,
      'avatarColorValue': avatarColorValue,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  LocalUser copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? profilePicturePath,
    int? avatarColorValue,
    DateTime? createdAt,
  }) {
    return LocalUser(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
