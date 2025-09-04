import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/widgets/calendar_day.dart';

class CalendarPanel extends StatelessWidget {
  final DateTime currentMonth;
  final Function(DateTime) onMonthChange;
  final Function(ContentItem, DateTime)? onItemScheduled;
  final Function(ContentItem)? onItemUnscheduled;
  final Function(ContentItem)? onEditItem;
  final Function(ContentItem, DateTime, DateTime)? onItemMoved;
  final List<ContentItem> Function(DateTime) getItemsForDate;
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
    this.isReadOnly = false,
  });

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startOfWeek = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final endOfWeek = lastDay.add(Duration(days: 7 - lastDay.weekday));

    final days = <DateTime>[];
    for (DateTime day = startOfWeek;
        day.isBefore(endOfWeek) || day.isAtSameMomentAs(endOfWeek);
        day = day.add(const Duration(days: 1))) {
      days.add(day);
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(currentMonth);
    final monthFormat = DateFormat('MMMM yyyy');
    final numberOfRows = (days.length / 7).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header with navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  final previousMonth = DateTime(
                    currentMonth.year,
                    currentMonth.month - 1,
                  );
                  onMonthChange(previousMonth);
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                monthFormat.format(currentMonth),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () {
                  final nextMonth = DateTime(
                    currentMonth.year,
                    currentMonth.month + 1,
                  );
                  onMonthChange(nextMonth);
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Days of week header
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid that can scroll when needed
          Expanded(
            child: SingleChildScrollView(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling for the grid itself
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                  childAspectRatio: 1.2,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final date = days[index];
                  final isCurrentMonth = date.month == currentMonth.month;
                  final items = getItemsForDate(date);

                  return CalendarDayCell(
                    date: date,
                    isCurrentMonth: isCurrentMonth,
                    items: items,
                    onItemScheduled: onItemScheduled,
                    onItemUnscheduled: onItemUnscheduled,
                    onEditItem: onEditItem,
                    onItemMoved: onItemMoved,
                    isReadOnly: isReadOnly,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
