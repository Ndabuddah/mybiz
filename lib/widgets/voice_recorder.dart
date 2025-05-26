import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_colors.dart';
import '../utils/helper.dart';

class VoiceRecorder extends StatefulWidget {
  final Function(File audioFile)? onRecordingComplete;

  const VoiceRecorder({Key? key, this.onRecordingComplete}) : super(key: key);

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isRecorderInitialized = false;
  String? _recordingPath;
  Timer? _timer;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  @override
  void dispose() {
    _stopRecording();
    _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      Helpers.showSnackBar(context, 'Microphone permission is required to record voice.', isError: true);
      return;
    }

    await _recorder.openRecorder();
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      await _initRecorder();
    }

    try {
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(toFile: _recordingPath, codec: Codec.aacADTS);

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = 0;
      });

      _startTimer();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      Helpers.showSnackBar(context, 'Failed to start recording. Please try again.', isError: true);
    }
  }

  Future<void> _pauseRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.pauseRecorder();

      setState(() {
        _isPaused = true;
      });

      _timer?.cancel();
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    if (!_isRecording || !_isPaused) return;

    try {
      await _recorder.resumeRecorder();

      setState(() {
        _isPaused = false;
      });

      _startTimer();
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stopRecorder();

      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      _timer?.cancel();

      if (_recordingPath != null && widget.onRecordingComplete != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          widget.onRecordingComplete!(file);
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          // Recording wave visualization (simplified)
          Container(
            height: 60,
            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
            child:
                _isRecording
                    ? Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          7,
                          (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 4, height: _isRecording && !_isPaused ? 10.0 + (index * 5) + (10 * (index % 3)) : 5, decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(2))),
                        ),
                      ),
                    )
                    : Center(child: Text('Press and hold to start recording', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45))),
          ),

          const SizedBox(height: 16),

          // Timer
          Text(_formatDuration(_recordingDuration), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isRecording ? AppColors.primaryColor : (isDarkMode ? Colors.white54 : Colors.black45))),

          const SizedBox(height: 16),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording && _isPaused) ...[
                // Resume button
                _buildControlButton(icon: Icons.play_arrow, color: Colors.green, onPressed: _resumeRecording, isDarkMode: isDarkMode),
              ] else if (_isRecording && !_isPaused) ...[
                // Pause button
                _buildControlButton(icon: Icons.pause, color: Colors.orange, onPressed: _pauseRecording, isDarkMode: isDarkMode),
              ],

              const SizedBox(width: 16),

              // Record/Stop button
              GestureDetector(
                onLongPress: _isRecording ? null : _startRecording,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: _isRecording ? Colors.red : AppColors.primaryColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: (_isRecording ? Colors.red : AppColors.primaryColor).withOpacity(0.3), blurRadius: 10, spreadRadius: 2)]),
                  child: IconButton(onPressed: _isRecording ? _stopRecording : _startRecording, icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 28)),
                ),
              ),

              const SizedBox(width: 16),

              if (_isRecording) ...[
                // Cancel button
                _buildControlButton(
                  icon: Icons.close,
                  color: Colors.grey,
                  onPressed: () {
                    _stopRecording();
                    // Don't call onRecordingComplete
                    _recordingPath = null;
                  },
                  isDarkMode: isDarkMode,
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Hint text
          Text(_isRecording ? 'Tap the stop button when you\'re done' : 'Press and hold or tap the mic button to start', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black45), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required Color color, required VoidCallback onPressed, required bool isDarkMode}) {
    return Container(width: 48, height: 48, decoration: BoxDecoration(color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05), shape: BoxShape.circle), child: IconButton(onPressed: onPressed, icon: Icon(icon, color: color)));
  }
}
