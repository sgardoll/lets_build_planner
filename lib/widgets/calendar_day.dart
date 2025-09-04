import 'package:flutter/material.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/widgets/content_card.dart';
import 'package:lets_build_planner/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarDayCell extends StatefulWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final List<ContentItem> items;
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
    return widget.date.year == now.year &&
           widget.date.month == now.month &&
           widget.date.day == now.day;
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
          color: _isToday 
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.3),
          width: _isToday ? 2 : 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day number
            Text(
              '${widget.date.day}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: _isToday ? FontWeight.bold : FontWeight.normal,
                color: widget.isCurrentMonth
                    ? (_isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            
            // Content items - use flexible layout to prevent overflow
            Expanded(
              child: widget.items.isEmpty
                  ? const SizedBox()
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          
                          Widget itemWidget = Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(
                              top: index == 0 ? 2 : 1,
                              bottom: index == widget.items.length - 1 ? 0 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.isPrivate && widget.isReadOnly
                                  ? theme.colorScheme.outline.withValues(alpha: 0.3)
                                  : ContentTypeColors.getColor(item.contentType.name, theme.brightness == Brightness.dark).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.isPrivate && widget.isReadOnly ? 'Private' : item.title,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: widget.items.length <= 2 ? 11 : 10,
                                      fontWeight: FontWeight.w500,
                                      color: item.isPrivate && widget.isReadOnly
                                          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                          : (theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
                                    ),
                                    maxLines: widget.items.length <= 2 ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (item.videoLink.isNotEmpty && (!item.isPrivate || !widget.isReadOnly))
                                  GestureDetector(
                                    onTap: () => _launchVideoUrl(item.videoLink),
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      child: Icon(
                                        Icons.play_circle_filled,
                                        size: widget.items.length <= 2 ? 16 : 14,
                                        color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                if (item.isPrivate && widget.isReadOnly)
                                  Icon(
                                    Icons.lock,
                                    size: widget.items.length <= 2 ? 12 : 10,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                              ],
                            ),
                          );

                          // Wrap in draggable if not read-only and not private content
                          if (!widget.isReadOnly && (!item.isPrivate || !widget.isReadOnly)) {
                            itemWidget = Draggable<ContentItem>(
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
                                  child: Text(
                                    item.title,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.5,
                                child: itemWidget,
                              ),
                              child: itemWidget,
                            );
                          }

                          return GestureDetector(
                            onTap: widget.onEditItem != null && !widget.isReadOnly
                                ? () => widget.onEditItem!(item)
                                : null,
                            onLongPress: widget.onItemUnscheduled != null && !widget.isReadOnly
                                ? () => widget.onItemUnscheduled!(item)
                                : null,
                            child: itemWidget,
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    if (widget.isReadOnly || widget.onItemScheduled == null) {
      return child;
    }

    return DragTarget<ContentItem>(
      onWillAcceptWithDetails: (details) => !widget.isReadOnly,
      onAcceptWithDetails: (details) {
        final droppedItem = details.data;
        
        // Check if this item is being moved from another date or scheduled from undated
        if (droppedItem.dateScheduled != null) {
          // Item is being moved from another date
          if (widget.onItemMoved != null) {
            widget.onItemMoved!(droppedItem, droppedItem.dateScheduled!, widget.date);
          }
        } else {
          // Item is being scheduled from undated panel
          if (widget.onItemScheduled != null) {
            widget.onItemScheduled!(droppedItem, widget.date);
          }
        }
        setState(() => _isDragOver = false);
      },
      onMove: (_) => setState(() => _isDragOver = true),
      onLeave: (_) => setState(() => _isDragOver = false),
      builder: (context, candidateData, rejectedData) {
        return child;
      },
    );
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