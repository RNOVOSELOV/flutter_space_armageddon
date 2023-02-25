import 'dart:async';
import 'dart:isolate';
import 'package:rxdart/rxdart.dart';
import 'package:spacehero/game_core/game_core_helpers/game_score_counter.dart';
import 'package:spacehero/game_core/models/game_info.dart';
import 'package:spacehero/isolates/main_loop.dart';
import 'package:spacehero/game_core/game_core_helpers/game_state.dart';

class GameBloc {
  ReceivePort? _receivePort;
  Isolate? _isolateLoop;

  final stateSubject = BehaviorSubject<GameSceneType>();
  final scoreValue = BehaviorSubject<int>.seeded(0);

  late final GameScoreCounter scoreCounter;

  Stream<GameInfo> observeGameInfo() =>
      Rx.combineLatest2<GameSceneType, int, GameInfo>(
          stateSubject.distinct(), scoreValue, (gsType, value) {
        GameState(type: gsType).getScene.update();
        return GameInfo(
            gsType: gsType,
            gameIsStarted: scoreCounter.gameIsEnded(),
            score: value);
      });

  GameBloc();

  void initBloc({required width, required height}) {
    GameState.screenHeight = height;
    GameState.screenWidth = width;
    stateSubject.add(GameSceneType.startGameScene);
    _startIsolateLoop();
    scoreCounter = GameScoreCounter();
  }

  void startGame() {
    stateSubject.add(GameSceneType.gameScene);
    scoreCounter.startGame();
  }

  void _startIsolateLoop() async {
    _receivePort = ReceivePort();
    _isolateLoop = await Isolate.spawn(mainLoop, _receivePort!.sendPort);
    _receivePort!.listen((message) {
      final score = scoreCounter.getCurrentScore(message);
      if (score == 20) {
        scoreCounter.endGame();
      }
      scoreValue.add(score);
    });
  }

  void dispose() {
    stopLoop();
    _receivePort?.close();
    _isolateLoop?.kill(priority: Isolate.immediate);
    stateSubject.close();
    scoreValue.close();
  }
}
