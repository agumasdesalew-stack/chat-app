class UserModel {
  final String id;
  final String firstName;
  final String? secondName;
  final String username;
  final String email;
  final DateTime lastActive;

  UserModel({
    required this.id,
    required this.firstName,
    this.secondName,
    required this.username,
    required this.email,
    required this.lastActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'],
      secondName: json['second_name'],
      username: json['username'],
      email: json['email'],
      lastActive: DateTime.parse(json['last_active']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'second_name': secondName,
        'username': username,
        'email': email,
        'last_active': lastActive.toIso8601String(),
      };
}