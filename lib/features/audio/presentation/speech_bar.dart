import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../../../app/theme/app_icons.dart';
import '../domain/speech_cubit.dart';
import '../domain/speech_plan.dart';
import '../domain/tts_engine.dart';

/// Play / pause / stop / speed for the section being read, plus a clear
/// message when no usable Arabic voice exists.
class SpeechBar extends StatelessWidget {
  const SpeechBar({super.key, required this.plan, required this.planKey});

  /// What this section speaks, and its identity. If another section's plan
  /// is loaded (e.g. after returning to this screen), it is reloaded first.
  final List<SpeechSegment> plan;
  final String planKey;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpeechCubit>();
    return BlocBuilder<SpeechCubit, SpeechState>(
      builder: (context, state) {
        final message = switch (state.status) {
          SpeechStatus.unavailable =>
            state.support == ArabicSupport.onlineOnly
                ? AppStrings.ttsOnlineOnly
                : AppStrings.ttsMissingVoice,
          SpeechStatus.error => AppStrings.ttsError,
          _ => null,
        };
        return Material(
          key: const Key('speech-bar'),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      child: Text(
                        message,
                        key: const Key('tts-message'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Row(children: [
                    IconButton(
                      key: const Key('tts-play-pause'),
                      tooltip: state.isPlaying
                          ? AppStrings.ttsPause
                          : AppStrings.ttsPlay,
                      icon: Icon(
                          state.isPlaying ? AppIcons.pause : AppIcons.play),
                      onPressed: state.isPlaying ? cubit.pause : _play(cubit),
                    ),
                    IconButton(
                      key: const Key('tts-stop'),
                      tooltip: AppStrings.ttsStop,
                      icon: const Icon(AppIcons.stop),
                      onPressed: state.status == SpeechStatus.idle ||
                              state.status == SpeechStatus.unavailable
                          ? null
                          : cubit.stop,
                    ),
                    TextButton(
                      key: const Key('tts-speed'),
                      onPressed: cubit.cycleRate,
                      child: Text(
                        '${_fmt(state.rate)}×',
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    const Spacer(),
                    if (state.support == ArabicSupport.offline)
                      Text(
                        AppStrings.ttsOfflineVoice,
                        key: const Key('tts-offline-badge'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  VoidCallback _play(SpeechCubit cubit) => () async {
        if (!cubit.owns(planKey)) await cubit.load(plan, key: planKey);
        await cubit.play();
      };

  static String _fmt(double r) =>
      r == r.roundToDouble() ? r.toStringAsFixed(0) : '$r';
}
