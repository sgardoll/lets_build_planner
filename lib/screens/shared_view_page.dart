import 'package:flutter/material.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/services/supabase_content_service.dart';
import 'package:lets_build_planner/widgets/undated_panel.dart';
import 'package:lets_build_planner/widgets/calendar_panel.dart';

class SharedViewPage extends StatefulWidget {
  final String userId;
  final String? userName;

  const SharedViewPage({super.key, required this.userId, this.userName});

  @override
  State<SharedViewPage> createState() => _SharedViewPageState();
}

class _SharedViewPageState extends State<SharedViewPage> {
  List<ContentItem> _contentItems = [];
  DateTime _currentMonth = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final items = await SupabaseContentService.getPublicContentItems(widget.userId);
      setState(() {
        _contentItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load shared content: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _changeMonth(DateTime newMonth) => setState(() => _currentMonth = newMonth);

  List<ContentItem> get _undatedItems => _contentItems.where((item) => item.dateScheduled == null).toList();

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<ContentItem> _getItemsForDate(DateTime date) => _contentItems.where((item) {
        final published = item.datePublished;
        final scheduled = item.dateScheduled;
        if (published != null) return _sameDay(published, date);
        if (scheduled != null) return _sameDay(scheduled, date);
        return false;
      }).toList();

  List<ContentItem> _getGhostItemsForDate(DateTime date) => _contentItems.where((item) {
        final published = item.datePublished;
        final scheduled = item.dateScheduled;
        if (published == null || scheduled == null) return false;
        if (_sameDay(published, scheduled)) return false;
        return _sameDay(scheduled, date);
      }).toList();

  List<CalendarLink> _getConnections() => _contentItems
      .where((item) => item.datePublished != null && item.dateScheduled != null && !_sameDay(item.datePublished!, item.dateScheduled!))
      .map((item) => CalendarLink(scheduledDate: item.dateScheduled!, publishedDate: item.datePublished!, item: item))
      .toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/v0-horiz.png', height: 40, fit: BoxFit.contain),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [Container(margin: const EdgeInsets.only(right: 16), child: const Chip(label: Text('View Only'), backgroundColor: Colors.orange, labelStyle: TextStyle(color: Colors.white)))]),
      body: Flex(direction: isMobile ? Axis.vertical : Axis.horizontal, children: [
        if (isMobile)
          Expanded(child: UndatedContentPanel(items: _undatedItems, allItems: _contentItems, isReadOnly: true))
        else
          SizedBox(width: 350, child: UndatedContentPanel(items: _undatedItems, allItems: _contentItems, isReadOnly: true)),
        if (isMobile) const Divider(height: 1) else const VerticalDivider(width: 1),
        Expanded(
          child: CalendarPanel(
            currentMonth: _currentMonth,
            onMonthChange: _changeMonth,
            getItemsForDate: _getItemsForDate,
            getGhostItemsForDate: _getGhostItemsForDate,
            connections: _getConnections(),
            isReadOnly: true,
          ),
        ),
      ]),
    );
  }
}
