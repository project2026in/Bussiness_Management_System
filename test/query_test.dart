import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Fetch DB Schema', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp();
      print('--- BUSINESSES ---');
      final bDocs = await FirebaseFirestore.instance.collection('businesses').get();
      for (var d in bDocs.docs) {
        print('${d.id}: ${d.data()}');
      }

      print('--- EMPLOYEES ---');
      final eDocs = await FirebaseFirestore.instance.collection('employees').get();
      for (var d in eDocs.docs) {
        print('${d.id}: ${d.data()}');
      }

      print('--- DAILY REPORTS ---');
      final rDocs = await FirebaseFirestore.instance.collection('daily_reports').get();
      for (var d in rDocs.docs) {
        print('${d.id}: ${d.data()}');
      }
    } catch (e) {
      print('Error: $e');
    }
  });
}
