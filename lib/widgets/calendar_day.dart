import 'package:flutter/material.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarDayCell extends StatefulWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final List<ContentItem> items; // Primary items for this date (published or scheduled-only)
  final List<ContentItem> ghostItems; // Lighter duplicates for scheduled date when published differs
  final Function(ContentItem, DateTime)? onItemScheduled;
  final Function(ContentItem)? onItemUnscheduled;
  final Function(ContentItem)? onEditItem;
  final Function(ContentItem, DateTime, DateTime)? onItemMoved;
  final bool isReadOnly;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.items,
    this.ghostItems = const [],
    this.onItemScheduled,
    this.onItemUnscheduled,
    this.onEditItem,
    this.onItemMoved,
    this.isReadOnly = false,
  });

  @override
  State<CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends State<CalendarDayCell> {
  bool _isDragOver = false;

  bool get _isToday {
    final now = DateTime.now();
    return widget.date.year == now.year && widget.date.month == now.month && widget.date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child = Container(
      decoration: BoxDecoration(
        color: _isDragOver
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : widget.isCurrentMonth
                ? theme.colorScheme.surface
                : theme.colorScheme.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: _isToday ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.3),
          width: _isToday ? 2 : 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.date.day}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: _isToday ? FontWeight.bold : FontWeight.normal,
                color: widget.isCurrentMonth ? (_isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface) : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              )),
          Expanded(
            child: (widget.items.isEmpty && widget.ghostItems.isEmpty)
                ? const SizedBox()
                : SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ..._buildPrimaryItems(context),
                      ..._buildGhostItems(context),
                    ]),
                  ),
          ),
        ]),
      ),
    );

    if (widget.isReadOnly || widget.onItemScheduled == null) return child;

    return DragTarget<ContentItem>(
      onWillAcceptWithDetails: (details) => !widget.isReadOnly,
      onAcceptWithDetails: (details) {
        final droppedItem = details.data;
        if (droppedItem.dateScheduled != null) {
          if (widget.onItemMoved != null) widget.onItemMoved!(droppedItem, droppedItem.dateScheduled!, widget.date);
        } else {
          if (widget.onItemScheduled != null) widget.onItemScheduled!(droppedItem, widget.date);
        }
        setState(() => _isDragOver = false);
      },
      onMove: (_) => setState(() => _isDragOver = true),
      onLeave: (_) => setState(() => _isDragOver = false),
      builder: (context, candidateData, rejectedData) => child,
    );
  }

  List<Widget> _buildPrimaryItems(BuildContext context) {
    final theme = Theme.of(context);
    return widget.items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      Widget itemChip = _CalendarItemChip(
        item: item,
        backgroundColor: item.isPrivate && widget.isReadOnly
            ? theme.colorScheme.outline.withValues(alpha: 0.3)
            : ContentTypeColors.getColor(item.contentType.name, theme.brightness == Brightness.dark).withValues(alpha: 0.8),
        textColor: item.isPrivate && widget.isReadOnly
            ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
            : (theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
        showVideoIcon: item.videoLink.isNotEmpty && (!item.isPrivate || !widget.isReadOnly),
        isCompact: widget.items.length <= 2,
        marginTop: index == 0 ? 2 : 1,
        marginBottom: index == widget.items.length - 1 && widget.ghostItems.isEmpty ? 0 : 1,
        onTap: widget.onEditItem != null && !widget.isReadOnly ? () => widget.onEditItem!(item) : null,
        onLongPress: widget.onItemUnscheduled != null && !widget.isReadOnly ? () => widget.onItemUnscheduled!(item) : null,
        onVideoTap: item.videoLink.isNotEmpty && (!item.isPrivate || !widget.isReadOnly) ? () => _launchVideoUrl(item.videoLink) : null,
        isPrivate: item.isPrivate && widget.isReadOnly,
        showLock: item.isPrivate && widget.isReadOnly,
      );
      if (!widget.isReadOnly && (!item.isPrivate || !widget.isReadOnly)) {
        itemChip = Draggable<ContentItem>(
          data: item,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            elevation: 6.0,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ContentTypeColors.getColor(item.contentType.name, theme.brightness == Brightness.dark),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(item.title,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.5, child: itemChip),
          child: itemChip,
        );
      }
    return itemChip;
    }).toList();
  }

  List<Widget> _buildGhostItems(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.ghostItems.isEmpty) return const [];
    return widget.ghostItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return _CalendarItemChip(
        item: item,
        backgroundColor: ContentTypeColors.getColor(item.contentType.name, theme.brightness == Brightness.dark).withValues(alpha: 0.25),
        textColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        showVideoIcon: false,
        isCompact: (widget.items.length + widget.ghostItems.length) <= 2,
        marginTop: widget.items.isEmpty && index == 0 ? 2 : 1,
        marginBottom: index == widget.ghostItems.length - 1 ? 0 : 1,
        onTap: widget.onEditItem != null && !widget.isReadOnly ? () => widget.onEditItem!(item) : null,
        onLongPress: null,
        onVideoTap: null,
        isPrivate: item.isPrivate && widget.isReadOnly,
        showLock: item.isPrivate && widget.isReadOnly,
        ghostLabel: 'Scheduled',
      );
    }).toList();
  }

  Future<void> _launchVideoUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}

class _CalendarItemChip extends StatelessWidget {
  final ContentItem item;
  final Color backgroundColor;
  final Color textColor;
  final bool showVideoIcon;
  final bool isCompact;
  final double marginTop;
  final double marginBottom;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onVideoTap;
  final bool isPrivate;
  final bool showLock;
  final String? ghostLabel;

  const _CalendarItemChip({
    required this.item,
    required this.backgroundColor,
    required this.textColor,
    required this.showVideoIcon,
    required this.isCompact,
    required this.marginTop,
    required this.marginBottom,
    this.onTap,
    this.onLongPress,
    this.onVideoTap,
    this.isPrivate = false,
    this.showLock = false,
    this.ghostLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isPrivate ? 'Private' : item.title;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: marginTop, bottom: marginBottom),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          Expanded(
            child: Text(ghostLabel != null ? '$title • $ghostLabel' : title,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: isCompact ? 11 : 10, fontWeight: FontWeight.w500, color: textColor, fontStyle: ghostLabel != null ? FontStyle.italic : FontStyle.normal),
                maxLines: isCompact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
          ),
          if (showVideoIcon)
            GestureDetector(
              onTap: onVideoTap,
              child: Container(
                padding: const EdgeInsets.all(1),
                child: Icon(Icons.play_circle_filled, size: isCompact ? 16 : 14, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
              ),
            ),
          if (showLock)
            Icon(Icons.lock, size: isCompact ? 12 : 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}
