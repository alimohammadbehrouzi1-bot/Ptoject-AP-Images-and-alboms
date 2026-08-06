import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'core/network/api_response.dart';
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
  final int id;
  final String username;
  final String text;
  final DateTime date;
  int likes;
  bool isLiked;
  CommentData({
    required this.id,
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
class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<FileItem>>? _photosFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _photosFuture = DataService().getAllPhotos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Home Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<FileItem>>(
        future: _photosFuture,
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
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageDetailScreen(
                        item: item,
                        username: widget.username,
                        isReadOnly: item.ownerName != widget.username,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    _refresh();
                  }
                },
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
                  onTap: () async {
                    if (item.isFolder) {
                      setState(() {
                        _currentAlbum = item;
                        _refreshData();
                      });
                    } else {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageDetailScreen(
                            item: item,
                            username: widget.currentUsername,
                            isReadOnly: true,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        _refreshData();
                      }
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
      if (_currentAlbum != null) {
        try {
          _currentAlbum = items.firstWhere(
            (i) => i.isFolder && i.id == _currentAlbum!.id,
          );
        } catch (e) {
          _currentAlbum = null;
        }
      }
      _visibleItems.clear();
      _isLastPage = false;
      _loadMore();
    });
  }

  void _loadMore() {
    if (_isLastPage) return;
    setState(() {
      List<FileItem> source = _getFilteredSource();
      int nextCount = _visibleItems.length + _pageSize;      if (nextCount >= source.length) {
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
                if (_selectedIds.length == 1 &&
                    _allVaultItems
                        .firstWhere((i) => i.id == _selectedIds.first)
                        .isFolder)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                    onPressed: () => _showRenameDialog(_selectedIds.first),
                  ),
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
                  onPressed: () => _confirmDelete(),
                ),
              ]
            : [
                if (_currentAlbum != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showRenameDialog(_currentAlbum!.id),
                  ),
                if (_currentAlbum != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDeleteCurrentAlbum(),
                  ),
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
                  onTap: () async {
                    if (_isSelectionMode) {
                      _toggle(item.id);
                    } else if (item.isFolder) {
                      setState(() {
                        _currentAlbum = item;
                        _refresh();
                      });
                    } else {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageDetailScreen(
                            item: item,
                            username: widget.username,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        _refresh();
                      }
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
            final albums = _allVaultItems.where((i) => i.isFolder).toList();
            final res = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UploadImageScreen(
                  albums: albums,
                  initialAlbumId: _currentAlbum?.id,
                ),
              ),
            );
            if (res != null) {
              final resp = await DataService().addImage(widget.username, res);
              if (mounted) {
                if (resp.isSuccess) {
                  _refresh();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(resp.message ?? 'Upload failed')),
                  );
                }
              }
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
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Album'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              labelText: 'Album Name',
              hintText: 'Enter album name',
            ),
            enabled: !isSaving,
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = c.text.trim();
                      if (name.isEmpty) return;

                      setDialogState(() => isSaving = true);
                      final resp = await DataService().addAlbum(name);

                      if (mounted) {
                        if (resp.isSuccess) {
                          Navigator.pop(context);
                          _refresh();
                        } else {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(resp.message ?? 'Error')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(int id) {
    final item = _allVaultItems.firstWhere((i) => i.id == id);
    final c = TextEditingController(text: item.name);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rename Album'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'New Name'),
            enabled: !isSaving,
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = c.text.trim();
                      if (name.isEmpty) return;

                      setDialogState(() => isSaving = true);
                      final resp = await DataService().renameAlbum(
                        albumId: id,
                        newName: name,
                      );

                      if (mounted) {
                        if (resp.isSuccess) {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          });
                          Navigator.pop(context);
                          _refresh();
                        } else {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(resp.message ?? 'Error')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCurrentAlbum() {
    if (_currentAlbum == null) return;
    final albumName = _currentAlbum!.name;
    final albumId = _currentAlbum!.id;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Album?'),
              content: Text(
                'Are you sure you want to delete "$albumName"? Photos inside will be preserved.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          final resp = await DataService().deleteAlbum(albumId);
                          if (mounted) {
                            if (resp.isSuccess) {
                              setState(() {
                                _currentAlbum = null;
                              });
                              Navigator.pop(context);
                              _refresh();
                            } else {
                              setDialogState(() => isDeleting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(resp.message ?? 'Error')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Items?'),
              content: const Text(
                'Are you sure you want to delete selected items? Deleting albums will not delete photos inside them.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          final idsToDelete = List<int>.from(_selectedIds);
                          bool anyError = false;
                          String? lastErrorMessage;

                          for (int id in idsToDelete) {
                            final item = _allVaultItems.firstWhere(
                              (i) => i.id == id,
                              orElse: () => FileItem(
                                id: -1,
                                name: '',
                                isFolder: true,
                                date: DateTime.now(),
                              ),
                            );
                            if (item.id != -1) {
                              final ApiResponse resp;
                              if (item.isFolder) {
                                resp = await DataService().deleteAlbum(id);
                              } else {
                                resp = await DataService().deleteImage(id);
                              }

                              if (!resp.isSuccess) {
                                anyError = true;
                                lastErrorMessage = resp.message;
                              } else {
                                _selectedIds.remove(id);
                              }
                            }
                          }
                          if (mounted) {
                            setState(() {
                              _isSelectionMode = _selectedIds.isNotEmpty;
                            });
                            Navigator.pop(context);
                            if (anyError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    lastErrorMessage ?? 'Some deletions failed',
                                  ),
                                ),
                              );
                            }
                            _refresh();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMoveDialog() {
    final selectedItems = _allVaultItems
        .where((i) => _selectedIds.contains(i.id))
        .toList();
    if (selectedItems.any((i) => i.isFolder)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only images can be moved')),
      );
      return;
    }

    final albums = _allVaultItems.where((i) => i.isFolder).toList();
    final sourceId = _currentAlbum?.id;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isMoving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Move to...'),
              content:
                  isMoving
                      ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            if (sourceId != null)
                              ListTile(
                                leading: const Icon(Icons.folder_open),
                                title: const Text('Root'),
                                onTap: () async {
                                  setDialogState(() => isMoving = true);
                                  final resp = await DataService().moveImages(
                                    imageIds: _selectedIds.toList(),
                                    sourceAlbumId: sourceId,
                                    targetAlbumId: null,
                                  );
                                  if (mounted) {
                                    if (resp.isSuccess) {
                                      setState(() {
                                        _isSelectionMode = false;
                                        _selectedIds.clear();
                                      });
                                      Navigator.pop(context);
                                      _refresh();
                                    } else {
                                      setDialogState(() => isMoving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            resp.message ?? 'Move failed',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ...albums.where((a) => a.id != sourceId).map(
                              (f) => ListTile(
                                leading: const Icon(Icons.folder),
                                title: Text(f.name),
                                onTap: () async {
                                  setDialogState(() => isMoving = true);
                                  final resp = await DataService().moveImages(
                                    imageIds: _selectedIds.toList(),
                                    sourceAlbumId: sourceId,
                                    targetAlbumId: f.id,
                                  );
                                  if (mounted) {
                                    if (resp.isSuccess) {
                                      setState(() {
                                        _isSelectionMode = false;
                                        _selectedIds.clear();
                                      });
                                      Navigator.pop(context);
                                      _refresh();
                                    } else {
                                      setDialogState(() => isMoving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            resp.message ?? 'Move failed',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
              actions: [
                TextButton(
                  onPressed: isMoving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
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
  final Set<int> _likingCommentIds = {};

  late List<String> _currentTags;
  late String? _currentCaption;

  @override
  void initState() {
    super.initState();
    _currentTags = List.from(widget.item.tags ?? []);
    _currentCaption = widget.item.caption;
  }

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
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmDelete,
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
                          _currentCaption ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                        if (_currentTags.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No tags',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            children: _currentTags
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
                                  icon: _likingCommentIds.contains(c.id)
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          c.isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 16,
                                          color: c.isLiked
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                  onPressed: _likingCommentIds.contains(c.id)
                                      ? null
                                      : () => _toggleCommentLike(c),
                                ),
                                if (c.username == widget.username)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _confirmDeleteComment(c),
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

  Future<void> _toggleCommentLike(CommentData c) async {
    setState(() => _likingCommentIds.add(c.id));
    final resp = await DataService().toggleCommentLike(c.id);
    if (mounted) {
      setState(() {
        _likingCommentIds.remove(c.id);
        if (resp.isSuccess) {
          final rawComment = resp.data?['comment'];
          if (rawComment is Map) {
            c.likes = (rawComment['likes'] as num).toInt();
            c.isLiked = rawComment['isLiked'] == true;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp.message ?? 'Like failed')),
          );
        }
      });
    }
  }

  void _confirmDeleteComment(CommentData c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final resp = await DataService().deleteComment(c.id);
              if (mounted) {
                if (resp.isSuccess) {
                  setState(() {
                    widget.item.comments.removeWhere((com) => com.id == c.id);
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(resp.message ?? 'Delete failed')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Photo?'),
              content: Text(
                'Are you sure you want to delete "${widget.item.name}"? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          final response = await DataService().deleteImage(
                            widget.item.id,
                          );
                          if (mounted) {
                            if (response.isSuccess) {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(
                                context,
                                true,
                              ); // Go back with success result
                            } else {
                              setDialogState(() => isDeleting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    response.message ?? 'Delete failed',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEdit() {
    final captionC = TextEditingController(text: _currentCaption);
    final tagC = TextEditingController(text: _currentTags.join(', '));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: captionC,
                      decoration: const InputDecoration(labelText: 'Caption'),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tagC,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        hintText: 'market, option, test',
                      ),
                      enabled: !isSaving,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final parsedTags = _parseTags(tagC.text);
                          setDialogState(() => isSaving = true);

                          final response = await DataService().updatePhoto(
                            imageId: widget.item.id,
                            caption: captionC.text,
                            tags: parsedTags,
                          );

                          if (mounted) {
                            if (response.isSuccess) {
                              setState(() {
                                final rawImage = response.data?['image'];
                                if (rawImage is Map) {
                                  final updatedCap =
                                      rawImage['caption']?.toString() ??
                                      captionC.text;
                                  final List<dynamic>? rawTags =
                                      rawImage['tags'];
                                  final List<String> updatedTags =
                                      rawTags is List
                                      ? rawTags
                                            .where((v) => v != null)
                                            .map((v) => v.toString())
                                            .toList()
                                      : List<String>.from(parsedTags);

                                  _currentCaption = updatedCap;
                                  _currentTags = updatedTags;

                                  // Also sync back to the model object so parent lists are updated
                                  widget.item.caption = updatedCap;
                                  widget.item.tags = updatedTags;
                                } else {
                                  _currentCaption = captionC.text;
                                  _currentTags = List.from(parsedTags);
                                  widget.item.caption = captionC.text;
                                  widget.item.tags = List.from(parsedTags);
                                }
                              });
                              Navigator.pop(context);
                            } else {
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    response.message ?? 'Update failed',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<String> _parseTags(String raw) {
    final result = <String>[];
    final seen = <String>{};

    for (final part in raw.split(',')) {
      final tag = part.trim();
      if (tag.isEmpty) continue;

      final normalized = tag.toLowerCase();
      if (seen.add(normalized)) {
        result.add(tag);
      }
    }
    return result;
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
  final int? initialAlbumId;
  const UploadImageScreen({
    super.key,
    required this.albums,
    this.initialAlbumId,
  });
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

  @override
  void initState() {
    super.initState();
    selectedAlbumId = widget.initialAlbumId;
  }

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
