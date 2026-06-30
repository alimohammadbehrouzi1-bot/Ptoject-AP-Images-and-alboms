import 'package:flutter/material.dart';

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
  const MainNavigation({super.key});

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
        children: const [
          Center(child: Text('Social Discovery', style: TextStyle(color: Colors.grey))),
          MyStuffsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue[800],
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle_rounded), label: 'My Vault'),
          ],
        ),
      ),
    );
  }
}

class MyStuffsPage extends StatefulWidget {
  const MyStuffsPage({super.key});

  @override
  State<MyStuffsPage> createState() => _MyStuffsPageState();
}

class _MyStuffsPageState extends State<MyStuffsPage> {
  final List<FileItem> _allItems = [
    FileItem(id: 1, name: 'Personal Album', isFolder: true, parentId: null, date: DateTime.now()),
  ];

  FileItem? _currentAlbum;
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  List<FileItem> get _visibleItems {
    if (_searchQuery.isNotEmpty) {
      String query = _searchQuery.toLowerCase();
      if (query.startsWith('#')) {
        String tag = query.substring(1);
        return _allItems.where((item) => !item.isFolder && (item.tags?.any((t) => t.toLowerCase().contains(tag)) ?? false)).toList();
      }
      return _allItems.where((item) {
        bool matchName = item.name.toLowerCase().contains(query);
        bool matchCaption = !item.isFolder && (item.caption?.toLowerCase().contains(query) ?? false);
        bool matchTags = !item.isFolder && (item.tags?.any((t) => t.toLowerCase().contains(query)) ?? false);
        bool matchComments = !item.isFolder && item.comments.any((c) => c.text.toLowerCase().contains(query));
        return matchName || matchCaption || matchTags || matchComments;
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
      _nameController.clear();
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
      comments: [],
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
        if (!item.isFolder) {
          item.parentId = targetAlbumId;
        }
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSelectionMode 
          ? Text('${_selectedIds.length} Selected', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          : (_searchQuery.isEmpty && _currentAlbum != null
              ? Text(_currentAlbum!.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
              : Container(
                  height: 40,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search photos, albums, #tags...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                )),
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
        ] : (_searchQuery.isNotEmpty 
            ? [IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ""; }))] 
            : [
                GestureDetector(
                  onTap: () => _showUserProfile(context),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        const Text('Me', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                          child: const CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.person, size: 18, color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),
                )
              ]),
      ),
      body: Column(
        children: [
          if (!_isSelectionMode && _searchQuery.isEmpty) _buildTopControls(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1,
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

  void _showUserProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 16),
            const Text('Me', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Personal Account', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileDetailScreen(allItems: _allItems)),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('View Profile'),
            ),
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
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => ImageDetailScreen(item: item)));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[100]!, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.isFolder ? Icons.folder_rounded : Icons.image_rounded, 
                    size: 45, 
                    color: item.isFolder ? Colors.blue[300] : Colors.grey[300]
                  ),
                  const SizedBox(height: 10),
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
                ],
              ),
            ),
            if (isSelected) const Positioned(top: 10, right: 10, child: Icon(Icons.check_circle, color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  void _showCreateAlbumDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Name your album'),
      content: TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'e.g. Summer 2024')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { _addAlbum(_nameController.text); Navigator.pop(context); }, child: const Text('Create')),
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
              title: const Text('Main Vault (Root)'),
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
}

class ProfileDetailScreen extends StatefulWidget {
  final List<FileItem> allItems;
  const ProfileDetailScreen({super.key, required this.allItems});

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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
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
      appBar: AppBar(
        title: const Text('Profile Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(_isProfilePicSelected ? Icons.check_circle : Icons.person, size: 60, color: Colors.blue),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: () => setState(() => _isProfilePicSelected = true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Me', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.blue),
              title: const Text('Change Password'),
              onTap: _showChangePasswordDialog,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              tileColor: Colors.grey[100],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Text('Liked Photos (${likedPhotos.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            likedPhotos.isEmpty
                ? const Text('No liked photos yet', style: TextStyle(color: Colors.grey))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
                    ),
                    itemCount: likedPhotos.length,
                    itemBuilder: (context, index) {
                      final item = likedPhotos[index];
                      return Container(
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class ImageDetailScreen extends StatefulWidget {
  final FileItem item;
  const ImageDetailScreen({super.key, required this.item});

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
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(widget.item.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
            onPressed: () => _showEditDialog(context),
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
                    aspectRatio: 1,
                    child: Container(color: Colors.grey[50], child: Icon(Icons.image, size: 80, color: Colors.blue[50])),
                  ),
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

  void _showEditDialog(BuildContext context) {
    final TextEditingController captionC = TextEditingController(text: widget.item.caption);
    final List<String> tempTags = List.from(widget.item.tags ?? []);
    final TextEditingController tagInputC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Photo Info'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: captionC, maxLines: 2, decoration: const InputDecoration(labelText: 'Caption')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: tagInputC, decoration: const InputDecoration(hintText: 'Add Tag'))),
                    IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue), onPressed: () {
                      if (tagInputC.text.isNotEmpty) {
                        setDialogState(() { tempTags.add(tagInputC.text); tagInputC.clear(); });
                      }
                    }),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: tempTags.map((t) => Chip(
                    label: Text('#$t'),
                    onDeleted: () => setDialogState(() => tempTags.remove(t)),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () {
              setState(() {
                widget.item.caption = captionC.text;
                widget.item.tags = List.from(tempTags);
              });
              Navigator.pop(context);
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          IconButton(
            icon: Icon(widget.item.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: widget.item.isLiked ? Colors.redAccent : Colors.black, size: 28),
            onPressed: () => setState(() { widget.item.isLiked = !widget.item.isLiked; widget.item.likes += widget.item.isLiked ? 1 : -1; }),
          ),
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
          if (widget.item.caption != null) 
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(widget.item.caption!, style: const TextStyle(fontSize: 14))),
          Wrap(
            spacing: 8,
            children: (widget.item.tags ?? []).map((t) => Text('#$t', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13))).toList(),
          ),
          const SizedBox(height: 6),
          Text(widget.item.date.toString().substring(0, 10), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          const Divider(height: 30),
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
        return ListTile(
          dense: true,
          leading: const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12)),
          title: Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(comment.text),
          trailing: IconButton(
            icon: Icon(comment.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: comment.isLiked ? Colors.redAccent : Colors.grey[400]),
            onPressed: () => setState(() { comment.isLiked = !comment.isLiked; comment.likes += comment.isLiked ? 1 : -1; }),
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 13)),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_commentController.text.isNotEmpty) {
                setState(() { widget.item.comments.add(CommentData(username: 'Me', text: _commentController.text)); _commentController.clear(); });
              }
            },
            child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();
  final List<String> _tags = [];
  bool _isFileSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('New Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        actions: [
          if (_isFileSelected && _nameController.text.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, {'name': _nameController.text, 'caption': _captionController.text, 'tags': _tags}),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isFileSelected = true),
              child: Container(
                height: 220, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
                child: Icon(_isFileSelected ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, size: 50, color: Colors.blue[100]),
              ),
            ),
            const SizedBox(height: 25),
            TextField(controller: _nameController, onChanged: (v) => setState(() {}), decoration: const InputDecoration(labelText: 'Image Title (Required)', border: UnderlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _captionController, maxLines: 2, decoration: const InputDecoration(labelText: 'Caption (Optional)', border: UnderlineInputBorder())),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: TextField(controller: _tagInputController, decoration: const InputDecoration(hintText: 'Add a tag', border: InputBorder.none))),
                IconButton(icon: const Icon(Icons.add_circle_outline_rounded), onPressed: () {
                  if (_tagInputController.text.isNotEmpty) { setState(() { _tags.add(_tagInputController.text); _tagInputController.clear(); }); }
                }),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: _tags.map((t) => Chip(label: Text('#$t'), onDeleted: () => setState(() => _tags.remove(t)))).toList()),
          ],
        ),
      ),
    );
  }
}
