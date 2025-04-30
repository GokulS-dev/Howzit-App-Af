class Celebrity {
  final String name;
  final String profile_pic;

  Celebrity({required this.name, required this.profile_pic});

  factory Celebrity.fromJson(Map<String, dynamic> json) {
    return Celebrity(
      name: json['username'],
      profile_pic: json['profile_pic'],
    );
  }
}
