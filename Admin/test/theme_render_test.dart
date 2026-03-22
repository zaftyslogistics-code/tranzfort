import 'package:admin/src/core/theme/admin_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin theme renders a scaffold with common components', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AdminTheme.dark,
        home: Scaffold(
          appBar: AppBar(title: const Text('TranZfort Admin')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    helperText: 'Admin login identity',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Open queue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TranZfort Admin'), findsOneWidget);
    expect(find.text('Open queue'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}
