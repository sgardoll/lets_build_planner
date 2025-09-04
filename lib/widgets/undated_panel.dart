import 'package:flutter/material.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/widgets/content_card.dart';

class UndatedContentPanel extends StatefulWidget {
  final List<ContentItem> items;
  final List<ContentItem> allItems;
  final Function(ContentItem)? onEditItem;
  final VoidCallback? onAddNew;
  final bool isReadOnly;

  const UndatedContentPanel({
    super.key,
    required this.items,
    required this.allItems,
    this.onEditItem,
    this.onAddNew,
    this.isReadOnly = false,
  });

  @override
  State<UndatedContentPanel> createState() => _UndatedContentPanelState();
}

class _UndatedContentPanelState extends State<UndatedContentPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ContentItem> get _currentItems {
    final items = _selectedIndex == 0 ? widget.items : widget.allItems;
    
    // Filter items based on search query
    List<ContentItem> filteredItems = items;
    if (_searchQuery.isNotEmpty) {
      filteredItems = items.where((item) {
        final title = item.title.toLowerCase();
        final description = item.description.toLowerCase();
        final outline = item.outline.toLowerCase();
        final contentType = item.contentType.displayName.toLowerCase();
        
        return title.contains(_searchQuery) ||
               description.contains(_searchQuery) ||
               outline.contains(_searchQuery) ||
               contentType.contains(_searchQuery);
      }).toList();
    }
    
    // Sort by creation date descending (newest first)
    final sortedItems = List<ContentItem>.from(filteredItems);
    sortedItems.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    return sortedItems;
  }

  Widget _buildItemsList(List<ContentItem> items) {
    if (items.isEmpty) {
      final isSearchActive = _searchQuery.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchActive ? Icons.search_off : 
              (_selectedIndex == 0 ? Icons.event_available : Icons.article_outlined),
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isSearchActive ? 'No matching content found' :
              (_selectedIndex == 0 ? 'No undated content' : 'No content'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            if (isSearchActive)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                },
                child: const Text('Clear search'),
              )
            else if (!widget.isReadOnly && widget.onAddNew != null)
              ElevatedButton.icon(
                onPressed: widget.onAddNew,
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ContentItemCard(
            item: item,
            onTap: widget.onEditItem != null ? () => widget.onEditItem!(item) : null,
            isDraggable: !widget.isReadOnly,
            isReadOnly: widget.isReadOnly,
            showDate: _selectedIndex == 1, // Show date only in "All" tab
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItems = _currentItems;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                // Header row with tabs and new button
                Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        indicatorSize: TabBarIndicatorSize.label,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_available, size: 18),
                                const SizedBox(width: 6),
                                Text('Undated'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.list_alt, size: 18),
                                const SizedBox(width: 6),
                                Text('All'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isReadOnly && widget.onAddNew != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: widget.onAddNew,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search content...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () => _searchController.clear(),
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: 'Clear search',
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildItemsList(currentItems),
          ),
        ],
      ),
    );
  }
}
