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
    setState(() => _isLoadingVideo = true);
    
    try {
      final file = await asset.file;
      if (file == null) {
        setState(() => _isLoadingVideo = false);
        return;
      }

      _videoController?.dispose();
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      await _videoController!.play();
      
      setState(() => _isLoadingVideo = false);
    } catch (e) {
      debugPrint('Error loading video: $e');
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
                    child: _buildVideoPlayer(asset),
                    heroAttributes: PhotoViewHeroAttributes(tag: 'asset_${asset.id}'),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                }

                return PhotoViewGalleryPageOptions(
                  imageProvider: AssetEntityImageProvider(
                    asset,
                    isOriginal: true,
                  ),
                  heroAttributes: PhotoViewHeroAttributes(tag: 'asset_${asset.id}'),
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
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              loadingBuilder: (context, event) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              },
              ),
            ),

            // Top bar with close button and info
            if (_showUI)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {
                              // TODO: Implement share
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onPressed: () => _showBottomSheet(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom info bar
            if (_showUI)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDate(widget.assets[_currentIndex].createDateTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_currentIndex + 1} von ${widget.assets.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(AssetEntity asset) {
    return GestureDetector(
      onTap: _toggleUI,
      child: Center(
        child: _isLoadingVideo
            ? const CircularProgressIndicator(color: Colors.white)
            : _videoController != null && _videoController!.value.isInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                      if (!_videoController!.value.isPlaying)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.play_arrow, size: 48),
                            color: Colors.white,
                            onPressed: () {
                              _videoController!.play();
                              setState(() {});
                            },
                          ),
                        ),
                      if (_videoController!.value.isPlaying && _showUI)
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _videoController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (_videoController!.value.isPlaying) {
                                    _videoController!.pause();
                                  } else {
                                    _videoController!.play();
                                  }
                                  setState(() {});
                                },
                              ),
                              Expanded(
                                child: VideoProgressIndicator(
                                  _videoController!,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.white,
                                    bufferedColor: Colors.white30,
                                    backgroundColor: Colors.white10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatVideoDuration(_videoController!.value.position),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                : const Icon(Icons.error, color: Colors.white, size: 64),
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
                title: const Text('Details', style: TextStyle(color: Colors.white)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Datum: ${_formatDate(asset.createDateTime)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                    Text(
                      'Auflösung: ${asset.width} × ${asset.height}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                    if (asset.type == AssetType.video)
                      Text(
                        'Dauer: ${_formatVideoDuration(Duration(seconds: asset.duration))}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Löschen', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement delete
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
