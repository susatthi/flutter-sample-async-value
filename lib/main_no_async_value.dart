import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'AsyncValue Sample',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('AsyncValue Sample'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // ローディングを表示する
                    setState(() {
                      isLoading = true;
                    });

                    try {
                      // ログインを実行する
                      await ref.read(userServiceProvider).login();

                      // ログインできたらスナックバーでメッセージを表示してホーム画面に遷移する
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ログインしました！'),
                        ),
                      );

                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    } catch (e) {
                      // エラーが発生したらエラーダイアログを表示する
                      await showDialog<void>(
                        context: context,
                        builder: (context) => ErrorDialog(error: e),
                      );
                    } finally {
                      // ローディングを非表示にする
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
                  child: const Text('ログイン'),
                ),
              ],
            ),
          ),
        ),
        // ローディングを表示する
        if (isLoading)
          const ColoredBox(
            color: Colors.black26,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
      ),
    );
  }
}

/// ユーザーサービスプロバイダー
final userServiceProvider = Provider(
  (_) => UserService(),
);

class UserService {
  UserService();

  /// ログインする
  Future<void> login() async {
    // ローディングを出したいので2秒待つ
    await Future<void>.delayed(const Duration(seconds: 2));

    // エラー時の動作が確認できるように1/2の確率で例外を発生させる
    if ((Random().nextInt(2) % 2).isEven) {
      throw 'ログインできませんでした。';
    }
  }
}

/// エラーダイアログ
class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('エラー'),
      content: Text(error.toString()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
