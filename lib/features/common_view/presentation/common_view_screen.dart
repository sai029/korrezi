import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/news_pool.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../application/common_view_provider.dart';

/// Common Mode (タブレット・横) — 親子同時閲覧用の2カラム分割ビュー。
///
/// 横幅が十分なとき: 左=ナビゲーショングリッド / 右=記事リーダー(ルビ付き) の2カラム。
/// 横幅が狭いとき: 1カラムにフォールバック（リスト→選択で下に記事）。
class CommonViewScreen extends ConsumerWidget {
  const CommonViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(commonViewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('いっしょに よむ')),
      drawer: const AppDrawer(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (articles) {
          if (articles.isEmpty) {
            return const Center(child: Text('まだ記事がありません'));
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final selected = ref.watch(selectedArticleIndexProvider)
                  .clamp(0, articles.length - 1);

              final nav = _NavigationGrid(
                articles: articles,
                selectedIndex: selected,
                onSelect: (i) =>
                    ref.read(selectedArticleIndexProvider.notifier).state = i,
              );
              final reader = _ArticleReader(article: articles[selected]);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 280, child: nav),
                    const VerticalDivider(width: 1),
                    Expanded(child: reader),
                  ],
                );
              }
              // 狭い場合は縦に並べる（縦向き時のフォールバック）。
              return Column(
                children: [
                  SizedBox(height: 160, child: nav),
                  const Divider(height: 1),
                  Expanded(child: reader),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// 左ペイン: 記事を選ぶ動的ナビゲーショングリッド。
class _NavigationGrid extends StatelessWidget {
  const _NavigationGrid({
    required this.articles,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<NewsPool> articles;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: articles.length,
      itemBuilder: (context, i) {
        final selected = i == selectedIndex;
        return InkWell(
          onTap: () => onSelect(i),
          borderRadius: BorderRadius.circular(16),
          child: Card(
            color: selected ? scheme.primaryContainer : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.article_outlined),
                  const Spacer(),
                  Text(articles[i].originalTitle,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 右ペイン: ルビ(Furigana)付きの記事リーダー。
class _ArticleReader extends StatelessWidget {
  const _ArticleReader({required this.article});
  final NewsPool article;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(article.originalTitle, style: textTheme.headlineMedium),
          const SizedBox(height: 24),
          // child_body_with_ruby の markup をルビ表示。
          FuriganaText(article.childBodyWithRuby, style: textTheme.headlineSmall),
        ],
      ),
    );
  }
}
