import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Frutia/model/Story.dart';
import 'package:Frutia/services/StoriesService.dart';

class StoriesSection extends StatefulWidget {
  const StoriesSection({Key? key}) : super(key: key);

  @override
  State<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends State<StoriesSection> {
  late Future<List<Story>> futureStories;
  Set<int> viewedStories = {};

  @override
  void initState() {
    super.initState();
    futureStories = StoriesService().getStories();
    _loadViewedStories();
  }

  Future<void> _loadViewedStories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      viewedStories = Set<int>.from(
          (prefs.getStringList('viewed_stories') ?? [])
              .map((s) => int.tryParse(s))
              .where((id) => id != null)
              .cast<int>());
    });
  }

  Future<void> _markStoryAsViewed(int storyId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      viewedStories.add(storyId);
    });
    await prefs.setStringList(
        'viewed_stories', viewedStories.map((id) => id.toString()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Story>>(
      future: futureStories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final stories = snapshot.data ?? [];

        return Container(
          height: 110,
          margin: EdgeInsets.only(top: 16, bottom: 16),
          // Envolvemos el ListView con un SizedBox.expand para darle un ancho definido
          child: SizedBox.expand(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                final isViewed = viewedStories.contains(story.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoryViewScreen(
                            story: story,
                            allStories: stories,
                            initialIndex: index,
                            onStoryViewed: (storyId) async {
                              await _markStoryAsViewed(storyId);
                            },
                          ),
                        ),
                      );
                      await _markStoryAsViewed(story.id);
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isViewed ? Colors.grey : Colors.blue,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 60,
                            height: 60,
                            padding: EdgeInsets.all(2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.network(
                                story.imageUrl,
                                fit: BoxFit.cover,
                                opacity: isViewed
                                    ? AlwaysStoppedAnimation(0.7)
                                    : AlwaysStoppedAnimation(1.0),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          story.title,
                          style: TextStyle(
                            color: isViewed ? Colors.grey : Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class StoryViewScreen extends StatefulWidget {
  final Story story;
  final List<Story> allStories;
  final int initialIndex;
  final Function(int) onStoryViewed; // Añadimos callback para marcar como vista

  const StoryViewScreen({
    Key? key,
    required this.story,
    required this.allStories,
    required this.initialIndex,
    required this.onStoryViewed,
  }) : super(key: key);

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;
  final Duration _storyDuration = Duration(seconds: 5);
  Set<int> _viewedInSession =
      {}; // Para rastrear las historias vistas en esta sesión

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animationController =
        AnimationController(vsync: this, duration: _storyDuration);

    // Marcar la historia inicial como vista
    _markCurrentStoryAsViewed();

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _animationController.forward();
  }

  void _markCurrentStoryAsViewed() {
    final currentStory = widget.allStories[_currentIndex];
    if (!_viewedInSession.contains(currentStory.id)) {
      _viewedInSession.add(currentStory.id);
      widget.onStoryViewed(currentStory.id);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStory() {
    if (_currentIndex < widget.allStories.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Indicador de progreso
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: widget.allStories
                    .asMap()
                    .map((index, story) {
                      return MapEntry(
                        index,
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: LinearProgressIndicator(
                              value: index == _currentIndex
                                  ? _animationController.value
                                  : index < _currentIndex
                                      ? 1.0
                                      : 0.0,
                              backgroundColor: Colors.grey[700],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      );
                    })
                    .values
                    .toList(),
              ),
            ),

            // PageView para las historias
            GestureDetector(
              onTapDown: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 2) {
                  _previousStory();
                } else {
                  _nextStory();
                }
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.allStories.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _animationController.reset();
                    _animationController.forward();
                    _markCurrentStoryAsViewed(); // Marcar como vista al cambiar de página
                  });
                },
                itemBuilder: (context, index) {
                  final story = widget.allStories[index];
                  return Center(
                    child: Image.network(
                      story.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.white, size: 50),
                              SizedBox(height: 16),
                              Text(
                                'Error al cargar la imagen',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Barra superior con información del usuario
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      child: Text(widget.allStories[_currentIndex]
                              .administrator?['name']?[0] ??
                          'A'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.allStories[_currentIndex]
                                    .administrator?['name'] ??
                                'FutPlay',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.allStories[_currentIndex].title,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryItem extends StatelessWidget {
  final Story story;
  final List<Story> allStories;
  final int index;
  final Function(int) onStoryViewed; // Añadir este parámetro

  const StoryItem({
    Key? key,
    required this.story,
    required this.allStories,
    required this.index,
    required this.onStoryViewed, // Añadir al constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryViewScreen(
              story: story,
              allStories: allStories,
              initialIndex: index,
              onStoryViewed: onStoryViewed, // Pasar la función recibida
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    story.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading story image: $error');
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              story.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
