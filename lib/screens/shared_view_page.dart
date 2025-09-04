import 'package:flutter/material.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/services/supabase_content_service.dart';
import 'package:lets_build_planner/widgets/undated_panel.dart';
import 'package:lets_build_planner/widgets/calendar_panel.dart';

class SharedViewPage extends StatefulWidget {
  final String userId;
  final String? userName;

  const SharedViewPage({
    super.key,
    required this.userId,
    this.userName,
  });

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load shared content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/v0-horiz.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const Chip(
              label: Text('View Only'),
              backgroundColor: Colors.orange,
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        children: [
          if (isMobile)
            Expanded(
              child: UndatedContentPanel(
                items: _undatedItems,
                allItems: _contentItems,
                isReadOnly: true, // This will hide add/edit buttons
              ),
            )
          else
            // Fixed width for undated panel in tablet/desktop to give calendar more space
            SizedBox(
              width: 350,
              child: UndatedContentPanel(
                items: _undatedItems,
                allItems: _contentItems,
                isReadOnly: true, // This will hide add/edit buttons
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
              getItemsForDate: _getItemsForDate,
              isReadOnly: true, // This will hide add/edit buttons
            ),
          ),
        ],
      ),
    );
  }
}