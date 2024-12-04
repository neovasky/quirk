import 'package:flutter/material.dart';
import '../../core/models/timer_settings.dart';

class TimerSettingsDialog extends StatefulWidget {
  final TimerSettings currentSettings;
  final Function(TimerSettings) onSettingsChanged;

  const TimerSettingsDialog({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<TimerSettingsDialog> createState() => _TimerSettingsDialogState();
}

class _TimerSettingsDialogState extends State<TimerSettingsDialog> {
  late final TextEditingController workMinController;
  late final TextEditingController workSecController;
  late final TextEditingController shortBreakMinController;
  late final TextEditingController shortBreakSecController;
  late final TextEditingController longBreakMinController;
  late final TextEditingController longBreakSecController;
  late final TextEditingController cyclesController;
  late bool autoStartBreaks;

  @override
  void initState() {
    super.initState();
    workMinController = TextEditingController(text: widget.currentSettings.workDurationMin.toString());
    workSecController = TextEditingController(text: widget.currentSettings.workDurationSec.toString());
    shortBreakMinController = TextEditingController(text: widget.currentSettings.shortBreakMin.toString());
    shortBreakSecController = TextEditingController(text: widget.currentSettings.shortBreakSec.toString());
    longBreakMinController = TextEditingController(text: widget.currentSettings.longBreakMin.toString());
    longBreakSecController = TextEditingController(text: widget.currentSettings.longBreakSec.toString());
    cyclesController = TextEditingController(text: widget.currentSettings.cycles.toString());
    autoStartBreaks = widget.currentSettings.autoStartBreaks;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timer Settings',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  _buildPresetButton('Regular'),
                  const SizedBox(width: 8),
                  _buildPresetButton('Quick'),
                  const SizedBox(width: 8),
                  _buildPresetButton('Extended'),
                  const SizedBox(width: 8),
                  _buildPresetButton('Endurance'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            _buildTimeRow('Work Duration:', workMinController, workSecController),
            const SizedBox(height: 32),
            _buildTimeRow('Short Break:', shortBreakMinController, shortBreakSecController),
            const SizedBox(height: 32),
            _buildTimeRow('Long Break:', longBreakMinController, longBreakSecController),
            const SizedBox(height: 32),
            
            _buildCyclesRow(),
            const SizedBox(height: 32),
            
            _buildAutoStartRow(),
            const SizedBox(height: 32),
            
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label) {
    void applyPreset() {
      switch(label) {
        case 'Regular':
          _updateTimers(25, 0, 5, 0, 15, 0, 4);
          break;
        case 'Quick':
          _updateTimers(15, 0, 3, 0, 10, 0, 4);
          break;
        case 'Extended':
          _updateTimers(45, 0, 10, 0, 20, 0, 4);
          break;
        case 'Endurance':
          _updateTimers(50, 0, 10, 0, 30, 0, 4);
          break;
      }
    }

    return Expanded(
      child: OutlinedButton(
        onPressed: applyPreset,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTimeRow(String label, TextEditingController minController, TextEditingController secController) {
    const textStyle = TextStyle(color: Colors.white, fontSize: 16);
    const labelStyle = TextStyle(color: Colors.white54);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Row(
          children: [
            SizedBox(
              width: 40,
              child: TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: textStyle,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 4),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('m', style: labelStyle),
            ),
            SizedBox(
              width: 40,
              child: TextField(
                controller: secController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: textStyle,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 4),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('s', style: labelStyle),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCyclesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Cycles:', style: TextStyle(color: Colors.white, fontSize: 16)),
        SizedBox(
          width: 40,
          child: TextField(
            controller: cyclesController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.only(bottom: 4),
              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoStartRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Auto-start breaks', style: TextStyle(color: Colors.white, fontSize: 16)),
        Switch(
          value: autoStartBreaks,
          onChanged: (value) => setState(() => autoStartBreaks = value),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', 
            style: TextStyle(color: Colors.white54)),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: _saveSettings,
          child: const Text('Save', 
            style: TextStyle(color: Color(0xFFBB86FC))),
        ),
      ],
    );
  }

  void _updateTimers(
    int workMin, int workSec,
    int shortBreakMin, int shortBreakSec,
    int longBreakMin, int longBreakSec,
    int cycles
  ) {
    setState(() {
      workMinController.text = workMin.toString();
      workSecController.text = workSec.toString();
      shortBreakMinController.text = shortBreakMin.toString();
      shortBreakSecController.text = shortBreakSec.toString();
      longBreakMinController.text = longBreakMin.toString();
      longBreakSecController.text = longBreakSec.toString();
      cyclesController.text = cycles.toString();
    });
  }

  void _saveSettings() {
    try {
      final settings = TimerSettings(
        workDurationMin: int.parse(workMinController.text),
        workDurationSec: int.parse(workSecController.text),
        shortBreakMin: int.parse(shortBreakMinController.text),
        shortBreakSec: int.parse(shortBreakSecController.text),
        longBreakMin: int.parse(longBreakMinController.text),
        longBreakSec: int.parse(longBreakSecController.text),
        cycles: int.parse(cyclesController.text),
        autoStartBreaks: autoStartBreaks,
      );
      
      widget.onSettingsChanged(settings);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
    }
  }

  @override
  void dispose() {
    workMinController.dispose();
    workSecController.dispose();
    shortBreakMinController.dispose();
    shortBreakSecController.dispose();
    longBreakMinController.dispose();
    longBreakSecController.dispose();
    cyclesController.dispose();
    super.dispose();
  }
}