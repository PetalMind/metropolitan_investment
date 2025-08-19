enum SmtpSecurity { none, ssl, tls }

class SmtpSettings {
  final String host;
  final int port;
  final String username;
  final String password;
  final SmtpSecurity security;

  SmtpSettings({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.security,
  });

  factory SmtpSettings.fromFirestore(Map<String, dynamic> data) {
    return SmtpSettings(
      host: data['host'] ?? '',
      port: data['port'] ?? 587,
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      security: SmtpSecurity.values.firstWhere(
        (e) => e.name == data['security'],
        orElse: () => SmtpSecurity.tls,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'host': host,
      'port': port,
      'username': username,
      'password':
          password, // Hasło powinno być przechowywane w bezpieczny sposób
      'security': security.name,
    };
  }

  SmtpSettings copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    SmtpSecurity? security,
  }) {
    return SmtpSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      security: security ?? this.security,
    );
  }
}
