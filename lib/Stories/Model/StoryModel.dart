// models/story_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String userId;
  final String username;
  final String userProfileImage;
  final String mediaUrl;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final StoryType type;
  final List<String> viewers;
  final bool isPrivateAccount; // Add this field

  Story({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    required this.mediaUrl,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.type,
    this.viewers = const [],
    required this.isPrivateAccount, // Add this
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isImage => type == StoryType.image;
  bool get isVideo => type == StoryType.video;
  Duration get remainingTime => expiresAt.difference(DateTime.now());


  factory Story.fromMap(Map<String, dynamic> data, String id) {
    return Story(
      id: id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userProfileImage: data['userProfileImage'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      caption: data['caption'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      type: StoryType.values.firstWhere(
            (e) => e.toString() == 'StoryType.${data['type']}',
        orElse: () => StoryType.image,
      ),
      viewers: List<String>.from(data['viewers'] ?? []),
      isPrivateAccount: data['isPrivateAccount'] ?? false, // Add this
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'type': type.name,
      'viewers': viewers,
      'isPrivateAccount': isPrivateAccount, // Add this
    };
  }
}


enum StoryType {
  image,
  video,
}