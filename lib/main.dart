import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

/// スナックバー表示用のGlobalKey
final scaffoldMessengerKeyProvider = Provider(
  (_) => GlobalKey<ScaffoldMessengerState>(),
);

/// ダイアログ表示用のGlobalKey
final navigatorKeyProvider = Provider(
  (_) => GlobalKey<NavigatorState>(),
);

/// オーバーレイローディングの表示有無
final overlayLoadingProvider = NotifierProvider<OverlayLoadingNotifier, bool>(
  OverlayLoadingNotifier.new,
);

class OverlayLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// ローディングを表示する
  void show() => state = true;

  /// ローディングを非表示にする
  void hide() => state = false;
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
      title: 'AsyncValue Sample',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const LoginPage(),
      builder: (context, child) => Consumer(
        builder: (context, ref, _) {
          final isLoading = ref.watch(overlayLoadingProvider);
          return Navigator(
            key: ref.watch(navigatorKeyProvider),
            onPopPage: (route, dynamic _) => false,
            pages: [
              MaterialPage<Widget>(
                child: Stack(
                  children: [
                    child!,
                    // ローディングを表示する
                    if (isLoading)
                      const ColoredBox(
                        color: Colors.black26,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ログイン処理結果をハンドリングする
    ref.listenAsync<void>(
      processResultProvider,
      complete: (_) => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (context) => const HomePage()),
      ),
      completeMessage: 'ログインしました！',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AsyncValue Sample'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => ref.read(userServiceProvider).login(),
              child: const Text('ログイン'),
            ),
          ],
        ),
      ),
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

/// メソッド処理結果
final processResultProvider = StateProvider<AsyncValue<void>>(
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
    final notifier = ref.read(processResultProvider.notifier);
    notifier.state = const AsyncValue.loading();
    notifier.state = await AsyncValue.guard(() async {
      // ローディングを出したいので擬似的に2秒待つ
      await Future<void>.delayed(const Duration(seconds: 2));

      // エラー時の動作が確認できるように1/2の確率で例外を発生させる
      if ((Random().nextInt(2) % 2).isEven) {
        throw 'ログインできませんでした。';
      }
    });
  }
}

extension WidgetRefEx on WidgetRef {
  /// AsyncValueを良い感じにハンドリングする
  void listenAsync<T>(
    ProviderListenable<AsyncValue<T>> asyncValueProvider, {
    void Function(T data)? complete,
    String? completeMessage,
  }) =>
      listen<AsyncValue<T>>(
        asyncValueProvider,
        (_, next) async {
          final loadingNotifier = read(overlayLoadingProvider.notifier);
          if (next.isLoading) {
            loadingNotifier.show();
            return;
          }

          next.when(
            data: (data) async {
              loadingNotifier.hide();

              // 完了メッセージがあればスナックバーを表示する
              if (completeMessage != null) {
                final messengerState =
                    read(scaffoldMessengerKeyProvider).currentState;
                messengerState?.showSnackBar(
                  SnackBar(
                    content: Text(completeMessage),
                  ),
                );
              }
              complete?.call(data);
            },
            error: (e, s) async {
              loadingNotifier.hide();

              // エラーが発生したらエラーダイアログを表示する
              await showDialog<void>(
                context: read(navigatorKeyProvider).currentContext!,
                builder: (context) => ErrorDialog(error: e),
              );
            },
            loading: loadingNotifier.show,
          );
        },
      );
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
