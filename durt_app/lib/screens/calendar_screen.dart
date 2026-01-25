import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Tarih formatı için gerekli

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  
  // Renkler
  final Color darkRed = const Color.fromARGB(255, 200, 13, 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TAKVİM')),
      body: Column(
        children: [
          // GÖRÜNÜM SEÇİCİ
          // Eğer Haftalıktaysa: Özel "Bölünmüş" Görünüm (4+3)
          // Eğer Aylıktaysa: Standart Yuvarlak Takvim
          _calendarFormat == CalendarFormat.week
              ? _buildCustomSplitWeek()
              : _buildStandardTableCalendar(),

          const Divider(),
          
          // ALT BİLGİ ALANI
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

  // --- BÖLÜM 1: AYLIK GÖRÜNÜM (STANDART KIRMIZI YUVARLAKLAR) ---
  Widget _buildStandardTableCalendar() {
    return TableCalendar(
      locale: 'tr_TR',
      startingDayOfWeek: StartingDayOfWeek.monday,
      firstDay: DateTime.utc(2026, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      
      // Sadece format değiştirmek için 'Haftalık' seçeneğini burada tutuyoruz
      availableCalendarFormats: const {
        CalendarFormat.month: 'Aylık',
        CalendarFormat.week: 'Haftalık',
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },

      // --- BURASI DEĞİŞTİ: Kare Builder'lar kaldırıldı, Stil eklendi ---
      calendarStyle: CalendarStyle(
        // Bugün: Koyu Kırmızı Yuvarlak
        todayDecoration: BoxDecoration(
          color: darkRed,
          shape: BoxShape.circle, 
        ),
        // Seçili Gün: Parlak Kırmızı Yuvarlak
        selectedDecoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        // Yazı Renkleri
        todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),

      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );
  }

  // --- BÖLÜM 2: HAFTALIK ÖZEL GÖRÜNÜM (4+3 & SOL ÜSTTE TARİH) ---
  Widget _buildCustomSplitWeek() {
    // Haftanın günlerini hesapla
    final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Column(
      children: [
        // Özel Başlık (Sol Üstte Tarih, Sağda Buton)
        _buildCustomHeader(startOfWeek),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              // 1. Satır: Pazartesi - Perşembe (4 Gün)
              Row(
                children: weekDays.sublist(0, 4).map((day) => Expanded(child: _buildDayCell(day))).toList(),
              ),
              const SizedBox(height: 8), // Satır boşluğu
              // 2. Satır: Cuma - Pazar (3 Gün)
              Row(
                children: [
                  ...weekDays.sublist(4, 7).map((day) => Expanded(child: _buildDayCell(day))),
                  const Expanded(child: SizedBox()), // Hizalamak için boşluk
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- YENİ BAŞLIK TASARIMI ---
  Widget _buildCustomHeader(DateTime startOfWeek) {
    // Tarih aralığını formatla (Örn: "19 Ocak - 25 Ocak 2026")
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    // intl paketi sayesinde Türkçe ay isimleri gelir
    final dateRangeText = '${DateFormat('d MMMM', 'tr_TR').format(startOfWeek)} - ${DateFormat('d MMMM y', 'tr_TR').format(endOfWeek)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // SOL TARAF: Tarih Bilgisi ve Oklar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateRangeText, // "19 Ocak - 25 Ocak 2026"
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

          // SAĞ TARAF: Aylık Görünüm Butonu
          InkWell(
            onTap: () => setState(() => _calendarFormat = CalendarFormat.month),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: const Text(
                "Aylık",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gün Hücresi (Haftalık Görünüm İçin - KARE KALIYOR)
  Widget _buildDayCell(DateTime day) {
    final isSelected = isSameDay(day, _selectedDay);
    final isToday = isSameDay(day, DateTime.now());
    
    Color borderColor = isToday ? darkRed : (isSelected ? Colors.red : Colors.grey.shade300);
    Color headerColor = isToday ? darkRed : (isSelected ? Colors.red : Colors.grey.shade200);
    Color textColor = (isSelected || isToday) ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
          _focusedDay = day;
        });
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
                alignment: Alignment.center,
                child: isToday || isSelected 
                  ? Icon(Icons.touch_app, size: 16, color: headerColor) 
                  : null, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}