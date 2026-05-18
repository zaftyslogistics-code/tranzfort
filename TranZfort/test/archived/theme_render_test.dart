import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/theme/app_theme.dart';

void main() {
  testWidgets('user app theme renders a scaffold with common components', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: AppBar(title: const Text('TranZfort')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Mobile',
                    helperText: 'Enter phone number',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 16),
                const Chip(label: Text('verified')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TranZfort'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
  });
}
