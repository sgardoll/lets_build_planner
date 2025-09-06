import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/widgets/calendar_day.dart';
import 'package:lets_build_planner/theme.dart';

class CalendarLink {
  final DateTime scheduledDate;
  final DateTime publishedDate;
  final ContentItem item;
  CalendarLink({required this.scheduledDate, required this.publishedDate, required this.item});
}

class CalendarPanel extends StatefulWidget {
  final DateTime currentMonth;
  final Function(DateTime) onMonthChange;
  final Function(ContentItem, DateTime)? onItemScheduled;
  final Function(ContentItem)? onItemUnscheduled;
  final Function(ContentItem)? onEditItem;
  final Function(ContentItem, DateTime, DateTime)? onItemMoved;
  final List<ContentItem> Function(DateTime) getItemsForDate; // Primary items by published date, or scheduled if no published
  final List<ContentItem> Function(DateTime)? getGhostItemsForDate; // Ghost items for scheduled date when published differs
  final List<CalendarLink> connections; // Links to draw between scheduled and published
  final bool isReadOnly;

  const CalendarPanel({
    super.key,
    required this.currentMonth,
    required this.onMonthChange,
    this.onItemScheduled,
    this.onItemUnscheduled,
    this.onEditItem,
    this.onItemMoved,
    required this.getItemsForDate,
    this.getGhostItemsForDate,
    this.connections = const [],
    this.isReadOnly = false,
  });

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  final Map<String, GlobalKey> _cellKeys = {};
  final GlobalKey _stackKey = GlobalKey();
  List<_LineSegment> _segments = [];

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startOfWeek = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final endOfWeek = lastDay.add(Duration(days: 7 - lastDay.weekday));

    final days = <DateTime>[];
    for (DateTime day = startOfWeek; day.isBefore(endOfWeek) || day.isAtSameMomentAs(endOfWeek); day = day.add(const Duration(days: 1))) {
      days.add(day);
    }
    return days;
  }

  String _dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void didUpdateWidget(covariant CalendarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _computeSegments());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _computeSegments());
  }

  void _computeSegments() {
    final List<_LineSegment> computed = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stackContext = _stackKey.currentContext;
    if (stackContext == null) return;
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    if (stackBox == null) return;

    for (final link in widget.connections) {
      final fromKey = _cellKeys[_dateKey(link.scheduledDate)];
      final toKey = _cellKeys[_dateKey(link.publishedDate)];
      if (fromKey?.currentContext == null || toKey?.currentContext == null) continue;
      final fromBox = fromKey!.currentContext!.findRenderObject() as RenderBox?;
      final toBox = toKey!.currentContext!.findRenderObject() as RenderBox?;
      if (fromBox == null || toBox == null) continue;
      final fromCenterGlobal = fromBox.localToGlobal(Offset(fromBox.size.width / 2, fromBox.size.height / 2));
      final toCenterGlobal = toBox.localToGlobal(Offset(toBox.size.width / 2, toBox.size.height / 2));
      final from = stackBox.globalToLocal(fromCenterGlobal);
      final to = stackBox.globalToLocal(toCenterGlobal);
      final baseColor = ContentTypeColors.getColor(link.item.contentType.name, isDark);
      final strokeColor = baseColor.withValues(alpha: 0.55);
      computed.add(_LineSegment(from: from, to: to, color: strokeColor));
    }

    if (mounted) setState(() => _segments = computed);
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(widget.currentMonth);
    final monthFormat = DateFormat('MMMM yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            onPressed: () {
              final previousMonth = DateTime(widget.currentMonth.year, widget.currentMonth.month - 1);
              widget.onMonthChange(previousMonth);
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Text(monthFormat.format(widget.currentMonth), style: Theme.of(context).textTheme.headlineSmall),
          IconButton(
            onPressed: () {
              final nextMonth = DateTime(widget.currentMonth.year, widget.currentMonth.month + 1);
              widget.onMonthChange(nextMonth);
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
        const SizedBox(height: 16),
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(day, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              key: _stackKey,
              child: Stack(children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 1, mainAxisSpacing: 1, childAspectRatio: 1.2),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final date = days[index];
                    final isCurrentMonth = date.month == widget.currentMonth.month;
                    final items = widget.getItemsForDate(date);
                    final ghosts = widget.getGhostItemsForDate?.call(date) ?? const <ContentItem>[];
                    final key = _cellKeys.putIfAbsent(_dateKey(date), () => GlobalKey());
                    return Container(
                      key: key,
                      child: CalendarDayCell(
                        date: date,
                        isCurrentMonth: isCurrentMonth,
                        items: items,
                        ghostItems: ghosts,
                        onItemScheduled: widget.onItemScheduled,
                        onItemUnscheduled: widget.onItemUnscheduled,
                        onEditItem: widget.onEditItem,
                        onItemMoved: widget.onItemMoved,
                        isReadOnly: widget.isReadOnly,
                      ),
                    );
                  },
                ),
                Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ConnectionsPainter(_segments))))
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LineSegment {
  final Offset from;
  final Offset to;
  final Color color;
  _LineSegment({required this.from, required this.to, required this.color});
}

class _ConnectionsPainter extends CustomPainter {
  final List<_LineSegment> segments;
  _ConnectionsPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()..moveTo(seg.from.dx, seg.from.dy)..lineTo(seg.to.dx, seg.to.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionsPainter oldDelegate) => oldDelegate.segments != segments;
}
