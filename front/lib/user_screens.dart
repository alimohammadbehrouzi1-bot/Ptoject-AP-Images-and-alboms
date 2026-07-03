import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_screens.dart';

class FileItem {
  final int id;
  final String name;
  final bool isFolder;
  int? parentId;
  String? caption;
  List<String>? tags;
  int likes;
  bool isLiked;
  final DateTime date;
  List<CommentData> comments;

  FileItem({
    required this.id, 
    required this.name, 
    required this.isFolder, 
    this.parentId,
    this.caption,
    this.tags,
    this.likes = 0,
    this.isLiked = false,
    required this.date,
    List<CommentData>? comments,
  }) : comments = comments ?? [];
}

class CommentData {
  final String username;
  final String text;
  int likes;
  bool isLiked;

  CommentData({required this.username, required this.text, this.likes = 0, this.isLiked = false});
}

class MainNavigation extends StatefulWidget {
  final String username;
  const MainNavigation({super.key, required this.username});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ExploreSocialPage(currentUsername: widget.username),
          MyStuffsPage(username: widget.username),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1A73E8),
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_mosaic_rounded), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_copy_rounded), label: 'Vault'),
          ],
        ),
      ),
    );
  }
}

class ExploreSocialPage extends StatefulWidget {
  final String currentUsername;
  const ExploreSocialPage({super.key, required this.currentUsername});

  @override
  State<ExploreSocialPage> createState() => _ExploreSocialPageState();
}

class _ExploreSocialPageState extends State<ExploreSocialPage> {
  List<FileItem> _allPublicPhotos = [];
  List<FileItem> _feedPhotos = [];
  Map<String, List<FileItem>> _userToPhotos = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllUsersData();
  }

  Future<void> _loadAllUsersData() async {
    try {
      final String response = await rootBundle.loadString('assets/mock_data.json');
      final data = json.decode(response);
      List<FileItem> allPhotos = [];
      Map<String, List<FileItem>> userMap = {};

      for (var user in data['users']) {
        String uname = user['username'];
        List<FileItem> userPhotos = [];
        
        for (var album in user['albums']) {
          for (var img in album['images']) {
            var item = FileItem(
              id: img['id'],
              name: img['name'],
              isFolder: false,
              caption: img['caption'],
              tags: List<String>.from(img['tags']),
              likes: img['likes'],
              isLiked: img['isLiked'],
              date: DateTime.parse(img['date']),
            );
            allPhotos.add(item);
            userPhotos.add(item);
          }
        }
        for (var img in user['standaloneImages']) {
          var item = FileItem(
            id: img['id'],
            name: img['name'],
            isFolder: false,
            caption: img['caption'],
            tags: List<String>.from(img['tags']),
            likes: img['likes'],
            isLiked: img['isLiked'],
            date: DateTime.parse(img['date']),
          );
          allPhotos.add(item);
          userPhotos.add(item);
        }
        userMap[uname] = userPhotos;
      }

      setState(() {
        _allPublicPhotos = allPhotos;
        _userToPhotos = userMap;
        _refreshFeed();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _refreshFeed() {
    if (_allPublicPhotos.isEmpty) return;
    List<FileItem> shuffled = List.from(_allPublicPhotos)..shuffle();
    setState(() {
      _feedPhotos = shuffled.take(5).toList();
    });
  }

  void _handleSearch(String query) {
    if (query.isEmpty) return;
    
    final lowerQuery = query.toLowerCase();
    
    // 1. Search for users who match the name
    List<String> foundUsernames = _userToPhotos.keys.where(
      (name) => name.toLowerCase().contains(lowerQuery),
    ).toList();

    // 2. Search for images whose names match the query
    // We need to keep track of which user owns which image to display correctly
    List<MapEntry<String, FileItem>> matchingImages = [];
    _userToPhotos.forEach((username, photos) {
      for (var photo in photos) {
        if (photo.name.toLowerCase().contains(lowerQuery)) {
          matchingImages.add(MapEntry(username, photo));
        }
      }
    });

    if (foundUsernames.isNotEmpty || matchingImages.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchResultsScreen(
            query: query,
            foundUsernames: foundUsernames,
            matchingImages: matchingImages,
            userToPhotos: _userToPhotos,
            currentUsername: widget.currentUsername,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matches found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _searchController,
            onSubmitted: _handleSearch,
            decoration: const InputDecoration(
              hintText: 'Search Users...',
              prefixIcon: Icon(Icons.search, size: 18),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A73E8)),
            onPressed: _refreshFeed,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async => _refreshFeed(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _feedPhotos.length,
              itemBuilder: (context, index) => _buildModernPost(context, _feedPhotos[index]),
            ),
          ),
    );
  }

  Widget _buildModernPost(BuildContext context, FileItem item) {
    // Determine owner for mock display
    String owner = _userToPhotos.entries
        .firstWhere((e) => e.value.contains(item), orElse: () => MapEntry("Unknown", []))
        .key;

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.blue[50], child: Icon(Icons.person, color: Colors.blue[300])),
            title: Text(owner, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.name), // نمایش اسم عکس زیر نام صاحب اثر
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtherUserProfileScreen(
                    username: owner, 
                    photos: _userToPhotos[owner]!,
                    currentUsername: widget.currentUsername,
                  ),
                ),
              );
            },
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ImageDetailScreen(item: item, username: widget.currentUsername, isReadOnly: true))
              );
            },
            child: Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.image_rounded, size: 64, color: Colors.blue[100]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 6),
                    Text('${item.likes}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.caption ?? "No caption", style: const TextStyle(fontSize: 14)),
                Text(item.date.toString().substring(0, 10), style: TextStyle(color: Colors.grey[400], fontSize: 11)), // نمایش تاریخ زیر کپشن
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OtherUserProfileScreen extends StatelessWidget {
  final String username;
  final List<FileItem> photos;
  final String currentUsername;
  const OtherUserProfileScreen({
    super.key, 
    required this.username, 
    required this.photos,
    required this.currentUsername,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(username), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(radius: 40, backgroundColor: Colors.blue[50], child: Icon(Icons.person, size: 40, color: Colors.blue[300])),
          const SizedBox(height: 16),
          Text(username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Divider(height: 48),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final item = photos[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageDetailScreen(
                          item: item, 
                          username: currentUsername, 
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(item.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SearchResultsScreen extends StatelessWidget {
  final String query;
  final List<String> foundUsernames;
  final List<MapEntry<String, FileItem>> matchingImages;
  final Map<String, List<FileItem>> userToPhotos;
  final String currentUsername;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.foundUsernames,
    required this.matchingImages,
    required this.userToPhotos,
    required this.currentUsername,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          title: Text('Results for "$query"'),
          bottom: const TabBar(
            labelColor: Color(0xFF1A73E8),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1A73E8),
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Photos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Users
            foundUsernames.isEmpty 
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: foundUsernames.length,
                  itemBuilder: (context, index) {
                    final uname = foundUsernames[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blue[50], child: Icon(Icons.person, color: Colors.blue[300])),
                      title: Text(uname, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OtherUserProfileScreen(
                              username: uname, 
                              photos: userToPhotos[uname]!,
                              currentUsername: currentUsername,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            // Tab 2: Photos
            matchingImages.isEmpty 
              ? const Center(child: Text('No photos found'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8,
                  ),
                  itemCount: matchingImages.length,
                  itemBuilder: (context, index) {
                    final owner = matchingImages[index].key;
                    final item = matchingImages[index].value;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageDetailScreen(item: item, username: currentUsername, isReadOnly: true)
                          )
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                  Text('by $owner', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class MyStuffsPage extends StatefulWidget {
  final String username;
  const MyStuffsPage({super.key, required this.username});

  @override
  State<MyStuffsPage> createState() => _MyStuffsPageState();
}

class _MyStuffsPageState extends State<MyStuffsPage> {
  List<FileItem> _allItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  Future<void> _loadMockData() async {
    try {
      final String response = await rootBundle.loadString('assets/mock_data.json');
      final data = json.decode(response);
      final List<FileItem> items = [];
      
      final user = data['users'][0];
      
      for (var album in user['albums']) {
        items.add(FileItem(
          id: album['id'],
          name: album['name'],
          isFolder: true,
          date: DateTime.parse(user['albums'][0]['images'][0]['date']),
        ));
        for (var img in album['images']) {
          items.add(FileItem(
            id: img['id'],
            name: img['name'],
            isFolder: false,
            parentId: album['id'],
            caption: img['caption'],
            tags: List<String>.from(img['tags']),
            likes: img['likes'],
            isLiked: img['isLiked'],
            date: DateTime.parse(img['date']),
          ));
        }
      }
      
      for (var img in user['standaloneImages']) {
        items.add(FileItem(
          id: img['id'],
          name: img['name'],
          isFolder: false,
          caption: img['caption'],
          tags: List<String>.from(img['tags']),
          likes: img['likes'],
          isLiked: img['isLiked'],
          date: DateTime.parse(img['date']),
        ));
      }

      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  FileItem? _currentAlbum;
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Filter types aligned with Java backend search methods
  final Set<String> _activeFilters = {};

  List<FileItem> get _visibleItems {
    if (_searchQuery.isNotEmpty) {
      String query = _searchQuery.toLowerCase();
      
      // searchByTags logic (hashtag or specific filter)
      if (query.startsWith('#')) {
        String tag = query.substring(1);
        return _allItems.where((item) => !item.isFolder && (item.tags?.any((t) => t.toLowerCase().contains(tag)) ?? false)).toList();
      }

      // If filters are active, apply only selected ones
      if (_activeFilters.isNotEmpty) {
        return _allItems.where((item) {
          bool match = false;
          if (_activeFilters.contains('Name')) {
            if (item.name.toLowerCase().contains(query)) match = true;
          }
          if (!item.isFolder && _activeFilters.contains('Caption')) {
            if (item.caption?.toLowerCase().contains(query) ?? false) match = true;
          }
          if (!item.isFolder && _activeFilters.contains('Tags')) {
            if (item.tags?.any((t) => t.toLowerCase().contains(query)) ?? false) match = true;
          }
          if (!item.isFolder && _activeFilters.contains('Comments')) {
            if (item.comments.any((c) => c.text.toLowerCase().contains(query))) match = true;
          }
          if (_activeFilters.contains('Date')) {
            if (item.date.toString().contains(query)) match = true;
          }
          return match;
        }).toList();
      }

      // Default: searchAll logic
      return _allItems.where((item) {
        bool matchName = item.name.toLowerCase().contains(query);
        bool matchCaption = !item.isFolder && (item.caption?.toLowerCase().contains(query) ?? false);
        bool matchTags = !item.isFolder && (item.tags?.any((t) => t.toLowerCase().contains(query)) ?? false);
        bool matchComments = !item.isFolder && item.comments.any((c) => c.text.toLowerCase().contains(query));
        bool matchDate = item.date.toString().contains(query);
        return matchName || matchCaption || matchTags || matchComments || matchDate;
      }).toList();
    }

    if (_currentAlbum == null) {
      return _allItems.where((item) => item.isFolder || item.parentId == null).toList();
    } else {
      return _allItems.where((item) => !item.isFolder && item.parentId == _currentAlbum!.id).toList();
    }
  }

  void _addAlbum(String name) {
    if (name.isNotEmpty) {
      setState(() => _allItems.add(FileItem(id: DateTime.now().millisecondsSinceEpoch, name: name, isFolder: true, date: DateTime.now())));
    }
  }

  void _addImage(Map<String, dynamic> data) {
    setState(() => _allItems.add(FileItem(
      id: DateTime.now().millisecondsSinceEpoch,
      name: data['name'],
      isFolder: false,
      parentId: _currentAlbum?.id,
      caption: data['caption'],
      tags: data['tags'],
      date: DateTime.now(),
    )));
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _moveSelectedImages(int? targetAlbumId) {
    setState(() {
      for (var id in _selectedIds) {
        var item = _allItems.firstWhere((i) => i.id == id);
        if (!item.isFolder) item.parentId = targetAlbumId;
      }
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool canMove = _selectedIds.isNotEmpty && 
                   _selectedIds.every((id) => !_allItems.firstWhere((i) => i.id == id).isFolder);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSelectionMode 
          ? Text('${_selectedIds.length} Selected', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          : Container(
              height: 40,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.tune_rounded, size: 18, color: _activeFilters.isNotEmpty ? Colors.blue : Colors.grey),
                    onPressed: () => _showFilterDialog(context),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
        leading: _isSelectionMode 
          ? IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => setState(() { _isSelectionMode = false; _selectedIds.clear(); }))
          : (_currentAlbum != null && _searchQuery.isEmpty
              ? IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => setState(() => _currentAlbum = null)) 
              : null),
        actions: _isSelectionMode ? [
          if (canMove) IconButton(icon: const Icon(Icons.drive_file_move_outlined, color: Colors.blue), onPressed: () => _showMoveDialog(context)),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () {
            setState(() { _allItems.removeWhere((i) => _selectedIds.contains(i.id)); _selectedIds.clear(); _isSelectionMode = false; });
          }),
        ] : [
          GestureDetector(
            onTap: () => _showUserProfile(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text(widget.username, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  CircleAvatar(radius: 14, backgroundColor: Colors.blue[50], child: Icon(Icons.person, size: 18, color: Colors.blue[300])),
                ],
              ),
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (!_isSelectionMode && _searchQuery.isEmpty) _buildTopControls(),
              if (_activeFilters.isNotEmpty && _searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _activeFilters.map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(f, style: const TextStyle(fontSize: 10)),
                          onDeleted: () => setState(() => _activeFilters.remove(f)),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.9,
                  ),
                  itemCount: _visibleItems.length,
                  itemBuilder: (context, index) {
                    final item = _visibleItems[index];
                    bool isSelected = _selectedIds.contains(item.id);
                    return _buildGridTile(item, isSelected);
                  },
                ),
              ),
            ],
          ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Search Filters'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Name', 'Caption', 'Tags', 'Comments', 'Date'].map((f) => CheckboxListTile(
              title: Text(f),
              value: _activeFilters.contains(f),
              onChanged: (val) {
                setDialogState(() {
                  if (val!) {
                    _activeFilters.add(f);
                  } else {
                    _activeFilters.remove(f);
                  }
                });
                setState(() {});
              },
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () { setState(() => _activeFilters.clear()); Navigator.pop(context); }, child: const Text('Clear All')),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _controlBtn(Icons.add_photo_alternate_rounded, "Upload", Colors.blue, () async {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadImageScreen()));
            if (res != null) _addImage(res);
          }),
          const SizedBox(width: 12),
          if (_currentAlbum == null)
            _controlBtn(Icons.create_new_folder_rounded, "New Album", Colors.indigo, () => _showCreateAlbumDialog(context)),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(15)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridTile(FileItem item, bool isSelected) {
    return InkWell(
      onLongPress: () => _toggleSelection(item.id),
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(item.id);
        } else if (item.isFolder) {
          setState(() { _currentAlbum = item; _searchQuery = ""; _searchController.clear(); });
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ImageDetailScreen(item: item, username: widget.username)));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.isFolder ? Icons.folder_rounded : Icons.image_rounded, size: 48, color: item.isFolder ? Colors.blue[200] : Colors.grey[200]),
            const SizedBox(height: 12),
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showCreateAlbumDialog(BuildContext context) {
    final TextEditingController nameC = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Name your album'),
      content: TextField(controller: nameC),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { _addAlbum(nameC.text); Navigator.pop(context); }, child: const Text('Create')),
      ],
    ));
  }

  void _showMoveDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Move to Album'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Main Vault'),
              onTap: () { _moveSelectedImages(null); Navigator.pop(context); },
            ),
            ..._allItems.where((f) => f.isFolder).map((album) => ListTile(
              leading: const Icon(Icons.folder_rounded, color: Colors.blue),
              title: Text(album.name),
              onTap: () { _moveSelectedImages(album.id); Navigator.pop(context); },
            )),
          ],
        ),
      ),
    ));
  }

  void _showUserProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 40, backgroundColor: Colors.blue[50], child: Icon(Icons.person, size: 40, color: Colors.blue[300])),
            const SizedBox(height: 16),
            Text(widget.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileDetailScreen(allItems: _allItems, username: widget.username)));
              },
              child: const Text('View Profile'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), 
                  (route) => false
                );
              }, 
              child: const Text('Log Out')
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDetailScreen extends StatefulWidget {
  final List<FileItem> allItems;
  final String username;
  const ProfileDetailScreen({super.key, required this.allItems, required this.username});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool _isProfilePicSelected = false;

  void _showChangePasswordDialog() {
    final TextEditingController usernameC = TextEditingController();
    final TextEditingController oldPassC = TextEditingController();
    final TextEditingController newPassC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: usernameC, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: oldPassC, decoration: const InputDecoration(labelText: 'Old Password'), obscureText: true),
            TextField(controller: newPassC, decoration: const InputDecoration(labelText: 'New Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (usernameC.text.isNotEmpty && oldPassC.text.isNotEmpty && newPassC.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<FileItem> likedPhotos = widget.allItems.where((item) => !item.isFolder && item.isLiked).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Profile Settings'), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(radius: 64, backgroundColor: Colors.blue[50], child: Icon(_isProfilePicSelected ? Icons.check_circle : Icons.person, size: 64, color: Colors.blue[300])),
                  Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.blue, radius: 18, child: IconButton(icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white), onPressed: () => setState(() => _isProfilePicSelected = true)))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            ListTile(leading: const Icon(Icons.lock_rounded, color: Colors.blue), title: const Text('Security & Password'), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16), onTap: _showChangePasswordDialog, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), tileColor: Colors.grey[50]),
            const Divider(height: 64),
            Row(children: [const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20), const SizedBox(width: 8), Text('Liked Photos (${likedPhotos.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            likedPhotos.isEmpty
                ? const Text('No liked photos yet', style: TextStyle(color: Colors.grey))
                : GridView.builder(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(), 
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12), 
                    itemCount: likedPhotos.length, 
                    itemBuilder: (context, index) {
                      final item = likedPhotos[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => ImageDetailScreen(item: item, username: widget.username, isReadOnly: true))
                          );
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), 
                                child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(item.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      );
                    }
                  ),
          ],
        ),
      ),
    );
  }
}

class ImageDetailScreen extends StatefulWidget {
  final FileItem item;
  final String username;
  final bool isReadOnly;
  const ImageDetailScreen({super.key, required this.item, required this.username, this.isReadOnly = false});

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)), 
        title: Text(widget.item.name), 
        actions: [
          if (!widget.isReadOnly)
            IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue), onPressed: () => _showEditDialog())
        ]
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(aspectRatio: 1.2, child: Container(color: Colors.grey[50], child: Icon(Icons.image, size: 80, color: Colors.blue[50]))),
                  _buildInteractionRow(),
                  _buildMetadata(),
                  _buildCommentsList(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final captionC = TextEditingController(text: widget.item.caption);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Edit Photo'),
      content: TextField(controller: captionC, decoration: const InputDecoration(labelText: 'Caption')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () { setState(() => widget.item.caption = captionC.text); Navigator.pop(context); }, child: const Text('Save'))],
    ));
  }

  Widget _buildInteractionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          IconButton(icon: Icon(widget.item.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: widget.item.isLiked ? Colors.redAccent : Colors.black, size: 28), onPressed: () => setState(() { widget.item.isLiked = !widget.item.isLiked; widget.item.likes += widget.item.isLiked ? 1 : -1; })),
          const Spacer(),
          Text('${widget.item.likes} likes', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.item.caption != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(widget.item.caption!, style: const TextStyle(fontSize: 14))),
          Wrap(spacing: 8, children: (widget.item.tags ?? []).map((t) => Text('#$t', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13))).toList()),
          const SizedBox(height: 6),
          Text(widget.item.date.toString().substring(0, 10), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          const Divider(height: 48),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.item.comments.length,
      itemBuilder: (context, index) {
        final comment = widget.item.comments[index];
        return ListTile(dense: true, leading: const CircleAvatar(radius: 12), title: Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: Text(comment.text), trailing: IconButton(icon: Icon(comment.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: comment.isLiked ? Colors.redAccent : Colors.grey[400]), onPressed: () => setState(() { comment.isLiked = !comment.isLiked; comment.likes += comment.isLiked ? 1 : -1; })));
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 13)))),
          TextButton(onPressed: () { if (_commentController.text.isNotEmpty) { setState(() { widget.item.comments.add(CommentData(username: widget.username, text: _commentController.text)); _commentController.clear(); }); } }, child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});
  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  final nameC = TextEditingController();
  final capC = TextEditingController();
  final tagC = TextEditingController();
  final List<String> tags = [];
  bool selected = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('New Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)), actions: [if (selected && nameC.text.isNotEmpty) TextButton(onPressed: () => Navigator.pop(context, {'name': nameC.text, 'caption': capC.text, 'tags': tags}), child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            InkWell(onTap: () => setState(() => selected = true), child: Container(height: 220, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)), child: Icon(selected ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, size: 50, color: Colors.blue[100]))),
            const SizedBox(height: 25),
            TextField(controller: nameC, onChanged: (v) => setState(() {}), decoration: const InputDecoration(labelText: 'Image Title (Required)', border: UnderlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: capC, maxLines: 2, decoration: const InputDecoration(labelText: 'Caption (Optional)', border: UnderlineInputBorder())),
            const SizedBox(height: 15),
            Row(children: [Expanded(child: TextField(controller: tagC, decoration: const InputDecoration(hintText: 'Add a tag', border: InputBorder.none))), IconButton(icon: const Icon(Icons.add_circle_outline_rounded), onPressed: () { if (tagC.text.isNotEmpty) { setState(() { tags.add(tagC.text); tagC.clear(); }); } })]),
            Wrap(spacing: 8, children: tags.map((t) => Chip(label: Text('#$t'), onDeleted: () => setState(() => tags.remove(t)))).toList()),
          ],
        ),
      ),
    );
  }
}
