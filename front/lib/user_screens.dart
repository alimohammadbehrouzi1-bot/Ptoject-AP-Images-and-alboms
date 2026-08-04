import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'data_service.dart';
import 'auth_screens.dart';

class FileItem {
  final int id;
  final String name;
  final bool isFolder;
  final String ownerName;
  final Uint8List? imageBytes;
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
    this.ownerName = "Me",
    this.imageBytes,
    this.parentId,
    this.caption,
    this.tags,
    this.likes = 0,
    this.isLiked = false,
    required this.date,
    List<CommentData>? comments,
  }) : comments = List<CommentData>.from(comments ?? const []);
}

class CommentData {
  final String username;
  final String text;
  final DateTime date;
  int likes;
  bool isLiked;
  CommentData({
    required this.username,
    required this.text,
    required this.date,
    this.likes = 0,
    this.isLiked = false,
  });
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
          HomePage(username: widget.username),
          GlobalUserSearchPage(currentUsername: widget.username),
          MyStuffsPage(username: widget.username),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_copy_rounded),
              label: 'Vault',
            ),
          ],
        ),
      ),
    );
  }
}

// --- HOME PAGE (All Photos Feed) ---
class HomePage extends StatelessWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Home Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<FileItem>>(
        future: DataService().getAllPhotos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('No photos yet'));
          }
          final List<FileItem> allPhotos = snapshot.data ?? [];
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: allPhotos.length,
            itemBuilder: (context, index) {
              final item = allPhotos[index];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageDetailScreen(
                      item: item,
                      username: username,
                      isReadOnly: item.ownerName != username,
                    ),
                  ),
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: item.imageBytes != null
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Image.memory(
                                      item.imageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    ),
                                  )
                                : const Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.blue,
                                  ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'by ${item.ownerName}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- GLOBAL USER SEARCH (Matches Vault Style) ---
class GlobalUserSearchPage extends StatefulWidget {
  final String currentUsername;
  const GlobalUserSearchPage({super.key, required this.currentUsername});

  @override
  State<GlobalUserSearchPage> createState() => _GlobalUserSearchPageState();
}

class _GlobalUserSearchPageState extends State<GlobalUserSearchPage> {
  final TextEditingController _searchC = TextEditingController();
  String? _foundUsername;
  List<FileItem> _userItems = [];
  final List<FileItem> _visibleItems = [];
  final ScrollController _scrollController = ScrollController();
  FileItem? _currentAlbum;
  bool _isLastPage = false;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        _loadMore();
      }
    });
  }

  void _handleSearch(String query) async {
    if (query.isEmpty) return;

    final items = await DataService().getVaultItems(query);
    if (items.isNotEmpty && mounted) {
      setState(() {
        _foundUsername = query;
        _userItems = items;
        _currentAlbum = null;
        _visibleItems.clear();
        _isLastPage = false;
        _loadMore();
      });
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not found')));
    }
  }

  Future<void> _refreshData() async {
    final String? foundName = _foundUsername;
    if (foundName != null) {
      _userItems = await DataService().getVaultItems(foundName);
    }
    _visibleItems.clear();
    _isLastPage = false;
    _loadMore();
  }

  void _loadMore() {
    if (_isLastPage || _foundUsername == null) return;
    setState(() {
      List<FileItem> source = _currentAlbum == null
          ? _userItems.where((i) => i.isFolder || i.parentId == null).toList()
          : _userItems
                .where((i) => !i.isFolder && i.parentId == _currentAlbum!.id)
                .toList();

      int nextCount = _visibleItems.length + _pageSize;
      if (nextCount >= source.length) {
        nextCount = source.length;
        _isLastPage = true;
      }
      _visibleItems.clear();
      _visibleItems.addAll(source.take(nextCount));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: _foundUsername == null || _currentAlbum == null
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchC,
                  onSubmitted: _handleSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search Username',
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: InputBorder.none,
                  ),
                ),
              )
            : Text(
                _foundUsername ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        leading: _currentAlbum != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () {
                  setState(() {
                    _currentAlbum = null;
                    _refreshData();
                  });
                },
              )
            : (_foundUsername != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _foundUsername = null;
                          _searchC.clear();
                        });
                      },
                    )
                  : null),
      ),
      body: _foundUsername == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_search_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Find a user to see their vault',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.9,
              ),
              itemCount: _visibleItems.length + (_isLastPage ? 0 : 2),
              itemBuilder: (context, i) {
                if (i >= _visibleItems.length) {
                  return const SizedBox(height: 50);
                }
                final item = _visibleItems[i];
                return InkWell(
                  onTap: () {
                    if (item.isFolder) {
                      setState(() {
                        _currentAlbum = item;
                        _refreshData();
                      });
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageDetailScreen(
                            item: item,
                            username: widget.currentUsername,
                            isReadOnly: true,
                          ),
                        ),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: item.isFolder
                                ? Icon(
                                    Icons.folder_rounded,
                                    size: 48,
                                    color: Colors.blue.withValues(alpha: 0.5),
                                  )
                                : item.imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.memory(
                                      item.imageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    ),
                                  )
                                : Icon(
                                    Icons.image_rounded,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// --- PERSONAL VAULT ---
class MyStuffsPage extends StatefulWidget {
  final String username;
  const MyStuffsPage({super.key, required this.username});

  @override
  State<MyStuffsPage> createState() => _MyStuffsPageState();
}

class _MyStuffsPageState extends State<MyStuffsPage> {
  List<FileItem> _allVaultItems = [];
  final List<FileItem> _visibleItems = [];
  final ScrollController _scrollController = ScrollController();
  FileItem? _currentAlbum;
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  final TextEditingController _searchC = TextEditingController();
  String _searchQ = "";
  final Set<String> _filters = {};
  bool _isLastPage = false;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _refresh();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        _loadMore();
      }
    });
  }

  Future<void> _refresh() async {
    final List<FileItem> items = await DataService().getVaultItems(
      widget.username,
    );
    setState(() {
      _allVaultItems = items;
      _visibleItems.clear();
      _isLastPage = false;
      _loadMore();
    });
  }

  void _loadMore() {
    if (_isLastPage) return;
    setState(() {
      List<FileItem> source = _getFilteredSource();
      int nextCount = _visibleItems.length + _pageSize;
      if (nextCount >= source.length) {
        nextCount = source.length;
        _isLastPage = true;
      }
      _visibleItems.clear();
      _visibleItems.addAll(source.take(nextCount));
    });
  }

  List<FileItem> _getFilteredSource() {
    if (_searchQ.isNotEmpty) {
      final q = _searchQ.toLowerCase();
      return _allVaultItems.where((item) {
        if (q.startsWith('#')) {
          return !item.isFolder &&
              (item.tags?.any(
                    (t) => t.toLowerCase().contains(q.substring(1)),
                  ) ??
                  false);
        }
        if (_filters.isEmpty) {
          return item.name.toLowerCase().contains(q) ||
              (!item.isFolder &&
                  (item.caption?.toLowerCase().contains(q) ?? false));
        }
        bool m = false;
        if (_filters.contains('Name') && item.name.toLowerCase().contains(q)) {
          m = true;
        }
        if (_filters.contains('Caption') &&
            !item.isFolder &&
            (item.caption?.toLowerCase().contains(q) ?? false)) {
          m = true;
        }
        if (_filters.contains('Tags') &&
            !item.isFolder &&
            (item.tags?.any((t) => t.toLowerCase().contains(q)) ?? false)) {
          m = true;
        }
        return m;
      }).toList();
    }
    return _currentAlbum == null
        ? _allVaultItems.where((i) => i.isFolder || i.parentId == null).toList()
        : _allVaultItems
              .where((i) => !i.isFolder && i.parentId == _currentAlbum!.id)
              .toList();
  }

  void _toggle(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _isSelectionMode = _selectedIds.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool canMove =
        _selectedIds.isNotEmpty &&
        _selectedIds.every(
          (id) => !_allVaultItems.firstWhere((i) => i.id == id).isFolder,
        );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: _isSelectionMode
            ? Text('${_selectedIds.length} Selected')
            : Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchC,
                  onChanged: (v) {
                    setState(() => _searchQ = v);
                    _refresh();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune, size: 18),
                      onPressed: () => _showFilterDialog(),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                }),
              )
            : (_currentAlbum != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => setState(() {
                        _currentAlbum = null;
                        _refresh();
                      }),
                    )
                  : null),
        actions: _isSelectionMode
            ? [
                if (canMove)
                  IconButton(
                    icon: const Icon(
                      Icons.drive_file_move_outlined,
                      color: Colors.blue,
                    ),
                    onPressed: () => _showMoveDialog(),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    for (var id in _selectedIds) {
                      DataService().deleteItem(id);
                    }
                    setState(() {
                      _selectedIds.clear();
                      _isSelectionMode = false;
                      _refresh();
                    });
                  },
                ),
              ]
            : [
                GestureDetector(
                  onTap: () => _showUserSheet(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      child: Text(widget.username[0].toUpperCase()),
                    ),
                  ),
                ),
              ],
      ),
      body: Column(
        children: [
          if (!_isSelectionMode && _searchQ.isEmpty) _buildControls(),
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.9,
              ),
              itemCount: _visibleItems.length + (_isLastPage ? 0 : 2),
              itemBuilder: (context, i) {
                if (i >= _visibleItems.length) {
                  return const SizedBox(height: 50);
                }
                final item = _visibleItems[i];
                bool sel = _selectedIds.contains(item.id);
                return InkWell(
                  onLongPress: () => _toggle(item.id),
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggle(item.id);
                    } else if (item.isFolder) {
                      setState(() {
                        _currentAlbum = item;
                        _refresh();
                      });
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageDetailScreen(
                            item: item,
                            username: widget.username,
                          ),
                        ),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: sel ? Colors.blue : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: item.isFolder
                                ? Icon(
                                    Icons.folder_rounded,
                                    size: 48,
                                    color: Colors.blue.withValues(alpha: 0.5),
                                  )
                                : item.imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.memory(
                                      item.imageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    ),
                                  )
                                : Icon(
                                    Icons.image_rounded,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
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

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _btn(Icons.add_a_photo, "Upload", Colors.blue, () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UploadImageScreen(
                  albums: const [], // Simplified for now
                ),
              ),
            );
            if (res != null) {
              await DataService().addImage(widget.username, res);
              _refresh();
            }
          }),
          const SizedBox(width: 12),
          if (_currentAlbum == null)
            _btn(
              Icons.folder_open,
              "Album",
              Colors.indigo,
              () => _showCreateAlbum(),
            ),
        ],
      ),
    );
  }

  Widget _btn(IconData i, String l, Color c, VoidCallback t) => Expanded(
    child: InkWell(
      onTap: t,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, color: c, size: 20),
            const SizedBox(width: 8),
            Text(
              l,
              style: TextStyle(color: c, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Filters'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Name', 'Caption', 'Tags']
                .map(
                  (f) => CheckboxListTile(
                    title: Text(f),
                    value: _filters.contains(f),
                    onChanged: (v) {
                      setS(() {
                        if (v!) {
                          _filters.add(f);
                        } else {
                          _filters.remove(f);
                        }
                      });
                      _refresh();
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _filters.clear());
                _refresh();
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAlbum() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Album'),
        content: TextField(controller: c),
        actions: [
          ElevatedButton(
            onPressed: () {
              DataService().addAlbum(widget.username, c.text);
              _refresh();
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to...'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Root'),
                onTap: () {
                  DataService().movePhotos(_selectedIds.toList(), null);
                  _refresh();
                  Navigator.pop(context);
                  setState(() => _isSelectionMode = false);
                },
              ),
              ..._allVaultItems
                  .where((i) => i.isFolder)
                  .map(
                    (f) => ListTile(
                      title: Text(f.name),
                      onTap: () {
                        DataService().movePhotos(_selectedIds.toList(), f.id);
                        _refresh();
                        Navigator.pop(context);
                        setState(() => _isSelectionMode = false);
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(widget.username[0].toUpperCase()),
            ),
            const SizedBox(height: 16),
            Text(
              widget.username,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileDetailScreen(username: widget.username),
                  ),
                );
              },
              child: const Text('Settings'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                DataService().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              },
              child: const Text('Log Out'),
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
  const ImageDetailScreen({
    super.key,
    required this.item,
    required this.username,
    this.isReadOnly = false,
  });
  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  final _commentC = TextEditingController();
  bool _isLiking = false;
  bool _isSendingComment = false;

  Future<void> _sendComment() async {
    final text = _commentC.text.trim();
    if (text.isEmpty || _isSendingComment) return;

    setState(() => _isSendingComment = true);

    final comment = await DataService().addComment(
      widget.item.id,
      widget.username,
      text,
    );

    if (mounted) {
      setState(() {
        _isSendingComment = false;
        if (comment != null) {
          widget.item.comments.add(comment);
          _commentC.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add comment')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.item.name),
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: _showEdit,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: widget.item.imageBytes != null
                          ? Image.memory(
                              widget.item.imageBytes!,
                              fit: BoxFit.contain,
                            )
                          : const Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.blue,
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                widget.item.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: widget.item.isLiked ? Colors.red : null,
                              ),
                              onPressed: _isLiking
                                  ? null
                                  : () async {
                                      final oldIsLiked = widget.item.isLiked;
                                      final oldLikes = widget.item.likes;

                                      setState(() {
                                        _isLiking = true;
                                        widget.item.isLiked = !oldIsLiked;
                                        widget.item.likes += widget.item.isLiked
                                            ? 1
                                            : -1;
                                      });

                                      final response = await DataService()
                                          .toggleLike(widget.item.id);

                                      if (mounted) {
                                        setState(() {
                                          _isLiking = false;
                                          if (response.isSuccess &&
                                              response.data != null) {
                                            widget.item.likes =
                                                (response.data['likes'] as num)
                                                    .toInt();
                                            widget.item.isLiked =
                                                response.data['isLiked'] ==
                                                true;
                                          } else {
                                            // Rollback
                                            widget.item.isLiked = oldIsLiked;
                                            widget.item.likes = oldLikes;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Action failed'),
                                              ),
                                            );
                                          }
                                        });
                                      }
                                    },
                            ),
                            Text('${widget.item.likes} likes'),
                          ],
                        ),
                        Text(
                          widget.item.caption ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Wrap(
                          spacing: 8,
                          children: (widget.item.tags ?? [])
                              .map(
                                (t) => Text(
                                  '#$t',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const Divider(height: 48),
                        const Text(
                          'Comments',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...widget.item.comments.map(
                          (c) => ListTile(
                            dense: true,
                            leading: const CircleAvatar(radius: 12),
                            title: Text(
                              c.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.text),
                                Text(
                                  '${c.date.hour}:${c.date.minute} - ${c.date.day}/${c.date.month}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${c.likes}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                IconButton(
                                  icon: Icon(
                                    c.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 16,
                                    color: c.isLiked ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      c.isLiked = !c.isLiked;
                                      c.likes += c.isLiked ? 1 : -1;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentC,
                    decoration: const InputDecoration(
                      hintText: 'Add comment...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSendingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isSendingComment ? null : _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEdit() {
    final captionC = TextEditingController(text: widget.item.caption);
    final List<String> tempTags = List.from(widget.item.tags ?? []);
    final tagC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: captionC,
                  decoration: const InputDecoration(labelText: 'Caption'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagC,
                        decoration: const InputDecoration(hintText: 'Add tag'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (tagC.text.isNotEmpty) {
                          setDialogState(() {
                            tempTags.add(tagC.text);
                            tagC.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: tempTags
                      .map(
                        (t) => Chip(
                          label: Text('#$t'),
                          onDeleted: () =>
                              setDialogState(() => tempTags.remove(t)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.item.caption = captionC.text;
                  widget.item.tags = List.from(tempTags);
                });
                DataService().updatePhoto(
                  widget.item.id,
                  captionC.text,
                  tempTags,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDetailScreen extends StatefulWidget {
  final String username;
  const ProfileDetailScreen({super.key, required this.username});
  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final likedFuture = DataService().getAllPhotos();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: FutureBuilder<List<FileItem>>(
        future: likedFuture,
        builder: (context, snapshot) {
          final liked = snapshot.data?.where((p) => p.isLiked).toList() ?? [];

          return FutureBuilder<Map<String, int>>(
            future: DataService().getUserStats(widget.username),
            builder: (context, statsSnapshot) {
              final stats = statsSnapshot.data ?? {'photos': 0, 'albums': 0};

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      child: Text(
                        widget.username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statItem('Photos', stats['photos'] ?? 0),
                        const SizedBox(width: 24),
                        _statItem('Albums', stats['albums'] ?? 0),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark Mode'),
                      trailing: Switch(
                        value:
                            DataService().themeNotifier.value == ThemeMode.dark,
                        onChanged: (v) =>
                            setState(() => DataService().toggleTheme(v)),
                      ),
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Change Username'),
                      onTap: _showChangeName,
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Change Password'),
                      onTap: _showChangePassword,
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.share_outlined),
                      title: const Text('Sharing & Access'),
                      onTap: _showSharingSettings,
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: _showDeleteConfirm,
                      tileColor: Colors.red.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const Divider(height: 64),
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Liked Photos (${liked.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    liked.isEmpty
                        ? const Text('No likes yet')
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: liked.length,
                            itemBuilder: (context, i) => InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImageDetailScreen(
                                    item: liked[i],
                                    username: widget.username,
                                    isReadOnly: true,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    liked[i].name,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statItem(String label, int count) => Column(
    children: [
      Text(
        count.toString(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );

  void _showSharingSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sharing & Access',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Public Profile'),
              subtitle: const Text('Allow others to search for you'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('Allow Comments'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('Show Likes'),
              value: true,
              onChanged: (v) {},
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeName() {
    final nameC = TextEditingController(text: widget.username);
    final passC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'New Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passC,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameC.text.isEmpty || passC.text.isEmpty) return;
              final response = await DataService().updateProfile(
                oldUsername: widget.username,
                newUsername: nameC.text.trim(),
                currentPassword: passC.text,
              );
              if (response.isSuccess) {
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          MainNavigation(username: nameC.text.trim()),
                    ),
                    (r) => false,
                  );
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response.message ?? 'Update failed')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword() {
    final oldPassC = TextEditingController();
    final newPassC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassC,
              decoration: const InputDecoration(labelText: 'Old Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPassC,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (oldPassC.text.isEmpty || newPassC.text.isEmpty) return;
              final response = await DataService().changePassword(
                username: widget.username,
                oldPassword: oldPassC.text,
                newPassword: newPassC.text,
              );
              if (response.isSuccess) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully'),
                    ),
                  );
                  Navigator.pop(context);
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response.message ?? 'Update failed')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              DataService().deleteAccount(widget.username);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class UploadImageScreen extends StatefulWidget {
  final List<FileItem> albums;
  const UploadImageScreen({super.key, required this.albums});
  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  final nC = TextEditingController();
  final cC = TextEditingController();
  final tC = TextEditingController();
  final List<String> tags = [];
  int? selectedAlbumId;
  File? _imageFile;
  String? _originalFileName;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _originalFileName = image.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            InkWell(
              onTap: () => _showPickerOptions(),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to select photo',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nC,
              decoration: const InputDecoration(labelText: 'Title *'),
            ),
            TextField(
              controller: cC,
              decoration: const InputDecoration(labelText: 'Caption'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Target Album'),
              initialValue: selectedAlbumId,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Root (No Album)'),
                ),
                ...widget.albums.map(
                  (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                ),
              ],
              onChanged: (v) => setState(() => selectedAlbumId = v),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tC,
                    decoration: const InputDecoration(hintText: 'Add tag'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (tC.text.isNotEmpty) {
                      setState(() => tags.add(tC.text));
                      tC.clear();
                    }
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: tags
                  .map(
                    (t) => Chip(
                      label: Text('#$t'),
                      onDeleted: () => setState(() => tags.remove(t)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (nC.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nC.text,
                    'caption': cC.text,
                    'tags': tags,
                    'albumId': selectedAlbumId,
                    'imageFile': _imageFile,
                    'originalFileName': _originalFileName,
                  });
                }
              },
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
