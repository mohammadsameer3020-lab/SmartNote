class UserModel {
  final String? uid;
  final String? email;
  final String? displayName;

  UserModel({this.uid, this.email, this.displayName});

  // تحويل البيانات من Firebase إلى Model
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
    );
  }

  // تحويل الـ Model إلى Map لحفظه
  Map<String, dynamic> toJson() {
    return {'uid': uid, 'email': email, 'displayName': displayName};
  }
}
