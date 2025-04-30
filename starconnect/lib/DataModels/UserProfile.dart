class UserProfile {
  final int id;
  final String profilePicUrl;
  final String username;
  final int followers;
  final int following;
  final List<Service> services;
  final List<CelebrityPost> posts;

  UserProfile({
    required this.id,
    required this.profilePicUrl,
    required this.username,
    required this.followers,
    required this.following,
    required this.services,
    required this.posts,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle nullable values or defaults
    var postsFromJson = json['celeb']['posts'] as List? ?? [];
    List<CelebrityPost> postList =
    postsFromJson.map((post) => CelebrityPost.fromJson(post)).toList();

    var followersFromJson = json['celeb']['followers'] as List? ?? [];
    int followersCount = followersFromJson.length;

    var servicesFromJson = json['celeb']['services'] as List? ?? [];
    List<Service> serviceList =
    servicesFromJson.map((service) => Service.fromJson(service)).toList();
    print("Services List:  $serviceList");
    return UserProfile(
      id: json['celeb']['id'],
      profilePicUrl: json['celeb']['profile_pic'] ?? '',
      followers: followersCount,
      username: json['celeb']['username'] ?? '', // Provide a default value or handle appropriately

      following: json['celeb']['following'] ?? 0, // Default value for following
      services: serviceList,
      posts: postList,
    );
  }
}

class CelebrityPost {
  final String imageURL;
  final String caption;
  final String celebName;
  final int celebId;
  final DateTime createdAt;

  CelebrityPost({
    required this.imageURL,
    required this.caption,
    required this.celebName,
    required this.celebId,
    required this.createdAt,
  });

  factory CelebrityPost.fromJson(Map<String, dynamic> json) {
    return CelebrityPost(
      imageURL: json['imageURL'] ?? '',
      caption: json['caption'] ?? '',
      celebName: json['celebname'] ?? '',
      celebId: json['celebid'] ?? 0, // Default value for celebId
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(), // Default DateTime if parsing fails
    );
  }
}

class Service {
  final int id;
  final int price;
  final String description;
  final String status;
  final int celebId;
  final int timeNeeded;

  Service({
    required this.id,
    required this.price,
    required this.description,
    required this.status,
    required this.celebId,
    required this.timeNeeded,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? 0, // Default value for id
      price: json['price'] ?? 0, // Default value for amount
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      celebId: json['celebid'] ?? 0, // Default value for celebId
      timeNeeded: json['timeNeeded'] ?? 0, // Default value for timeNeeded
    );
  }
}

