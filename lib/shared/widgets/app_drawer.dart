import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 開発用のモード切替ナビゲーション。
///
/// 本番ではデバイス（タブレット/スマホ）と向きでモードが決まるが、開発中は
/// 1画面で3モードを行き来できるよう Drawer で導線を提供する。
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.path;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text('AI Discovery\nLearning App',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          _tile(context, current, '/child', Icons.dynamic_feed,
              'Child Feed', 'タブレット・縦 / TikTok風フィード'),
          _tile(context, current, '/common', Icons.menu_book,
              'Common View', 'タブレット・横 / 親子で記事を読む'),
          _tile(context, current, '/parent', Icons.favorite,
              'Parent Dashboard', 'スマホ・縦 / 会話のきっかけ'),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String current, String path,
      IconData icon, String title, String subtitle) {
    final selected = current == path;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      selected: selected,
      onTap: () {
        Navigator.pop(context);
        if (!selected) context.go(path);
      },
    );
  }
}
