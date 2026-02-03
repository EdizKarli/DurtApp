import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'day_details_page.dart';
import 'edit_reminder_page.dart'; // Edit sayfasını import etmeyi unutmayın

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

  Map<String, List<dynamic>> _groupedReminders = {}; 

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; 
    _fetchAllReminders(); 
  }

  Future<void> _fetchAllReminders() async {
    final url = Uri.parse('http://localhost:3000/api/reminders'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> allData = json.decode(response.body) ?? []; 
        Map<String, List<dynamic>> tempMap = {};

        for (var item in allData) {
          if (item['reminder_time'] == null) continue;

          try {
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
    String selectedDateKey = DateFormat('yyyy-MM-dd').format(_selectedDay ?? DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('TAKVİM')),
      body: Column(
        children: [
          _calendarFormat == CalendarFormat.week
              ? _buildCustomSplitWeek()
              : _buildStandardTableCalendar(),

          const Divider(),
          
          DailyRemindersWidget(
            reminders: _groupedReminders[selectedDateKey] ?? [],
            // Bu fonksiyonu widget'a veriyoruz ki düzenleyip geri dönünce takvim yenilensin
            onDataChanged: _fetchAllReminders, 
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
        
        // Detay sayfasına giderken bekleme yapıyoruz
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

  // --- GÜN HÜCRESİ ---
  Widget _buildDayCell(DateTime day) {
    final isSelected = isSameDay(day, _selectedDay);
    final isToday = isSameDay(day, DateTime.now());
    
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

                    ...dailyReminders.take(3).map((reminder) {
                      if (reminder == null || reminder is! Map) return const SizedBox();

                      String type = reminder['type'] ?? "";
                      String rawText = reminder['type'] ?? "";

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
    if (type == null) return Icons.notifications; 
    switch (type) {
      case 'Doktor Muayenesi': return Icons.local_hospital;
      case 'İş Görüşmesi': return Icons.work;
      case 'Sınav': return Icons.school;
      case 'Doğum Günü': return Icons.cake;
      case 'Evlilik Yıldönümü': return Icons.volunteer_activism;
      case 'İlişki Yıldönümü': return Icons.favorite;
      case 'Eğlence': return Icons.celebration;
      default: return Icons.notifications; 
    }
  }
}

// ----------------------------------------------------
// DAILY REMINDERS WIDGET (GÜNCELLENMİŞ HALİ)
// ----------------------------------------------------
class DailyRemindersWidget extends StatelessWidget {
  final List<dynamic> reminders; 
  final VoidCallback onDataChanged; // Veri yenileme fonksiyonu eklendi

  const DailyRemindersWidget({
    super.key, 
    required this.reminders, 
    required this.onDataChanged
  });

  static final Map<String, IconData> _typeIcons = {
    "Doğum Günü": Icons.cake,
    "Evlilik Yıldönümü": Icons.volunteer_activism,
    "İlişki Yıldönümü": Icons.favorite,
    "Eğlence": Icons.celebration,
    "Doktor Muayenesi": Icons.medical_services,
    "İş Görüşmesi": Icons.work,
    "Sınav": Icons.school,
    "Özel Dürt": Icons.edit_note,
  };

  Color _getIconColor(String type) {
    switch (type) {
      case "Doğum Günü": return Colors.pink;
      case "Evlilik Yıldönümü": return Colors.red;
      case "İlişki Yıldönümü": return Colors.redAccent;
      case "Eğlence": return Colors.orange;
      case "İş Görüşmesi": return Colors.blue;
      case "Sınav": return Colors.purple;
      case "Doktor Muayenesi": return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            "Bora, bugün için planlanmış bir Dürt yok. 😴",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Text(
            "Bora, bugün için seni Dürtmek istedik:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        Container(
          height: 320, 
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final String type = reminder['type'] ?? "Özel Dürt";
              final String title = reminder['title'] ?? "";
              final String frequency = reminder['frequency'] ?? "";
              
              // GEÇMİŞ KONTROLÜ
              // Dürt saati şu andan önceyse "Geçmiş" kabul edilir -> ReadOnly
              DateTime reminderDate = DateTime.parse(reminder['reminder_time']);
              bool isPast = reminderDate.isBefore(DateTime.now());

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getIconColor(type).withOpacity(0.1),
                    child: Icon(_typeIcons[type] ?? Icons.circle, color: _getIconColor(type)),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("$type • $frequency"),
                  
                  // --- DEĞİŞEN KISIM: İKON VE YÖNLENDİRME ---
                  trailing: IconButton(
                    icon: Icon(
                      isPast ? Icons.visibility : Icons.edit, // Geçmişse GÖZ, Gelecekse KALEM
                      color: Colors.grey
                    ),
                    tooltip: isPast ? "İncele" : "Düzenle",
                    onPressed: () async {
                      // Düzenleme sayfasına git
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditReminderPage(
                            reminder: reminder,
                            isReadOnly: isPast, // Geçmişse sadece okunur
                          ),
                        ),
                      );
                      // Geri dönünce verileri yenile
                      onDataChanged();
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}