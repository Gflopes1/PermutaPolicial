// /lib/features/calendar/widgets/simple_calendar.dart

import 'package:flutter/material.dart';
import '../../../core/models/work_day.dart';

class SimpleCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final WorkDay? Function(DateTime) getWorkDay;
  final bool isMultiSelectMode;
  final Set<DateTime> multiSelectedDays;
  final Function(DateTime)? onDayLongPress;

  const SimpleCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.getWorkDay,
    this.isMultiSelectMode = false,
    this.multiSelectedDays = const {},
    this.onDayLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final startOffset = firstWeekday - 1; // Converte weekday (1-7) para índice do array (0-6)

    return Column(
      children: [
        // Dias da semana
        _buildWeekdays(context),
        // Grid de dias
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: 42, // 6 semanas * 7 dias
            itemBuilder: (context, index) {
              final dayIndex = index - startOffset;
              if (dayIndex < 0 || dayIndex >= daysInMonth) {
                return const SizedBox.shrink(); // Dia vazio
              }

              final day = DateTime(focusedDay.year, focusedDay.month, dayIndex + 1);
              final workDay = getWorkDay(day);
              
              bool isSelected;
              if (isMultiSelectMode) {
                isSelected = multiSelectedDays.any((d) => 
                  d.year == day.year && d.month == day.month && d.day == day.day);
              } else {
                isSelected = day.year == selectedDay.year &&
                    day.month == selectedDay.month &&
                    day.day == selectedDay.day;
              }
              
              final isToday = day.year == DateTime.now().year &&
                  day.month == DateTime.now().month &&
                  day.day == DateTime.now().day;

              return _buildDayCell(context, day, workDay, isSelected, isToday, isMultiSelectMode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdays(BuildContext context) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    WorkDay? workDay,
    bool isSelected,
    bool isToday,
    bool isMultiSelectMode,
  ) {
    Color? backgroundColor;
    if (isSelected) {
      if (isMultiSelectMode) {
        backgroundColor = Theme.of(context).colorScheme.secondary.withAlpha(120);
      } else {
        backgroundColor = Theme.of(context).colorScheme.primary;
      }
    } else if (isToday && !isMultiSelectMode) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
    }

    Color? dayColor;
    if (workDay != null && workDay.presetCor != null) {
      try {
        dayColor = Color(int.parse(workDay.presetCor!.replaceFirst('#', '0xFF')));
      } catch (e) {
        dayColor = Colors.blue;
      }
    }

    return GestureDetector(
      onTap: () => onDaySelected(day),
      onLongPress: onDayLongPress != null ? () => onDayLongPress!(day) : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: dayColor ?? Colors.transparent,
            width: workDay != null ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (workDay != null && workDay.totalHours > 0)
              Text(
                '${workDay.totalHours.toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (workDay != null && workDay.etapas > 0)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${workDay.etapas}E',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


