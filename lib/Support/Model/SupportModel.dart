// models/support_ticket.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final List<SupportMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> data, String id) {
    return SupportTicket(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'general',
      status: data['status'] ?? 'open',
      priority: data['priority'] ?? 'medium',
      messages: (data['messages'] as List<dynamic>? ?? [])
          .map((msg) => SupportMessage.fromMap(msg))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'messages': messages.map((msg) => msg.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class SupportMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isAdmin;

  SupportMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.timestamp,
    required this.isAdmin,
  });

  factory SupportMessage.fromMap(Map<String, dynamic> data) {
    return SupportMessage(
      id: data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAdmin': isAdmin,
    };
  }
}