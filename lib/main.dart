import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/game_colors.dart';
import 'constants/game_config.dart';
import 'game/base_defense_game.dart';
import 'managers/game_manager.dart';
import 'systems/save_system.dart';
import 'models/game_mode_data.dart';
import 'ui/splash/splash_screen.dart';
import 'ui/main_menu/main_menu_view.dart';
import 'ui/main_menu/mode_select_dialog.dart';
import 'ui/game_hud/game_hud_view.dart';
import 'ui/upgrade_menu/upgrade_selection_dialog.dart';
import 'ui/second_chance/second_chance_dialog.dart';
import 'ui/game_over/game_over_dialog.dart';
import 'ui/pause/pause_dialog.dart';
import 'ui/settings/settings_dialog.dart';
import 'ui/upgrades/permanent_upgrades_view.dart';
import 'ui/armory/armory_view.dart';
import 'ui/tutorial/tutorial_overlay.dart';
import 'ui/debug/debug_panel.dart';
import 'services/rewarded_ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait as requested (Clause 1)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Load persistent save state (Clause 142)
  await SaveSystem.init();

  // Initialize Rewarded Ad Service (Clauses 436, 437)
  await RewardedAdService.instance.init();

  runApp(const PolyFortApp());
}

class PolyFortApp extends StatelessWidget {
  const PolyFortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poly Fort',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: GameColors.background,
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: GameColors.ink,
          displayColor: GameColors.ink,
        ),
      ),
      home: const GameContainerScreen(),
    );
  }
}

class GameContainerScreen extends StatefulWidget {
  const GameContainerScreen({super.key});

  @override
  State<GameContainerScreen> createState() => _GameContainerScreenState();
}

class _GameContainerScreenState extends State<GameContainerScreen> with WidgetsBindingObserver {
  late final BaseDefenseGame _game;
  final GameManager _gameManager = GameManager.instance;

  bool _isSplashDone = false;
  bool _isUpgradesOpen = false;
  bool _isArmoryOpen = false;
  bool _isSettingsOpen = false;
  bool _isModeSelectOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = BaseDefenseGame(gameManager: _gameManager);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-pause when app transitions to background (Clause 141)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Ignore lifecycle transitions caused by full-screen rewarded ads (Clause 500)
    if (RewardedAdService.instance.isShowingAd || _gameManager.isRewardedAdShowing) {
      return;
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_gameManager.state == GameState.playing || _gameManager.state == GameState.preparingWave) {
        _gameManager.pauseGame();
      }
    }
  }

  void _onStartGame() {
    // Clauses 282, 291: Fresh players launch Normal directly; Mode Select opens once Chaos is unlocked
    if (SaveSystem.currentSave.chaosUnlocked) {
      setState(() {
        _isModeSelectOpen = true;
        _isUpgradesOpen = false;
        _isArmoryOpen = false;
        _isSettingsOpen = false;
      });
    } else {
      _startMode(GameMode.normal);
    }
  }

  void _startMode(GameMode mode) {
    setState(() {
      _isUpgradesOpen = false;
      _isArmoryOpen = false;
      _isSettingsOpen = false;
      _isModeSelectOpen = false;
    });
    _game.resetGameForNewRun(mode: mode);
  }

  void _openUpgrades() {
    setState(() {
      _isUpgradesOpen = true;
      _isArmoryOpen = false;
      _isSettingsOpen = false;
    });
  }

  void _closeUpgrades() {
    setState(() {
      _isUpgradesOpen = false;
    });
  }

  void _openArmory() {
    setState(() {
      _isArmoryOpen = true;
      _isUpgradesOpen = false;
      _isSettingsOpen = false;
    });
  }

  void _closeArmory() {
    setState(() {
      _isArmoryOpen = false;
    });
  }

  void _openSettings() {
    setState(() {
      _isSettingsOpen = true;
    });
  }

  void _closeSettings() {
    setState(() {
      _isSettingsOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.ink,
      body: Center(
        child: AspectRatio(
          // Responsive 9:16 container with letterbox fit for tablets
          aspectRatio: GameConfig.virtualWidth / GameConfig.virtualHeight,
          child: !_isSplashDone
              ? SplashScreen(
                  onLoaded: () {
                    setState(() {
                      _isSplashDone = true;
                    });
                  },
                )
              : ListenableBuilder(
                  listenable: _gameManager,
                  builder: (context, _) {
                    final anyModalOpen = _isUpgradesOpen || _isArmoryOpen || _isSettingsOpen || _isModeSelectOpen;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. The Flame 2.5D Canvas World
                        GameWidget(game: _game),

                        // 2. Main Menu Overlay (Clauses 53, 54)
                        if (_gameManager.state == GameState.menu && !anyModalOpen)
                          MainMenuView(
                            onStartGame: _onStartGame,
                            onOpenUpgrades: _openUpgrades,
                            onOpenArmory: _openArmory,
                            onOpenSettings: _openSettings,
                          ),

                        // 3. In-Game Battle HUD
                        if ((_gameManager.state == GameState.playing ||
                                _gameManager.state == GameState.preparingWave ||
                                _gameManager.state == GameState.tutorial ||
                                _gameManager.state == GameState.upgradeSelection ||
                                _gameManager.state == GameState.paused) &&
                            !anyModalOpen)
                          GameHudView(game: _game),

                        // 4. Interactive Tutorial Overlay (Clauses 55, 143)
                        if (_gameManager.state == GameState.tutorial && !anyModalOpen)
                          TutorialOverlay(gameManager: _gameManager),

                        // 5. Roguelite 3-Card Upgrade Modal (Clauses 86, 87)
                        if (_gameManager.state == GameState.upgradeSelection && !anyModalOpen)
                          Container(
                            color: Colors.black.withValues(alpha: 0.75),
                            child: UpgradeSelectionDialog(gameManager: _gameManager),
                          ),

                        // 6. In-Game Pause Dialog (Clause 140)
                        if (_gameManager.state == GameState.paused && !anyModalOpen)
                          Container(
                            color: Colors.black.withValues(alpha: 0.85),
                            child: PauseDialog(
                              game: _game,
                              onOpenSettings: _openSettings,
                            ),
                          ),

                        // 6.5. Second Chance Revive Modal (Clauses 462–480)
                        if (_gameManager.state == GameState.awaitingSecondChance && !anyModalOpen)
                          Container(
                            color: Colors.black.withValues(alpha: 0.82),
                            child: SecondChanceDialog(
                              gameManager: _gameManager,
                            ),
                          ),

                        // 7. Game Over Modal (Clauses 101, 102)
                        if (_gameManager.state == GameState.gameOver && !anyModalOpen)
                          Container(
                            color: Colors.black.withValues(alpha: 0.82),
                            child: GameOverDialog(
                              game: _game,
                              onOpenArmory: _openUpgrades,
                            ),
                          ),

                        // 8. Mode Select Modal (Clauses 291–296)
                        if (_isModeSelectOpen)
                          Container(
                            color: Colors.black.withValues(alpha: 0.82),
                            child: ModeSelectDialog(
                              onSelectMode: _startMode,
                              onClose: () => setState(() => _isModeSelectOpen = false),
                            ),
                          ),

                        // 9. Permanent Upgrades Shop Modal (Clauses 105–112)
                        if (_isUpgradesOpen)
                          PermanentUpgradesView(onClose: _closeUpgrades),

                        // 10. Armory Showcase Modal (Clauses 117, 118)
                        if (_isArmoryOpen)
                          ArmoryView(onClose: _closeArmory),

                        // 11. Settings Modal (Clause 138)
                        if (_isSettingsOpen)
                          SettingsDialog(onClose: _closeSettings),

                        // 12. QA Diagnostic Debug Panel (Clauses 148, 978: hidden in release builds)
                        if (kDebugMode)
                          DebugPanel(game: _game),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
