import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Backend için gerekli
import 'dart:convert'; // JSON çevirmek için gerekli
import 'package:intl/intl.dart'; // Tarih formatı için
import 'add_reminder_page.dart';
import 'edit_reminder_page.dart'; // YENİ: Düzenleme sayfasını içeri aktarıyoruz

class DayDetailsPage extends StatefulWidget {
  final DateTime selectedDate;

  const DayDetailsPage({super.key, required this.selectedDate});

  @override
  State<DayDetailsPage> createState() => _DayDetailsPageState();
}

class _DayDetailsPageState extends State<DayDetailsPage> {
  List<dynamic> reminders = []; // Veritabanından gelecek liste
  bool isLoading = true; // Yükleniyor mu?

  @override
  void initState() {
    super.initState();
    _fetchReminders(); // Sayfa açılınca verileri çek
  }

  // Backend'den Veri Çeken Fonksiyon
  Future<void> _fetchReminders() async {
    // Tarihi YYYY-MM-DD formatına çevir (Backend böyle bekliyor)
    String formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final url = Uri.parse('http://localhost:3000/api/reminders?date=$formattedDate');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          reminders = json.decode(response.body); // Gelen JSON'ı listeye at
          isLoading = false;
        });
      } else {
        print("Hata: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
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
          ? const Center(child: CircularProgressIndicator(color: Colors.red)) // Yüklenirken dönen halka
          : reminders.isEmpty
              ? _buildEmptyState() // Liste boşsa bu gözüksün
              : _buildReminderList(), // Doluysa liste gözüksün
      
      // GÜNCELLEME 1: Geniş "Daha fazla ekleyin" butonu
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddPage,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Daha fazla ekleyin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Boş Durum Tasarımı
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Bugün için planlanmış bir dürt yok.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
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

  // Dolu Liste Tasarımı
  Widget _buildReminderList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Butonun altında kalmasın diye boşluk
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
            
            // GÜNCELLEME 2: Ok yerine "Düzenle" Butonu
            trailing: TextButton.icon(
              onPressed: () => _navigateToEditPage(reminder),
              icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
              label: const Text("Düzenle", style: TextStyle(color: Colors.grey)),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddPage() async {
    // Ekleme sayfasına git ve dönüşte veriyi yenile
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddReminderPage(initialDate: widget.selectedDate)),
    );
    _fetchReminders(); // Geri dönünce listeyi güncelle!
  }

  // YENİ: Düzenleme sayfasına gitme fonksiyonu
  void _navigateToEditPage(Map<String, dynamic> reminder) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReminderPage(reminder: reminder),
      ),
    );
    _fetchReminders(); // Düzenleme veya silme sonrası listeyi yenile
  }

  Icon _getIconForType(String type) {
    switch (type) {
      case 'Doktor Muayenesi': return const Icon(Icons.local_hospital, color: Colors.red);
      case 'İş Görüşmesi': return const Icon(Icons.work, color: Colors.blue);
      case 'Sınav': return const Icon(Icons.school, color: Colors.orange);
      default: return const Icon(Icons.notifications, color: Colors.grey);
    }
  }
}