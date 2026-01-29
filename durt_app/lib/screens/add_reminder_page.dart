import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // YENİ: Backend ile konuşmak için
import 'dart:convert'; // YENİ: Veriyi JSON'a çevirmek için

class AddReminderPage extends StatefulWidget {
  final DateTime initialDate;

  const AddReminderPage({super.key, required this.initialDate});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final TextEditingController _titleController = TextEditingController();
  String? _selectedType;
  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = "1 Gün Önce";

  final List<String> _types = ["Doktor Muayenesi", "İş Görüşmesi", "Sınav", "Özel Dürt"];
  final List<String> _frequencies = ["1 Gün Önce"];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Dürt Ekle"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DÜRT TÜRÜ
            const Text("Dürt Türü", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              hint: const Text("Bir tür seçiniz"),
              items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) => setState(() => _selectedType = value),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.category),
              ),
            ),
            
            const SizedBox(height: 20),

            // 2. BAŞLIK
            const Text("Başlık", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: "Örn: Dişçi Randevusu",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),

            const SizedBox(height: 10),

            // 3. TARİH
            const Text("Son Tarih", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. SIKLIK
            const Text("Hatırlatma Sıklığı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedFrequency,
              items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value!;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.alarm),
              ),
            ),

            const SizedBox(height: 40),

            // KAYDET BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Dürt Oluştur", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    // Eğer düzenleme yaparken mevcut tarih bugünden önceyse (geçmişteyse),
    // Takvim açılırken hata vermemesi için "başlangıç tarihini" o gün yapıyoruz.
    // Ancak seçilebilir en erken tarih (firstDate) her zaman "Bugün" oluyor.
    DateTime initial = _selectedDate;
    if (initial.isBefore(DateTime.now())) {
      initial = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,     // Takvim açıldığında seçili duran gün
      firstDate: DateTime.now(), // KURAL: Bugünden önceki günler GRİ olur, seçilemez!
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'), // Takvimin Türkçe olması için
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- İŞTE SİHİR BURADA GERÇEKLEŞİYOR ---
  Future<void> _saveReminder() async {
    // 1. Basit kontrol: Başlık veya Tür boşsa uyarı ver
    if (_titleController.text.isEmpty || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen başlık ve tür seçiniz")),
      );
      return;
    }

    // 2. Backend Adresi (Chrome kullandığınız için localhost çalışır)
    final url = Uri.parse('http://localhost:3000/api/reminders');

    try {
      // 3. İsteği Gönder (POST)
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // 4. Veriyi JSON formatına çevir
        body: jsonEncode({
          'title': _titleController.text,
          'type': _selectedType, // Veritabanındaki yeni sütun
          'reminder_time': _selectedDate.toIso8601String(), // Tarihi standart formatta gönder
          'frequency': _selectedFrequency, // Veritabanındaki yeni sütun
        }),
      );

      // 5. Sonucu Kontrol Et
      if (response.statusCode == 200) {
        // Başarılı!
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Dürt başarıyla oluşturuldu!")),
          );
          Navigator.pop(context); // Önceki sayfaya dön
        }
      } else {
        // Sunucu hatası
        print('Hata: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata oluştu: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      // Bağlantı hatası (Backend kapalıysa buraya düşer)
      print('Bağlantı Hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sunucuya bağlanılamadı. Backend açık mı?")),
        );
      }
    }
  }
}