import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spacehero/presentation/space_game/bloc/space_game_bloc.dart';
import 'package:spacehero/presentation/space_game/dto/statistic_dto.dart';
import 'package:spacehero/resources/app_colors.dart';

class StatisticsPanel extends StatefulWidget {
  const StatisticsPanel({Key? key}) : super(key: key);

  @override
  State<StatisticsPanel> createState() => _StatisticsPanelState();
}

class _StatisticsPanelState extends State<StatisticsPanel> {
  StatisticDto statisticDto = const StatisticDto.initial();

  double opacity = 0;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0, right: 12, left: 12),
        child: Align(
          alignment: Alignment.topCenter,
          child: BlocListener<SpaceGameBloc, SpaceGameState>(
            listenWhen: (previous, current) =>
                current is InventChangedState ||
                current is SpaceGameInitialState ||
                current is SpaceGameStatusChanged,
            listener: (context, state) {
              if (state is StatisticChangedState) {
                statisticDto = state.statistic;
                setState(() {});
              } else if (state is SpaceGameStatusChanged) {
                switch (state.status) {
                  case GameStatus.initial:
                  case GameStatus.gameOver:
                  case GameStatus.statistics:
                    opacity = 0;
                    setState(() {});
                    break;
                  case GameStatus.respawn:
                  case GameStatus.respawned:
                    opacity = 1;
                    setState(() {});
                    break;
                }
              } else if (state is SpaceGameInitialState) {
                opacity = 0;
                setState(() {});
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Score: ${statisticDto.score}',
                  style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.colorScoreTextTransparentColor),
                ),
                Expanded(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < statisticDto.maxLivesCount; i++)
                      i < statisticDto.brokenLives
                          ? Icon(
                              const IconData(0xf833,
                                  fontFamily: CupertinoIcons.iconFont,
                                  fontPackage: CupertinoIcons.iconFontPackage),
                              color: AppColors.colorHeart,
                            )
                          : Icon(
                              const IconData(0xf443,
                                  fontFamily: CupertinoIcons.iconFont,
                                  fontPackage: CupertinoIcons.iconFontPackage),
                              color: AppColors.colorHeart,
                            )
                  ],
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}