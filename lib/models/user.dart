class User {
  int? userId;
  String username;
  String password;
  String? token;

  User({
    this.userId,
    required this.username,
    required this.password,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['username'],
      password: json['password'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'password': password,
    'token': token,
  };
}