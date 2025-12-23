class SignUpModel {
  String? name;
  String? email;
  String? password;
  String? avatar;

  SignUpModel({this.name, this.email, this.password, this.avatar});

  SignUpModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    password = json['password'];
    avatar = json['avatar'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['email'] = email;
    data['password'] = password;
    data['avatar'] = avatar;
    return data;
  }
}
