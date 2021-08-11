class User {
  final String id;
  final Map<String, dynamic> appMetadata;
  final Map<String, dynamic> userMetadata;
  final String aud;
  final String? email;
  final String? phone;
  final String createdAt;
  @Deprecated('Use emailConfirmedAt')
  final String? confirmedAt;
  final String? emailConfirmedAt;
  final String? phoneConfirmedAt;
  final String? lastSignInAt;
  final String role;
  final String updatedAt;

  const User({
    required this.id,
    this.appMetadata = const {},
    this.userMetadata = const {},
    required this.aud,
    required this.email,
    required this.phone,
    required this.createdAt,
    this.confirmedAt,
    this.emailConfirmedAt,
    this.phoneConfirmedAt,
    this.lastSignInAt,
    required this.role,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        appMetadata: (json['app_metadata'] ?? {}) as Map<String, dynamic>,
        userMetadata: (json['user_metadata'] ?? {}) as Map<String, dynamic>,
        aud: json['aud'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        createdAt: json['created_at'] as String,
        emailConfirmedAt: json['email_confirmed_at'] as String?,
        phoneConfirmedAt: json['phone_confirmed_at'] as String?,
        confirmedAt: json['confirmed_at'] as String?,
        lastSignInAt: json['last_sign_in_at'] as String?,
        role: json['role'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'app_metadata': appMetadata,
        'user_metadata': userMetadata,
        'aud': aud,
        'email': email,
        'created_at': createdAt,
        'confirmed_at': emailConfirmedAt,
        'last_sign_in_at': lastSignInAt,
        'role': role,
        'updated_at': updatedAt,
      };
}
