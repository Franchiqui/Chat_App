import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? fileName;
  const VideoPlayerWidget({Key? key, required this.videoUrl, this.fileName})
      : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
    _listener = () => setState(() {});
    _controller.addListener(_listener);
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _showControls = true;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _enterFullscreen() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                _buildControls(fullscreen: true),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$m:$s';
  }

  Widget _buildControls({bool fullscreen = false}) {
    if (!_showControls) return const SizedBox.shrink();
    final isPlaying = _controller.value.isPlaying;
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: fullscreen ? 24 : 8, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black54, Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.fileName != null &&
                widget.fileName!.isNotEmpty &&
                fullscreen)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  widget.fileName!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: fullscreen ? 38 : 28,
                  ),
                  onPressed: _togglePlay,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: SliderComponentShape.noOverlay,
                      activeTrackColor: Colors.blue.shade400,
                      inactiveTrackColor: Colors.blue.shade100,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      min: 0,
                      max: duration.inMilliseconds
                          .toDouble()
                          .clamp(1, double.infinity),
                      value: position.inMilliseconds
                          .clamp(0, duration.inMilliseconds)
                          .toDouble(),
                      onChanged: (v) async {
                        final newPos = Duration(milliseconds: v.toInt());
                        await _controller.seekTo(newPos);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen,
                      color: Colors.white, size: 24),
                  onPressed: _enterFullscreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _isInitialized
                ? VideoPlayer(_controller)
                : const Center(child: CircularProgressIndicator()),
            _buildControls(),
          ],
        ),
      ),
    );
  }
}
