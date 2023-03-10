import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spacehero/data/hive_service.dart';
import 'package:spacehero/data/models/result.dart';
import 'package:spacehero/presentation/game_page/dto/invent_dto.dart';
import 'package:spacehero/presentation/game_page/dto/statistic_dto.dart';
import 'package:spacehero/resources/app_constants_parameters.dart';

part 'space_game_event.dart';

part 'space_game_state.dart';

enum GameStatus {
  initial, // new game screen
  respawn, // player positioned & start game with 5 sec damage pause
  respawned, // damage is active
  gameOver, // game result screen
  statistics, // statistics screen
}

class SpaceGameBloc extends Bloc<SpaceGameEvent, SpaceGameState> {
  StatisticDto statistic = const StatisticDto.initial();
  InventDto invent = const InventDto.initial();
  GameStatus gameStatus = GameStatus.initial;

  final hiveService = HiveService();

  SpaceGameBloc()
      : super(const SpaceGameStatusChanged(status: GameStatus.initial)) {
    on<ScoreAddEvent>(_gameLoopAddScore);
    on<PlayerDiedEvent>(_gameLoopPlayerDied);
    on<PlayerFireEvent>(_gameLoopPlayerFire);
    on<GameLoadedEvent>(_gameLoopGameLoaded);
    on<OpenInitialScreenEvent>(_gameLoopOpenInitialScreen);
    on<OpenStatisticScreenEvent>(_gameLoopOpenStatisticsScreen);
    on<BonusArmorEvent>(_bonusArmor);
    on<PlayerArmorEvent>(_gameLoopPlayerArmor);
    on<BonusBombEvent>(_bonusBomb);
    on<PlayerBombFireEvent>(_gameLoopPlayerBomb);
    on<BonusHpEvent>(_bonusHp);
    on<PlayerMultiFireEvent>(_playerMultiRocket);
    on<BonusRocketEvent>(_bonusRocket);
    on<BonusSpeedEvent>(_bonusSpeed);
    on<PlayerSpeedEvent>(_playerSpeed);
  }

  FutureOr<void> _gameLoopGameLoaded(
    final GameLoadedEvent event,
    final Emitter<SpaceGameState> emit,
  ) async {
    await respawnPlayer(emit);
  }

  FutureOr<void> _gameLoopPlayerDied(
    final PlayerDiedEvent event,
    final Emitter<SpaceGameState> emit,
  ) async {
    statistic = statistic.copyWith(brokenLives: statistic.brokenLives + 1);
    if (statistic.brokenLives >= statistic.maxLivesCount) {
      emit(SpaceGameStatusChanged(
          status: GameStatus.gameOver, data: statistic.score));
      hiveService
          .addResult(Result(score: statistic.score, dateTime: DateTime.now()));
      emit(StatisticChangedState(statistic: statistic));
    } else {
      await Future.delayed(
          const Duration(seconds: 1), () => respawnPlayer(emit));
    }
  }

  FutureOr<void> respawnPlayer(Emitter emit) async {
    gameStatus = GameStatus.respawn;
    emit(const SpaceGameStatusChanged(status: GameStatus.respawn));
    emit(StatisticChangedState(statistic: statistic));
    invent = const InventDto.initial();
    emit(InventChangedState(invent: invent));
    await Future.delayed(
      const Duration(seconds: AppConstants.playerRespawnTime),
      () {
        if (gameStatus == GameStatus.respawn) {
          gameStatus = GameStatus.respawned;
          emit(const SpaceGameStatusChanged(status: GameStatus.respawned));
        }
      },
    );
  }

  FutureOr<void> _gameLoopPlayerFire(
    final PlayerFireEvent event,
    final Emitter<SpaceGameState> emit,
  ) {
    if (gameStatus == GameStatus.respawned ||
        gameStatus == GameStatus.respawn) {
      int rocketCount = invent.rocket - 1;
      if (rocketCount >= 0) {
        invent = invent.copyWith(rocket: rocketCount);
        emit(PlayerFireState(rocketCount));
        emit(InventChangedState(invent: invent));
      } else {
        rocketCount = 0;
      }
    }
  }

  FutureOr<void> _gameLoopAddScore(
    final ScoreAddEvent event,
    final Emitter<SpaceGameState> emit,
  ) {
    statistic = statistic.copyWith(score: statistic.score + event.scoreDelta);
    emit(StatisticChangedState(statistic: statistic));
  }

  FutureOr<void> _gameLoopOpenInitialScreen(
      final OpenInitialScreenEvent event, final Emitter<SpaceGameState> emit) {
    statistic = const StatisticDto.initial();
    invent = const InventDto.initial();
    gameStatus = GameStatus.initial;
    emit(const SpaceGameStatusChanged(status: GameStatus.initial));
  }

  FutureOr<void> _gameLoopOpenStatisticsScreen(
      final OpenStatisticScreenEvent event,
      final Emitter<SpaceGameState> emit) async {
    final results = hiveService.getPeoples();
    emit(SpaceGameStatusChanged(status: GameStatus.statistics, data: results));
  }

  FutureOr<void> _bonusArmor(
      final BonusArmorEvent event, final Emitter<SpaceGameState> emit) {
    invent = invent.copyWith(armor: invent.armor + 5);
    emit(InventChangedState(invent: invent));
  }

  FutureOr<void> _gameLoopPlayerArmor(
      final PlayerArmorEvent event, final Emitter<SpaceGameState> emit) async {
    emit(const PlayerArmorState(armorIsActive: true));
    final tickCount = invent.armor;
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      int armorCount = invent.armor - 1;
      if (armorCount < 0) {
        armorCount = 0;
      }
      invent = invent.copyWith(armor: armorCount);
      emit(InventChangedState(invent: invent));
    });

    await Future.delayed(
      Duration(seconds: tickCount + 1),
      () {
        timer.cancel();
        emit(const PlayerArmorState(armorIsActive: false));
      },
    );
  }

  FutureOr<void> _bonusHp(
      final BonusHpEvent event, final Emitter<SpaceGameState> emit) {
    statistic = statistic.copyWith(maxLivesCount: statistic.maxLivesCount + 1);
    emit(StatisticChangedState(statistic: statistic));
  }

  FutureOr<void> _playerMultiRocket(
      final PlayerMultiFireEvent event, final Emitter<SpaceGameState> emit) {
    if (gameStatus == GameStatus.respawned ||
        gameStatus == GameStatus.respawn) {
      int rocketCount = invent.rocket - 3;
      if (rocketCount >= 0) {
        invent = invent.copyWith(rocket: rocketCount);
        emit(PlayerMultiFireState(rocketCount));
        emit(InventChangedState(invent: invent));
      } else {
        rocketCount = 0;
      }
    }
  }

  FutureOr<void> _bonusRocket(
      final BonusRocketEvent event, final Emitter<SpaceGameState> emit) {
    invent = invent.copyWith(
      rocket: invent.rocket + 50,
    );
    emit(InventChangedState(invent: invent));
  }

  FutureOr<void> _gameLoopPlayerBomb(
      final PlayerBombFireEvent event, final Emitter<SpaceGameState> emit) {
    if (gameStatus == GameStatus.respawned ||
        gameStatus == GameStatus.respawn) {
      int bombCount = invent.bomb - 1;
      if (bombCount >= 0) {
        invent = invent.copyWith(bomb: bombCount);
        emit(PlayerBombState(bombCount));
        emit(InventChangedState(invent: invent));
      } else {
        bombCount = 0;
      }
    }
  }

  FutureOr<void> _bonusBomb(
      final BonusBombEvent event, final Emitter<SpaceGameState> emit) {
    invent = invent.copyWith(
      bomb: invent.bomb + 1,
    );
    emit(InventChangedState(invent: invent));
  }

  FutureOr<void> _bonusSpeed(
      final BonusSpeedEvent event, final Emitter<SpaceGameState> emit) {
    invent = invent.copyWith(speed: invent.speed + 5);
    emit(InventChangedState(invent: invent));
  }

  FutureOr<void> _playerSpeed(
      final PlayerSpeedEvent event, final Emitter<SpaceGameState> emit) async {
    emit(const PlayerSpeedState(speedIsActive: true));
    final tickCount = invent.speed;
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      int speedCount = invent.speed - 1;
      if (speedCount < 0) {
        speedCount = 0;
      }
      invent = invent.copyWith(speed: speedCount);
      emit(InventChangedState(invent: invent));
    });

    await Future.delayed(
      Duration(seconds: tickCount + 1),
      () {
        timer.cancel();
        emit(const PlayerSpeedState(speedIsActive: false));
      },
    );
  }

  @override
  Future<void> close() async {
    await hiveService.closeDb();
    return super.close();
  }
}
