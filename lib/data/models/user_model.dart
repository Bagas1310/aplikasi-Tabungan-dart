class UserModel {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String? profileImage;
  final String createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.profileImage,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'email': email,
    'password_hash': passwordHash,
    'profile_image': profileImage,
    'created_at': createdAt,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] as int,
    name: map['name'] as String,
    email: map['email'] as String,
    passwordHash: map['password_hash'] as String,
    profileImage: map['profile_image'] as String?,
    createdAt: map['created_at'] as String,
  );

  UserModel copyWith({String? name, String? email, String? profileImage}) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        passwordHash: passwordHash,
        profileImage: profileImage ?? this.profileImage,
        createdAt: createdAt,
      );
}
