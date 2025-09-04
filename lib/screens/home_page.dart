import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/services/supabase_content_service.dart';
import 'package:lets_build_planner/widgets/undated_panel.dart';
import 'package:lets_build_planner/widgets/calendar_panel.dart';
import 'package:lets_build_planner/widgets/content_dialog.dart';
// Removed full-screen LoadingScreen to avoid duplicate splash; using in-page loader
import 'package:lets_build_planner/supabase/supabase_config.dart';
import 'package:lets_build_planner/screens/auth_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ContentItem> _contentItems = [];
  DateTime _currentMonth = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    try {
      SupabaseAuth.authStateChanges.listen((AuthState state) {
        if (mounted) {
          setState(() {
            // Refresh UI when auth state changes
          });
          _loadContent(); // Reload content when auth state changes
        }
      });
    } catch (e) {
      debugPrint('Error setting up auth listener in HomePage: $e');
      // Continue without auth state monitoring if it fails
    }
  }

  Future<void> _loadContent() async {
    try {
      List<ContentItem> items;
      if (SupabaseAuth.isAuthenticated) {
        // Load user's content (including private)
        items = await SupabaseContentService.getAllContentItems();
      } else {
        // Load all public content across users (non-private)
        items = [];
      }
      setState(() {
        _contentItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading content: $e');
      setState(() => _isLoading = false);
    }
  }

  // No longer need manual saving since we're using real-time database operations

  Future<void> _scheduleContent(ContentItem item, DateTime date) async {
    try {
      final updatedItem =
          await SupabaseContentService.scheduleContentItem(item.id, date);
      setState(() {
        final index = _contentItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _contentItems[index] = updatedItem;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling content: $e')),
      );
    }
  }

  Future<void> _unscheduleContent(ContentItem item) async {
    try {
      final updatedItem =
          await SupabaseContentService.unscheduleContentItem(item.id);
      setState(() {
        final index = _contentItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _contentItems[index] = updatedItem;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unscheduling content: $e')),
      );
    }
  }

  Future<void> _moveContent(
      ContentItem item, DateTime fromDate, DateTime toDate) async {
    try {
      final updatedItem =
          await SupabaseContentService.scheduleContentItem(item.id, toDate);
      setState(() {
        final index = _contentItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _contentItems[index] = updatedItem;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving content: $e')),
      );
    }
  }

  Future<void> _updateContent(ContentItem updatedItem) async {
    try {
      final savedItem =
          await SupabaseContentService.updateContentItem(updatedItem);
      setState(() {
        final index = _contentItems.indexWhere((i) => i.id == updatedItem.id);
        if (index != -1) {
          _contentItems[index] = savedItem;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating content: $e')),
      );
    }
  }

  Future<void> _deleteContent(ContentItem itemToDelete) async {
    try {
      await SupabaseContentService.deleteContentItem(itemToDelete.id);
      setState(() {
        _contentItems.removeWhere((item) => item.id == itemToDelete.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting content: $e')),
      );
    }
  }

  void _addNewContent() {
    final newItem = ContentItem(
      id: '', // Will be set by SupabaseContentService
      userId: SupabaseAuth.currentUser?.id,
      title: 'New Content Item',
    );
    _editContent(newItem);
  }

  void _editContent(ContentItem item, {bool isReadOnly = false}) {
    showDialog(
      context: context,
      builder: (context) => ContentEditDialog(
        item: item,
        onSave: (updatedItem) async {
          if (item.id.isEmpty) {
            // This is a new item, create it
            try {
              final createdItem =
                  await SupabaseContentService.createContentItem(
                title: updatedItem.title,
                description: updatedItem.description,
                url: updatedItem.url,
                attachments: updatedItem.attachments,
                dateScheduled: updatedItem.dateScheduled,
                datePublished: updatedItem.datePublished,
                videoLink: updatedItem.videoLink,
                isPrivate: updatedItem.isPrivate,
                contentType: updatedItem.contentType,
                outline: updatedItem.outline,
              );
              setState(() {
                _contentItems.add(createdItem);
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error creating content: $e')),
              );
            }
          } else {
            // This is an existing item, update it
            await _updateContent(updatedItem);
          }
        },
        onDelete: item.id.isEmpty ? null : _deleteContent,
        isReadOnly: isReadOnly,
      ),
    );
  }

  void _changeMonth(DateTime newMonth) {
    setState(() {
      _currentMonth = newMonth;
    });
  }

  List<ContentItem> get _undatedItems =>
      _contentItems.where((item) => item.dateScheduled == null).toList();

  List<ContentItem> _getItemsForDate(DateTime date) => _contentItems
      .where((item) =>
          item.dateScheduled != null &&
          item.dateScheduled!.year == date.year &&
          item.dateScheduled!.month == date.month &&
          item.dateScheduled!.day == date.day)
      .toList();

  Future<void> _signOut() async {
    try {
      await SupabaseAuth.signOut();
      if (mounted) {
        setState(() {
          // Refresh the UI to show read-only mode
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sign In to Edit',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const AuthPage(isDialog: true),
            ],
          ),
        ),
      ),
    );
  }

  void _shareCalendar() {
    final currentUserId = SupabaseAuth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to share your calendar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Use the current app's base URL for sharing
    final currentUrl = Uri.base;
    final shareUrl = '${currentUrl.origin}/shared/$currentUserId';
    Clipboard.setData(ClipboardData(text: shareUrl));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share link copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = SupabaseAuth.isAuthenticated;
    final userEmail = SupabaseAuth.currentUser?.email;
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Image.network(
            'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/open-router-library-ry2ta7/assets/1vva4juqfxr3/v0-vert.png',
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const SizedBox(height: 40),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          actions: [
            if (isAuthenticated) ...[
              IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareCalendar,
                  tooltip: 'Share Calendar'),
              PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Signed in as: $userEmail')));
                        break;
                      case 'logout':
                        _signOut();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(children: [
                              const Icon(Icons.person),
                              const SizedBox(width: 8),
                              Text(userEmail ?? 'User')
                            ])),
                        const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(children: [
                              Icon(Icons.logout),
                              SizedBox(width: 8),
                              Text('Sign Out')
                            ]))
                      ])
            ] else ...[
              TextButton(
                  onPressed: _showAuthDialog, child: const Text('Sign In'))
            ]
          ],
          title: Image.network(
              'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/open-router-library-ry2ta7/assets/1vva4juqfxr3/v0-vert.png',
              height: 40,
              fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) {
            return Container(height: 40, alignment: Alignment.center);
          }),
          automaticallyImplyLeading: false),
      body: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        children: [
          if (isMobile)
            Expanded(
              child: UndatedContentPanel(
                items: _undatedItems,
                allItems: _contentItems,
                onEditItem: isAuthenticated
                    ? _editContent
                    : (item) => _editContent(item, isReadOnly: true),
                onAddNew: isAuthenticated ? _addNewContent : null,
                isReadOnly: !isAuthenticated,
              ),
            )
          else
            // Fixed width for undated panel in tablet/desktop to give calendar more space
            SizedBox(
              width: 350,
              child: UndatedContentPanel(
                items: _undatedItems,
                allItems: _contentItems,
                onEditItem: isAuthenticated
                    ? _editContent
                    : (item) => _editContent(item, isReadOnly: true),
                onAddNew: isAuthenticated ? _addNewContent : null,
                isReadOnly: !isAuthenticated,
              ),
            ),
          if (isMobile)
            const Divider(height: 1)
          else
            const VerticalDivider(width: 1),
          Expanded(
            child: CalendarPanel(
              currentMonth: _currentMonth,
              onMonthChange: _changeMonth,
              onItemScheduled: isAuthenticated ? _scheduleContent : null,
              onItemUnscheduled: isAuthenticated ? _unscheduleContent : null,
              onEditItem: isAuthenticated
                  ? _editContent
                  : (item) => _editContent(item, isReadOnly: true),
              onItemMoved: isAuthenticated ? _moveContent : null,
              getItemsForDate: _getItemsForDate,
              isReadOnly: !isAuthenticated,
            ),
          ),
        ],
      ),
    );
  }
}
