import 'package:flutter_test/flutter_test.dart';
import 'package:blog_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
void main(){testWidgets('app boots', (tester) async { await tester.pumpWidget(const ProviderScope(child:BlogApp())); await tester.pump(); expect(find.text('Welcome back'), findsOneWidget); });}
