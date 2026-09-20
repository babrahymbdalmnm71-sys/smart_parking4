import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _errorWidget();
    }

    // For Web, Image.network is often more reliable due to CORS and renderer differences
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _errorWidget(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _placeholderWidget();
        },
      );
    }

    return CachedNetworkImage(
      key: ValueKey(imageUrl),
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _placeholderWidget(),
      errorWidget: (context, url, error) => _errorWidget(),
    );
  }

  Widget _placeholderWidget() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(Icons.local_parking_rounded, color: AppColors.primary, size: iconSize),
    );
  }
}
