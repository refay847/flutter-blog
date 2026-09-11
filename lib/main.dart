import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/app_shell.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

void main(){WidgetsFlutterBinding.ensureInitialized();runApp(const ProviderScope(child:BlogApp()));}

class BlogApp extends ConsumerWidget{
  const BlogApp({super.key});
  @override Widget build(BuildContext c,WidgetRef ref){
    final auth=ref.watch(authStateProvider);
    return MaterialApp(
      title:'Blogspace',
      debugShowCheckedModeBanner:false,
      theme:AppTheme.light(),
      home: auth.when(
        loading: () => const _Splash(),
        error: (_, _) => const LoginPage(),
        data: (user) => user == null
            ? const LoginPage()
            : const AppShell(),
      ),
    );
  }
}
class _Splash extends StatelessWidget{const _Splash();@override Widget build(BuildContext c)=>const Scaffold(body:Center(child:CircularProgressIndicator()));}
