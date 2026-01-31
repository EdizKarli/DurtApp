import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'day_details_page.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  
  final Color darkRed = const Color.fromARGB(255, 200, 13, 0);

  // GÜVENLİK 1: Başlangıçta boş bir Map ile başlatıyoruz ki null hatası almayalım.
  Map<String, List<dynamic>> _groupedReminders = {}; 

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Başlangıçta seçili günü ayarla
    _fetchAllReminders(); 
  }

  // --- GÜVENLİ VERİ ÇEKME ---
  Future<void> _fetchAllReminders() async {
    final url = Uri.parse('http://localhost:3000/api/reminders'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Gelen veriyi güvenli bir şekilde listeye çeviriyoruz
        List<dynamic> allData = json.decode(response.body) ?? []; 
        Map<String, List<dynamic>> tempMap = {};

        for (var item in allData) {
          if (item['reminder_time'] == null) continue; // Tarih yoksa atla

          try {
            // Tarihi güvenli parse et
            DateTime parsedDate = DateTime.parse(item['reminder_time']);
            String dateKey = DateFormat('yyyy-MM-dd').format(parsedDate);
            
            if (!tempMap.containsKey(dateKey)) {
              tempMap[dateKey] = [];
            }
            tempMap[dateKey]!.add(item);
          } catch (e) {
            print("Tarih Parse Hatası: $e");
          }
        }

        if (mounted) {
          setState(() {
            _groupedReminders = tempMap;
          });
        }
      }
    } catch (e) {
      print("Takvim Veri Hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TAKVİM')),
      body: Column(
        children: [
          _calendarFormat == CalendarFormat.week
              ? _buildCustomSplitWeek()
              : _buildStandardTableCalendar(),

          const Divider(),
          
          Expanded(
            child: Center(
              child: Text(
                _selectedDay == null 
                  ? "Dürtmenizi ayarlamak için tarih seçiniz." 
                  : "${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year} seçildi.",
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- AYLIK GÖRÜNÜM ---
  Widget _buildStandardTableCalendar() {
    return TableCalendar(
      locale: 'tr_TR',
      startingDayOfWeek: StartingDayOfWeek.monday,
      firstDay: DateTime.utc(2026, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      
      availableCalendarFormats: const {
        CalendarFormat.month: 'Aylık',
        CalendarFormat.week: 'Haftalık',
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },

      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(color: darkRed, shape: BoxShape.circle),
        selectedDecoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),

      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) async {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DayDetailsPage(selectedDate: selectedDay)),
        );
        _fetchAllReminders();
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );
  }

  // --- HAFTALIK ÖZEL GÖRÜNÜM ---
  Widget _buildCustomSplitWeek() {
    final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Column(
      children: [
        _buildCustomHeader(startOfWeek),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              Row(
                children: weekDays.sublist(0, 4).map((day) => Expanded(child: _buildDayCell(day))).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...weekDays.sublist(4, 7).map((day) => Expanded(child: _buildDayCell(day))),
                  const Expanded(child: SizedBox()), 
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomHeader(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final dateRangeText = '${DateFormat('d MMMM', 'tr_TR').format(startOfWeek)} - ${DateFormat('d MMMM y', 'tr_TR').format(endOfWeek)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateRangeText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.chevron_left, color: Colors.red),
                    onPressed: () => setState(() {
                      _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                    }),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.chevron_right, color: Colors.red),
                    onPressed: () => setState(() {
                      _focusedDay = _focusedDay.add(const Duration(days: 7));
                    }),
                  ),
                ],
              )
            ],
          ),
          InkWell(
            onTap: () => setState(() => _calendarFormat = CalendarFormat.month),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: const Text("Aylık", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- GÜVENLİ GÜN HÜCRESİ ---
  Widget _buildDayCell(DateTime day) {
    final isSelected = isSameDay(day, _selectedDay);
    final isToday = isSameDay(day, DateTime.now());
    
    // GÜVENLİK 2: Veri çekerken null kontrolü
    // Eğer Map null ise veya o tarihte veri yoksa boş liste ata
    String dateKey = DateFormat('yyyy-MM-dd').format(day);
    List<dynamic> dailyReminders = _groupedReminders[dateKey] ?? [];

    Color borderColor = isToday ? darkRed : (isSelected ? Colors.red : Colors.grey.shade300);
    Color headerColor = isToday ? darkRed : (isSelected ? Colors.red : Colors.grey.shade200);
    Color textColor = (isSelected || isToday) ? Colors.white : Colors.black;
    
    String dayName = DateFormat('EEEE', 'tr_TR').format(day);

    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedDay = day;
          _focusedDay = day;
        });

        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DayDetailsPage(selectedDate: day)),
        );
        _fetchAllReminders(); 
      },
      child: Container(
        height: 140, 
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${day.day}',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      dayName, 
                      style: TextStyle(
                        color: isToday ? darkRed : Colors.grey.shade700,
                        fontSize: 10, 
                        fontWeight: FontWeight.w500
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // --- GÜVENLİ LİSTELEME ---
                    ...dailyReminders.take(3).map((reminder) {
                      // GÜVENLİK 3: Her bir öğenin null olup olmadığını kontrol et
                      if (reminder == null || reminder is! Map) return const SizedBox();

                      //List<String> standardTypes = ["Doktor Muayenesi", "İş Görüşmesi", "Sınav"];
                      String type = reminder['type'] ?? "";
                      //String title = reminder['title'] ?? "";
                      
                      String rawText = reminder['type'] ?? "";

                      // 6 HARF SINIRI
                      String displayText = rawText.length > 6 
                          ? "${rawText.substring(0, 6)}..." 
                          : rawText;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Row(
                          children: [
                            Icon(_getIconData(type), size: 12, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              displayText,
                              style: const TextStyle(fontSize: 10, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    if (dailyReminders.length > 3)
                      const Icon(Icons.more_horiz, size: 12, color: Colors.grey)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String? type) {
    if (type == null) return Icons.notifications; // Null gelirse varsayılan ikon
    switch (type) {
      case 'Doktor Muayenesi': return Icons.local_hospital;
      case 'İş Görüşmesi': return Icons.work;
      case 'Sınav': return Icons.school;
      default: return Icons.notifications; 
    }
  }
}