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
    // ログイン処理結果をハンドリングする
    ref.listen<AsyncValue<void>>(
      loginResultProvider,
      (_, next) async {
        if (next.isLoading) {
          // ローディングを表示する
          setState(() {
            isLoading = true;
          });
          return;
        }

        await next.when(
          data: (_) async {
            // ローディングを非表示にする
            setState(() {
              isLoading = false;
            });

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
          },
          error: (e, s) async {
            // ローディングを非表示にする
            setState(() {
              isLoading = false;
            });

            // エラーが発生したらエラーダイアログを表示する
            await showDialog<void>(
              context: context,
              builder: (context) => ErrorDialog(error: e),
            );
          },
          loading: () {
            // ローディングを表示する
            setState(() {
              isLoading = true;
            });
          },
        );
      },
    );

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
                    // ログインを実行する
                    await ref.read(userServiceProvider).login();
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

/// ログイン処理結果
final loginResultProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

/// ユーザーサービスプロバイダー
final userServiceProvider = Provider(
  UserService.new,
);

class UserService {
  UserService(this.ref);

  final Ref ref;

  /// ログインする
  Future<void> login() async {
    final notifier = ref.read(loginResultProvider.notifier);

    // ログイン結果をローディング中にする
    notifier.state = const AsyncValue.loading();

    // ログイン処理を実行する
    notifier.state = await AsyncValue.guard(() async {
      // ローディングを出したいので2秒待つ
      await Future<void>.delayed(const Duration(seconds: 2));

      // エラー時の動作が確認できるように1/2の確率で例外を発生させる
      if ((Random().nextInt(2) % 2).isEven) {
        throw 'ログインできませんでした。';
      }
    });
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
