import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

/// Full-screen photo and video viewer with swipe navigation
class PhotoVideoViewer extends StatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;

  const PhotoVideoViewer({
    Key? key,
    required this.assets,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<PhotoVideoViewer> createState() => _PhotoVideoViewerState();
}

class _PhotoVideoViewerState extends State<PhotoVideoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;
  VideoPlayerController? _videoController;
  bool _isLoadingVideo = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Auto-hide UI after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showUI = false);
      }
    });

    // Load video if initial asset is a video
    if (widget.assets[_currentIndex].type == AssetType.video) {
      _loadVideo(widget.assets[_currentIndex]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo(AssetEntity asset) async {
    if (!mounted) return;
    setState(() => _isLoadingVideo = true);

    try {
      final file = await asset.file;
      if (file == null) {
        if (!mounted) return;
        setState(() => _isLoadingVideo = false);
        return;
      }

      _videoController?.dispose();
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      await _videoController!.play();

      if (!mounted) return;
      setState(() => _isLoadingVideo = false);
    } catch (e) {
      debugPrint('Error loading video: $e');
      if (!mounted) return;
      setState(() => _isLoadingVideo = false);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);

    final asset = widget.assets[index];

    // Dispose previous video controller
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
    }

    // Load new video if needed
    if (asset.type == AssetType.video) {
      _loadVideo(asset);
    }
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
  }

  String _formatDate(DateTime date) {
    return DateFormat('d. MMMM yyyy, HH:mm', 'de_DE').format(date);
  }

  String _buildInfoLine(AssetEntity asset) {
    final parts = <String>[];
    parts.add('${_currentIndex + 1} von ${widget.assets.length}');
    parts.add('${asset.width} × ${asset.height}');
    if (asset.type == AssetType.video) {
      parts.add(
        _formatVideoDuration(Duration(seconds: asset.duration)),
      );
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // Photo/Video Gallery
            GestureDetector(
              onTap: _toggleUI,
              child: PhotoViewGallery.builder(
                pageController: _pageController,
                itemCount: widget.assets.length,
                onPageChanged: _onPageChanged,
                builder: (context, index) {
                  final asset = widget.assets[index];

                  if (asset.type == AssetType.video) {
                    return PhotoViewGalleryPageOptions.customChild(
                      child: index == _currentIndex
                          ? _buildVideoPlayer(asset)
                          : _buildVideoPlaceholder(asset),
                      heroAttributes: PhotoViewHeroAttributes(
                        tag: 'asset_${asset.id}',
                      ),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                    );
                  }

                  return PhotoViewGalleryPageOptions(
                    imageProvider: AssetEntityImageProvider(
                      asset,
                      isOriginal: true,
                    ),
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: 'asset_${asset.id}',
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Fehler beim Laden',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                loadingBuilder: (context, event) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            ),

            if (_showUI) _buildTopOverlay(widget.assets[_currentIndex]),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay(AssetEntity asset) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              _buildRoundAction(
                icon: Icons.close,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 90),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 40),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDate(asset.createDateTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _buildInfoLine(asset),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 178),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildRoundAction(
                icon: Icons.more_vert,
                onPressed: _showBottomSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundAction({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 110),
            border: Border.all(
              color: Colors.white.withValues(alpha: 40),
              width: 0.8,
            ),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(AssetEntity asset) {
    return GestureDetector(
      onTap: _toggleUI,
      child: _isLoadingVideo
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _videoController != null && _videoController!.value.isInitialized
          ? SizedBox.expand(
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _videoController!,
                builder: (context, value, child) {
                  final duration = value.duration;
                  final maxMs = duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0;
                  final positionMs = value.position.inMilliseconds
                      .clamp(0, maxMs.toInt())
                      .toDouble();

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                      if (!value.isPlaying)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 128),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.play_arrow, size: 48),
                            color: Colors.white,
                            onPressed: () {
                              _videoController!.play();
                            },
                          ),
                        ),
                      if (_showUI)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildVideoControls(value, positionMs, maxMs),
                        ),
                    ],
                  );
                },
              ),
            )
          : const Center(
              child: Icon(Icons.error, color: Colors.white, size: 64),
            ),
    );
  }

  String _formatVideoDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showBottomSheet() {
    final asset = widget.assets[_currentIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text(
                  'Details',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Datum: ${_formatDate(asset.createDateTime)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 178),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Auflösung: ${asset.width} × ${asset.height}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 178),
                        fontSize: 12,
                      ),
                    ),
                    if (asset.type == AssetType.video)
                      Text(
                        'Dauer: ${_formatVideoDuration(Duration(seconds: asset.duration))}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 178),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoPlaceholder(AssetEntity asset) {
    return Center(
      child: AssetEntityImage(
        asset,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize.square(800),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideoControls(
    VideoPlayerValue value,
    double positionMs,
    double maxMs,
  ) {
    final duration = value.duration;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 130),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 35),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    },
                  ),
                  Text(
                    _formatVideoDuration(value.position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: positionMs,
                        min: 0,
                        max: maxMs,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                        onChanged: (valueMs) {
                          _videoController!.seekTo(
                            Duration(milliseconds: valueMs.round()),
                          );
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatVideoDuration(duration),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 200),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
