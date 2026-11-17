import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/strings.dart';
import '../../library/data/library_repository.dart';
import 'progress_cubit.dart';

/// "Continue reading": opens the last reading position. The location is
/// resolved from the paragraph ID, so it still works after content re-ordering.
/// Shows nothing when there is no progress or the paragraph no longer exists.
class ResumeCard extends StatelessWidget {
  const ResumeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryRepository>();
    return BlocBuilder<ProgressCubit, ProgressState>(
      builder: (context, state) {
        final last = state.last;
        if (last == null) return const SizedBox.shrink();
        return FutureBuilder<ParagraphLocation?>(
          key: ValueKey('resume-${last.paragraphId}'),
          future: library.locate(last.paragraphId, saintHint: last.saintId),
          builder: (context, snap) {
            final loc = snap.data;
            if (loc == null) return const SizedBox.shrink();
            return Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                key: const Key('resume-card'),
                leading: const Icon(Icons.play_circle_outline),
                title: const Text(AppStrings.continueReading),
                subtitle: Text('${loc.saint.title} › ${loc.section.title}'),
                onTap: () => context.push(AppRoutes.section(
                  loc.saint.id,
                  loc.section.id,
                  paragraphId: loc.paragraph.id,
                )),
              ),
            );
          },
        );
      },
    );
  }
}
