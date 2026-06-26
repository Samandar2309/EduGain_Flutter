// Auth domain models mirroring the backend DTOs (AuthTokens, User).

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    tokenType: json['token_type'] as String? ?? 'Bearer',
    expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
  );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    this.phone,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.cefrLevel,
    this.nativeLang = 'uz',
    this.currentXp = 0,
    this.level = 1,
    this.streakCount = 0,
  });

  final String id;
  final String role;
  final String? phone;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? cefrLevel;
  final String nativeLang;
  final int currentXp;
  final int level;
  final int streakCount;

  String get displayName => fullName ?? phone ?? email ?? 'Foydalanuvchi';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    role: json['role'] as String? ?? 'user',
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    fullName: json['full_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    cefrLevel: json['cefr_level'] as String?,
    nativeLang: json['native_lang'] as String? ?? 'uz',
    currentXp: (json['current_xp'] as num?)?.toInt() ?? 0,
    level: (json['level'] as num?)?.toInt() ?? 1,
    streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
  );
}

class AuthResult {
  const AuthResult({
    required this.tokens,
    required this.user,
    required this.isNewUser,
  });

  final AuthTokens tokens;
  final AppUser user;
  final bool isNewUser;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    isNewUser: json['is_new_user'] as bool? ?? false,
  );
}
