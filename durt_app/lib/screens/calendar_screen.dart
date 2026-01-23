import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TAKVİM')),
      body: Column(
        children: [
          TableCalendar(
            locale: 'tr_TR',
            startingDayOfWeek: StartingDayOfWeek.monday,
            rowHeight: 100.0,
            firstDay: DateTime.utc(2026, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            calendarBuilders: CalendarBuilders(
              // This builder handles the day you have clicked on
              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2), // Red border for the whole box
                  ),
                  child: Column(
                    children: [
                      // PART 1: The Header (Colored)
                      Container(
                        width: double.infinity, // Stretches color to full width
                        color: Colors.red,      // The red background you wanted
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // PART 2: The Body (White space for writing)
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.white, // Kept white so you can "write" here later
                          alignment: Alignment.bottomCenter,
                          child: const Text("Seçili", style: TextStyle(fontSize: 10, color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                );
              },

              // This builder handles the "Today" marker
              todayBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color.fromARGB(255, 200, 13, 0)),
                  ),
                  child: Column(
                    children: [
                      // Colored Header for Today
                      Container(
                        width: double.infinity,
                        color: const Color.fromARGB(255, 200, 13, 0),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // White Body for Today
                      Expanded(child: Container(color: Colors.white)),
                    ],
                  ),
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, 
              titleCentered: true,      
              titleTextStyle: TextStyle(color: Colors.red, fontSize: 18), // Red Month Name
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.red),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.red),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.black),
              weekendStyle: TextStyle(color: Colors.red), 
            ),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Color.fromARGB(255, 200, 13, 0), 
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.red),
              todayTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              selectedTextStyle: TextStyle(color: Colors.white),
            ),
            
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; 
              });
              // This is where you will eventually call your Node.js API
              // to filter reminders for this specific day.
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const Expanded(
            child: Center(
              child: Text("Dürtmenizi ayarlamak için tarih seçiniz."),
            ),
          ),
        ],
      ),
    );
  }
}