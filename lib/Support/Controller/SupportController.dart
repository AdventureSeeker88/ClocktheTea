// controllers/support_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Const/AppColors.dart';
import '../Model/SupportModel.dart';

class SupportController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive variables
  RxList<SupportTicket> tickets = <SupportTicket>[].obs;
  RxBool isLoading = false.obs;
  RxString selectedCategory = 'All'.obs;
  RxString selectedStatus = 'All'.obs;

  // Categories and priorities
  final List<String> categories = [
    'Account Issues',
    'Technical Problems',
    'Content Concerns',
    'Payment Issues',
    'Feature Requests',
    'Bug Reports',
    'General Inquiry',
    'Other'
  ];

  final List<String> priorities = [
    'Low',
    'Medium',
    'High',
    'Urgent'
  ];

  final List<String> statuses = [
    'All',
    'Open',
    'In Progress',
    'Resolved',
    'Closed'
  ];

  @override
  void onInit() {
    super.onInit();
    fetchUserTickets();
  }

  /// 🔹 Fetch user's support tickets in real-time (FIXED: No composite index required)
  void fetchUserTickets() {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;

    // Solution 1: Remove orderBy to avoid composite index requirement
    // We'll sort manually in the app instead
    _firestore
        .collection('supportTickets')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      // Sort manually by updatedAt in descending order
      final sortedTickets = snapshot.docs
          .map((doc) => SupportTicket.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      tickets.assignAll(sortedTickets);
      isLoading.value = false;
    }, onError: (error) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to load support tickets: $error');
    });
  }

  /// 🔹 Alternative method: Fetch tickets without real-time updates (if above doesn't work)
  Future<void> fetchUserTicketsOnce() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      isLoading.value = true;

      final snapshot = await _firestore
          .collection('supportTickets')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Sort manually by updatedAt in descending order
      final sortedTickets = snapshot.docs
          .map((doc) => SupportTicket.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      tickets.assignAll(sortedTickets);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to load support tickets: $e');
    }
  }

  /// 🔹 Create new support ticket
  Future<void> createSupportTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'Please log in to create a support ticket');
        return;
      }

      isLoading.value = true;

      final ticketId = _firestore.collection('supportTickets').doc().id;
      final initialMessage = SupportMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        senderId: user.uid,
        message: description,
        timestamp: DateTime.now(),
        isAdmin: false,
      );

      final newTicket = SupportTicket(
        id: ticketId,
        userId: user.uid,
        title: title,
        description: description,
        category: category,
        status: 'open',
        priority: priority.toLowerCase(),
        messages: [initialMessage],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('supportTickets')
          .doc(ticketId)
          .set(newTicket.toMap());

      isLoading.value = false;
      Get.snackbar(
        'Success',
        'Support ticket created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.teal.withOpacity(0.1),
        colorText: AppColors.textPrimary,
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to create support ticket: $e');
    }
  }

  /// 🔹 Add message to existing ticket
  Future<void> addMessageToTicket(String ticketId, String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final newMessage = SupportMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        senderId: user.uid,
        message: message,
        timestamp: DateTime.now(),
        isAdmin: false,
      );

      await _firestore
          .collection('supportTickets')
          .doc(ticketId)
          .update({
        'messages': FieldValue.arrayUnion([newMessage.toMap()]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'status': 'open', // Reopen if closed
      });

    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e');
    }
  }

  /// 🔹 Update ticket status
  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    try {
      await _firestore
          .collection('supportTickets')
          .doc(ticketId)
          .update({
        'status': newStatus.toLowerCase().replaceAll(' ', '_'),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      Get.snackbar('Updated', 'Ticket status updated to $newStatus');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update ticket status: $e');
    }
  }

  /// 🔹 Get filtered tickets based on selected filters
  List<SupportTicket> get filteredTickets {
    var filtered = tickets;

    // Filter by category
    if (selectedCategory.value != 'All') {
      filtered = filtered.where((ticket) => ticket.category == selectedCategory.value).toList().obs;
    }

    // Filter by status
    if (selectedStatus.value != 'All') {
      final statusFilter = selectedStatus.value.toLowerCase().replaceAll(' ', '_');
      filtered = filtered.where((ticket) => ticket.status == statusFilter).toList().obs;
    }

    return filtered;
  }

  /// 🔹 Get statistics
  Map<String, int> get ticketStats {
    return {
      'total': tickets.length,
      'open': tickets.where((ticket) => ticket.status == 'open').length,
      'in_progress': tickets.where((ticket) => ticket.status == 'in_progress').length,
      'resolved': tickets.where((ticket) => ticket.status == 'resolved').length,
    };
  }

  /// 🔹 Format status for display
  String formatStatus(String status) {
    return status.replaceAll('_', ' ').toTitleCase();
  }

  /// 🔹 Get status color
  Color getStatusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.rosePink;
      case 'in_progress':
        return AppColors.gold;
      case 'resolved':
        return AppColors.teal;
      case 'closed':
        return AppColors.textSecondary;
      default:
        return AppColors.deepPurple;
    }
  }

  /// 🔹 Get priority color
  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return AppColors.rosePink;
      case 'medium':
        return AppColors.gold;
      case 'low':
        return AppColors.teal;
      default:
        return AppColors.textSecondary;
    }
  }

  /// 🔹 Refresh tickets manually
  Future<void> refreshTickets() async {
    await fetchUserTicketsOnce();
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String toTitleCase() {
    return split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}