import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminNotificationsView extends StatefulWidget {
  const AdminNotificationsView({super.key});

  @override
  State<AdminNotificationsView> createState() => _AdminNotificationsViewState();
}

class _AdminNotificationsViewState extends State<AdminNotificationsView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _targetAudience = 'all'; // 'all', 'owners', 'employees'
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'target_audience': _targetAudience,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'admin',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully!'), backgroundColor: Colors.green),
        );
        _titleController.clear();
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications Management',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
                SizedBox(height: 8),
                Text(
                  'Broadcast messages to users and employees across the platform.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Compose Notification
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Compose Notification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          
                          // Target Audience
                          const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _targetAudience,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Users (Owners & Employees)')),
                              DropdownMenuItem(value: 'owners', child: Text('Owners Only')),
                              DropdownMenuItem(value: 'employees', child: Text('Employees Only')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _targetAudience = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Title
                          const Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'e.g., System Maintenance Update',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Message
                          const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Type your message here...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Message is required' : null,
                          ),
                          const SizedBox(height: 24),
                          
                          // Send Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isSending ? null : _sendNotification,
                              icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
                              label: Text(_isSending ? 'Sending...' : 'Send Broadcast', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                VerticalDivider(width: 1, color: Colors.grey.shade300),

                // Right Column: Sent Notifications Log
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Broadcast History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('notifications')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                              }
                              
                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      const Text('No broadcasts sent yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                    ],
                                  ),
                                );
                              }
                              
                              return ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: docs.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data() as Map<String, dynamic>;
                                  final title = data['title'] ?? 'No Title';
                                  final message = data['message'] ?? 'No Message';
                                  final audience = data['target_audience'] ?? 'all';
                                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                                  
                                  IconData audienceIcon;
                                  Color audienceColor;
                                  String audienceText;
                                  
                                  switch (audience) {
                                    case 'owners':
                                      audienceIcon = Icons.storefront;
                                      audienceColor = Colors.orange;
                                      audienceText = 'Owners';
                                      break;
                                    case 'employees':
                                      audienceIcon = Icons.badge;
                                      audienceColor = Colors.purple;
                                      audienceText = 'Employees';
                                      break;
                                    default:
                                      audienceIcon = Icons.public;
                                      audienceColor = Colors.blue;
                                      audienceText = 'All Users';
                                  }
                                  
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: audienceColor.withValues(alpha: 0.1),
                                      child: Icon(audienceIcon, color: audienceColor),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: audienceColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: audienceColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            audienceText,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: audienceColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(message),
                                        const SizedBox(height: 8),
                                        Text(
                                          DateFormat('MMM d, yyyy • h:mm a').format(timestamp),
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
