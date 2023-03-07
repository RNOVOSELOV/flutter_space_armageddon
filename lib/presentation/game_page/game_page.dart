import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spacehero/presentation/game_page/bloc/space_game_bloc.dart';
import 'package:spacehero/presentation/widgets/inventory_panel.dart';
import 'package:spacehero/presentation/widgets/stats_panel.dart';
import 'package:spacehero/presentation/widgets/widget_game_over.dart';
import 'package:spacehero/presentation/widgets/widget_start_screen.dart';
import 'package:spacehero/presentation/flame_space_game/space_game_instance.dart';

class GamePage extends StatelessWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => SpaceGameBloc(),
        child: const GameView(),
      ),
    );
  }
}

class GameView extends StatefulWidget {
  const GameView({Key? key}) : super(key: key);

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  GameStatus gameStatus = GameStatus.initial;
  int resultScore = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SpaceGameBloc, SpaceGameState>(
      listenWhen: (previous, current) => current is SpaceGameStatusChanged,
      listener: (context, state) {
        if (state is SpaceGameStatusChanged) {
          gameStatus = state.status;
          resultScore = state.score;
          setState(() {});
        }
      },
      child: Stack(
        children: [
          Positioned.fill(child: SpaceGameInstance.getInstance().getGameWidget),
          if (gameStatus == GameStatus.initial) const StartScreenWidget(),
          if (gameStatus == GameStatus.respawn ||
              gameStatus == GameStatus.respawned)
            const InventoryPanel(),
          if (gameStatus == GameStatus.respawn ||
              gameStatus == GameStatus.respawned)
            const StatisticsPanel(),
          if (gameStatus == GameStatus.gameOver)
            EndGameWidget(scoreValue: resultScore),
          if (gameStatus == GameStatus.statistics) SizedBox.shrink(),
        ],
      ),
    );
  }
}
