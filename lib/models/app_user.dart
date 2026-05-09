class UserSetupData {
  String nickname = "";
  String? gender;
  String? profileImagePath;
  List<String> selectedCategories = [];
}

class AppUser {
  String nickname;
  String? gender;
  String? profileImagePath;
  String bio;
  String avatar;
  int followers;
  int following;

  AppUser({
    required this.nickname,
    this.gender,
    this.profileImagePath,
    this.bio = "",
    this.avatar = "",
    this.followers = 0,
    this.following = 0,
  });
}

class EditProfileResult {
  final String nickname;
  final String? gender;
  final String? profileImagePath;
  final String bio;
  final String avatar;

  EditProfileResult({
    required this.nickname,
    this.gender,
    this.profileImagePath,
    this.bio = "",
    this.avatar = "",
  });
}