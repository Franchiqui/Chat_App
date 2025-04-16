import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String? fileName;
  const AudioPlayerWidget({Key? key, required this.audioUrl, this.fileName})
      : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  String _truncateFileNameWith(String fileName, {int maxLength = 28}) {
    if (fileName.length <= maxLength) return fileName;
    final ext = fileName.contains('.') ? '.${fileName.split('.').last}' : '';
    final name = fileName.replaceAll(ext, '');
    final allowed = maxLength - ext.length - 3;
    return name.substring(0, allowed.clamp(0, name.length)) + '...' + ext;
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _player.setUrl(widget.audioUrl);
      _duration = _player.duration ?? Duration.zero;
      setState(() {});
      _positionSub = _player.positionStream.listen((pos) {
        setState(() {
          _position = pos;
          _duration = _player.duration ?? Duration.zero;
        });
      });
      _playerStateSub = _player.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
        });
      });
    } catch (e) {
      // Si la url no es válida, ignora
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.blue.shade100, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.fileName != null && widget.fileName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
              child: Text(
                _truncateFileNameWith(widget.fileName!, maxLength: 28),
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.blueGrey.shade700,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: _togglePlayback,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        _isPlaying ? Colors.blue.shade100 : Colors.blue.shade50,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.09),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: Colors.blue.shade400,
                    inactiveTrackColor: Colors.blue.shade100,
                    thumbColor: Colors.blue.shade700,
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds
                        .toDouble()
                        .clamp(1, double.infinity),
                    value: _position.inMilliseconds
                        .clamp(0, _duration.inMilliseconds)
                        .toDouble(),
                    onChanged: (v) async {
                      final newPos = Duration(milliseconds: v.toInt());
                      await _player.seek(newPos);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey.shade700,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade400,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  _WaveformPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final midY = size.height / 2;
    final amplitude = size.height / 3;
    final waveCount = 12;
    for (int i = 0; i < waveCount; i++) {
      final x = i * size.width / (waveCount - 1);
      final y = midY + amplitude * (i % 2 == 0 ? 1 : -1) * (progress);
      canvas.drawCircle(Offset(x, y), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
