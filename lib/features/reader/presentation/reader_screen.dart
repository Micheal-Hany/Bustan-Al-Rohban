import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../app/strings.dart';
import '../../../core/content/content_models.dart';
import '../../../core/widgets/status_views.dart';
import '../../library/data/library_repository.dart';
import '../../library/presentation/load_status.dart';
import '../domain/editorial.dart';
import '../domain/reader_items.dart';
import 'editorial_card.dart';
import 'reader_cubit.dart';
import 'text_scale_cubit.dart';

/// Reads one section. Original text is rendered exactly as stored.
class ReaderScreen extends StatelessWidget {
  const ReaderScreen({
    super.key,
    required this.saintId,
    required this.sectionId,
    this.paragraphId,
    this.editorial,
  });

  final String saintId;
  final String sectionId;

  /// Optional paragraph anchor to open at.
  final String? paragraphId;
  final EditorialSource? editorial;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ReaderCubit(
            context.read<LibraryRepository>(),
            saintId: saintId,
            sectionId: sectionId,
            paragraphId: paragraphId,
            editorial: editorial,
          )..load(),
        ),
        BlocProvider(create: (_) => TextScaleCubit()),
      ],
      child: const _ReaderView(),
    );
  }
}

class _ReaderView extends StatelessWidget {
  const _ReaderView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) {
        return Scaffold(
          key: const Key('reader-screen'),
          appBar: AppBar(
            title: Text(
              state.section?.title ?? state.saint?.title ?? AppStrings.library,
            ),
            actions: state.status == LoadStatus.loaded
                ? const [_TextSizeControls()]
                : null,
          ),
          body: _body(context, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, ReaderState state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          details: state.error ?? AppStrings.loadFailed,
          onRetry: () => context.read<ReaderCubit>().load(),
        );
      case LoadStatus.empty:
        return EmptyView(message: state.message ?? AppStrings.notFound);
      case LoadStatus.loaded:
        return _ReaderList(
          items: state.items,
          initialIndex: state.initialIndex,
        );
    }
  }
}

class _TextSizeControls extends StatelessWidget {
  const _TextSizeControls();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TextScaleCubit>();
    return BlocBuilder<TextScaleCubit, double>(
      builder: (context, scale) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            key: const Key('text-smaller'),
            tooltip: AppStrings.textSmaller,
            icon: const Icon(Icons.text_decrease),
            onPressed: cubit.canDecrease ? cubit.smaller : null,
          ),
          Text(
            '${(scale * 100).round()}%',
            key: const Key('text-scale-label'),
            textDirection: TextDirection.ltr,
          ),
          IconButton(
            key: const Key('text-larger'),
            tooltip: AppStrings.textLarger,
            icon: const Icon(Icons.text_increase),
            onPressed: cubit.canIncrease ? cubit.larger : null,
          ),
        ]);
      },
    );
  }
}

class _ReaderList extends StatelessWidget {
  const _ReaderList({required this.items, required this.initialIndex});

  final List<ReaderItem> items;
  final int initialIndex;

  static const double bodySize = 18;
  static const double headingSize = 21;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextScaleCubit, double>(
      builder: (context, scale) {
        return ScrollablePositionedList.builder(
          key: const Key('reader-list'),
          itemCount: items.length,
          initialScrollIndex: initialIndex,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, i) => _buildItem(context, items[i], i, scale),
        );
      },
    );
  }

  Widget _buildItem(
    BuildContext context,
    ReaderItem item,
    int index,
    double scale,
  ) {
    final theme = Theme.of(context);
    switch (item) {
      case HeaderItem():
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.saintTitle, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                item.sectionTitle,
                key: const Key('reader-section-title'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(item.pageText, style: theme.textTheme.bodySmall),
            ],
          ),
        );
      case EditorialItem():
        return EditorialCard(
          key: Key('editorial-${item.addition.id}'),
          addition: item.addition,
        );
      case PageMarkerItem():
        return Padding(
          key: ValueKey('page-marker-$index'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(item.label, style: theme.textTheme.labelMedium),
            ),
            const Expanded(child: Divider()),
          ]),
        );
      case ParagraphItem():
        return _ParagraphView(paragraph: item.paragraph, scale: scale);
    }
  }
}

class _ParagraphView extends StatelessWidget {
  const _ParagraphView({required this.paragraph, required this.scale});

  final Paragraph paragraph;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = paragraph.kind == ParagraphKind.heading;
    final base = theme.textTheme.bodyLarge ?? const TextStyle();
    final style = base.copyWith(
      fontSize: (heading ? _ReaderList.headingSize : _ReaderList.bodySize) *
          scale,
      height: 1.9,
      fontWeight: heading ? FontWeight.bold : null,
    );
    return Padding(
      // Stable anchor: the paragraph id is part of the key.
      key: Key('para-${paragraph.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(paragraph.text, style: style),
    );
  }
}
