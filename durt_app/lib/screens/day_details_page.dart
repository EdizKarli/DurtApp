import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'add_reminder_page.dart';
import 'edit_reminder_page.dart';

class DayDetailsPage extends StatefulWidget {
  final DateTime selectedDate;

  const DayDetailsPage({super.key, required this.selectedDate});

  @override
  State<DayDetailsPage> createState() => _DayDetailsPageState();
}

class _DayDetailsPageState extends State<DayDetailsPage> {
  List<dynamic> reminders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  // GEÇMİŞ GÜN KONTROLÜ
  // Seçilen tarih, bugünün gece yarısından (00:00) önceyse "Geçmiş" sayılır.
  bool get _isPastDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Sadece tarihi al, saati at
    return widget.selectedDate.isBefore(today);
  }

  Future<void> _fetchReminders() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final url = Uri.parse('http://localhost:3000/api/reminders?date=$formattedDate');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          reminders = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('d MMMM yyyy', 'tr_TR').format(widget.selectedDate)),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : reminders.isEmpty
              ? _buildEmptyState()
              : _buildReminderList(),
      
      // KURAL 1: Geçmiş günse "Ekleme Butonu" GİZLENSİN
      floatingActionButton: (_isPastDay || reminders.isEmpty) 
          ? null // Buton yok
          : FloatingActionButton.extended(
              onPressed: _navigateToAddPage,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Daha fazla ekleyin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          // Geçmişse farklı mesaj göster
          Text(
            _isPastDay 
              ? "Bu tarihte kaydedilmiş bir dürt yok." 
              : "Bugün için planlanmış bir dürt yok.",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Geçmişse "İlk Dürtünü Ekle" butonu da GİZLENSİN
          if (!_isPastDay)
            ElevatedButton.icon(
              onPressed: _navigateToAddPage,
              icon: const Icon(Icons.add),
              label: const Text("İlk Dürtünü Ekle"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            )
        ],
      ),
    );
  }

  Widget _buildReminderList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: ListTile(
            leading: _getIconForType(reminder['type'] ?? 'Özel'),
            title: Text(
              reminder['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${reminder['type']} • ${reminder['frequency']}"),
            
            // KURAL 2: Geçmişse "İncele", Gelecekse "Düzenle"
            trailing: TextButton.icon(
              onPressed: () => _navigateToEditPage(reminder),
              // İkon ve Yazı duruma göre değişiyor
              icon: Icon(_isPastDay ? Icons.visibility : Icons.edit, size: 16, color: Colors.grey),
              label: Text(_isPastDay ? "İncele" : "Düzenle", style: const TextStyle(color: Colors.grey)),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddReminderPage(initialDate: widget.selectedDate)),
    );
    _fetchReminders();
  }

  void _navigateToEditPage(Map<String, dynamic> reminder) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        // KURAL 3: Edit sayfasına "Sadece Okunabilir" (isReadOnly) bilgisini gönderiyoruz
        builder: (context) => EditReminderPage(
          reminder: reminder, 
          isReadOnly: _isPastDay, // Eğer geçmişse TRUE gider
        ),
      ),
    );
    _fetchReminders();
  }

  Icon _getIconForType(String type) {
    switch (type) {
      case 'Doktor Muayenesi': return const Icon(Icons.local_hospital, color: Colors.red);
      case 'İş Görüşmesi': return const Icon(Icons.work, color: Colors.blue);
      case 'Sınav': return const Icon(Icons.school, color: Colors.orange);
      case 'Doğum Günü': return const Icon(Icons.cake, color: Colors.yellow);
      case 'Evlilik Yıldönümü': return const Icon(Icons.volunteer_activism, color: Colors.pink);
      case 'İlişki Yıldönümü': return const Icon(Icons.favorite, color: Colors.red);
      case 'Eğlence': return const Icon(Icons.celebration, color: Colors.green);
      default: return const Icon(Icons.notifications, color: Colors.grey);
    }
  }
}