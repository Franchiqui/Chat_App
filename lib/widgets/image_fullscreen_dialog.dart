import 'package:flutter/material.dart';

class ImageFullscreenDialog extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;
  const ImageFullscreenDialog({Key? key, required this.imageUrl, this.heroTag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: heroTag ?? imageUrl,
                  child: InteractiveViewer(
                    child: Image.network(imageUrl),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
