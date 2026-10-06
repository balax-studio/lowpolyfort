import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../../systems/save_system.dart';
import '../../localization/app_localization.dart';
import '../common/brutalist_card.dart';
import '../common/brutalist_button.dart';
import '../common/brutalist_badge.dart';

/// User settings dialog for audio, haptics, damage numbers, language, and progress resets (Clause 138, 664).
class SettingsDialog extends StatefulWidget {
  final VoidCallback onClose;

  const SettingsDialog({super.key, required this.onClose});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late double _masterVol;
  late double _sfxVol;
  late bool _vibration;
  late bool _showDamage;
  late String _language;

  @override
  void initState() {
    super.initState();
    final save = SaveSystem.currentSave;
    _masterVol = save.masterVolume;
    _sfxVol = save.sfxVolume;
    _vibration = save.vibrationEnabled;
    _showDamage = save.showDamageNumbers;
    _language = save.language;
  }

  void _saveSettings() {
    final updated = SaveSystem.currentSave.copyWith(
      masterVolume: _masterVol,
      sfxVolume: _sfxVol,
      vibrationEnabled: _vibration,
      showDamageNumbers: _showDamage,
      language: _language,
    );
    SaveSystem.save(updated);
    widget.onClose();
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: BrutalistCard(
            backgroundColor: GameColors.background,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrutalistBadge(
                  text: 'WIPE SAVE DATA?',
                  backgroundColor: GameColors.punchRed,
                  textColor: Colors.white,
                  fontSize: 14,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This will permanently reset all Scrap, high scores, and permanent upgrades.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GameColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: BrutalistButton(
                        label: 'CANCEL',
                        backgroundColor: GameColors.surfaceSubtle,
                        fontSize: 13,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BrutalistButton(
                        label: 'WIPE DATA',
                        backgroundColor: GameColors.punchRed,
                        textColor: Colors.white,
                        fontSize: 13,
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await SaveSystem.resetAll();
                          if (mounted) {
                            setState(() {
                              _masterVol = 1.0;
                              _sfxVol = 1.0;
                              _vibration = true;
                              _showDamage = true;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
        child: BrutalistCard(
          backgroundColor: GameColors.background,
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: BrutalistBadge(
                  text: AppLocalization.text('settings'),
                  backgroundColor: GameColors.acidYellow,
                  icon: Icons.settings,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 18),

              // Language Selector Row (Clause 664)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalization.text('language'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  Row(
                    children: [
                      BrutalistButton(
                        label: 'ENGLISH',
                        backgroundColor: _language == 'en' ? GameColors.acidYellow : GameColors.surfaceSubtle,
                        fontSize: 11,
                        horizontalPadding: 10,
                        verticalPadding: 6,
                        onPressed: () => setState(() => _language = 'en'),
                      ),
                      const SizedBox(width: 6),
                      BrutalistButton(
                        label: 'TÜRKÇE',
                        backgroundColor: _language == 'tr' ? GameColors.acidYellow : GameColors.surfaceSubtle,
                        fontSize: 11,
                        horizontalPadding: 10,
                        verticalPadding: 6,
                        onPressed: () => setState(() => _language = 'tr'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Master Volume
              _buildSliderRow(AppLocalization.text('master_vol'), _masterVol, (v) => setState(() => _masterVol = v)),
              const SizedBox(height: 10),

              // SFX Volume
              _buildSliderRow(AppLocalization.text('sfx_vol'), _sfxVol, (v) => setState(() => _sfxVol = v)),
              const SizedBox(height: 10),

              // Vibration Toggle
              _buildSwitchRow(AppLocalization.text('vibration'), _vibration, (v) => setState(() => _vibration = v)),
              const SizedBox(height: 10),

              // Damage Numbers Toggle
              _buildSwitchRow(AppLocalization.text('damage_numbers'), _showDamage, (v) => setState(() => _showDamage = v)),
              const SizedBox(height: 18),

              // Reset Data Button
              BrutalistButton(
                label: AppLocalization.text('wipe_data'),
                icon: Icons.delete_forever,
                backgroundColor: GameColors.surfaceSubtle,
                textColor: GameColors.punchRed,
                fontSize: 13,
                onPressed: () => _confirmReset(context),
              ),
              const SizedBox(height: 16),

              // Save & Close
              BrutalistButton(
                label: AppLocalization.text('apply_close'),
                icon: Icons.check,
                backgroundColor: GameColors.electricLime,
                fontSize: 15,
                onPressed: _saveSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            Text('${(value * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: GameColors.ink,
            inactiveTrackColor: const Color(0xFFC7C3B7),
            thumbColor: GameColors.acidYellow,
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        Switch(
          value: value,
          activeThumbColor: GameColors.electricLime,
          activeTrackColor: GameColors.electricLime.withValues(alpha: 0.5),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: GameColors.surfaceSubtle,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
