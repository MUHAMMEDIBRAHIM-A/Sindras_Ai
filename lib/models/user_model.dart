/// User profile model.
class UserModel {
  final String id;
  final String email;
  final String createdAt;

  UserModel({required this.id, required this.email, required this.createdAt});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      createdAt: json['created_at'],
    );
  }
}
