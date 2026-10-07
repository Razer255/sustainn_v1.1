/// User model representing a farmer in the Sustainn platform.
/// Maps to `users/{userId}` in Firestore.
class UserModel {
  final String id;
  final String phone;
  final String name;
  final String guardianName; // Father's / husband's name
  final String language;
  final String region;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.guardianName = '',
    required this.language,
    required this.region,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      guardianName: map['guardianName'] ?? '',
      language: map['language'] ?? 'en',
      region: map['region'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'guardianName': guardianName,
      'language': language,
      'region': region,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? guardianName,
    String? language,
    String? region,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      guardianName: guardianName ?? this.guardianName,
      language: language ?? this.language,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, phone: $phone)';
}
