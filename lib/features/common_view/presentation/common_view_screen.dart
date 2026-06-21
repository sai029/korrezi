import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
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
              final selected = ref
                  .watch(selectedArticleIndexProvider)
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
/// グリッドカード: radiusLg / 選択時背景 accent / elev1。
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
    final accent = scheme.secondary;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.space3),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 1.4,
        crossAxisSpacing: AppSpacing.space3,
        mainAxisSpacing: AppSpacing.space3,
      ),
      itemCount: articles.length,
      itemBuilder: (context, i) {
        final selected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: AppMotion.durBase,
            curve: AppMotion.curveStandard,
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.2)
                  : AppColors.surface,
              borderRadius: AppRadii.lg,
              border: selected
                  ? Border.all(color: accent, width: 2)
                  : Border.all(color: AppColors.ink300),
              boxShadow: AppElevation.elev1(),
            ),
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.article_outlined,
                  color: selected ? accent : AppColors.ink500,
                ),
                Text(
                  articles[i].originalTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 右ペイン: ルビ(Furigana)付きの記事リーダー。
/// calm content 原則: 背景 surface / padding space6 / 行間 1.8 / 見出し Rounded・本文 Noto。
class _ArticleReader extends StatelessWidget {
  const _ArticleReader({required this.article});
  final NewsPool article;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ColoredBox(
      color: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル: ルビ対応。child_title_with_ruby があればルビ付き表示。
            FuriganaText(
              article.childTitleWithRuby.isEmpty
                  ? article.originalTitle
                  : article.childTitleWithRuby,
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.space5),
            // 本文: Noto Sans JP + 行間 1.8 を明示（calm content 厳守）
            FuriganaText(
              article.childBodyWithRuby,
              style: textTheme.bodyLarge?.copyWith(height: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}
