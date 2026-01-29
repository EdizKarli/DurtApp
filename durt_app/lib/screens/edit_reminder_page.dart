import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditReminderPage extends StatefulWidget {
  final Map<String, dynamic> reminder;

  const EditReminderPage({super.key, required this.reminder});

  @override
  State<EditReminderPage> createState() => _EditReminderPageState();
}

class _EditReminderPageState extends State<EditReminderPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();
  
  String? _selectedType;
  DateTime _selectedDate = DateTime.now(); // Tarih verisi burada tutuluyor
  String _selectedFrequency = "1 Gün Önce";

  final List<String> _types = ["Doktor Muayenesi", "İş Görüşmesi", "Sınav", "Özel Dürt"];
  final List<String> _frequencies = ["1 Gün Önce", "2 Gün Önce", "1 Hafta Önce"];

  @override
  void initState() {
    super.initState();
    // MEVCUT VERİLERİ DOLDURMA
    _titleController.text = widget.reminder['title'];
    _selectedFrequency = widget.reminder['frequency'] ?? "1 Gün Önce";
    
    // Tarihi veritabanından gelen string'den DateTime'a çeviriyoruz
    _selectedDate = DateTime.parse(widget.reminder['reminder_time']);

    String incomingType = widget.reminder['type'];
    if (_types.contains(incomingType)) {
      _selectedType = incomingType;
    } else {
      _selectedType = "Özel Dürt";
      _customTypeController.text = incomingType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dürt Düzenle"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
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
              items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  if (value != "Özel Dürt") _customTypeController.clear();
                });
              },
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            
            
            const SizedBox(height: 20),
            
            // 2. BAŞLIK
            const Text("Başlık", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(controller: _titleController, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            
            const SizedBox(height: 20),

            // 3. TARİH SEÇİMİ (YENİ EKLENEN KISIM)
            const Text("Son Tarih", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate, // Tıklayınca takvimi açar
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue), // Düzenleme sayfası olduğu için Mavi ikon
                    const SizedBox(width: 10),
                    // Tarihi Gün Ay Yıl formatında göster
                    Text(
                      DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // 4. SIKLIK
            const Text("Sıklık", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedFrequency,
              items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (value) => setState(() => _selectedFrequency = value!),
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),

            const SizedBox(height: 40),

            // GÜNCELLE BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _updateReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Değişiklikleri Kaydet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // SİLME BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _deleteReminder,
                icon: const Icon(Icons.delete),
                label: const Text("Bu Dürtü Sil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 139, 0, 0), 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TARİH SEÇME FONKSİYONU
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

  Future<void> _updateReminder() async {
    String finalType = _selectedType == "Özel Dürt" ? _customTypeController.text : _selectedType!;
    final url = Uri.parse('http://localhost:3000/api/reminders/${widget.reminder['id']}');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text,
          'type': finalType,
          'reminder_time': _selectedDate.toIso8601String(), // Güncel tarihi gönderiyoruz
          'frequency': _selectedFrequency,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Güncellendi")));
      }
    } catch (e) {
      print("Hata: $e");
    }
  }

  Future<void> _deleteReminder() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu dürt kalıcı olarak silinecektir."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final url = Uri.parse('http://localhost:3000/api/reminders/${widget.reminder['id']}');
      try {
        await http.delete(url);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ Silindi")));
        }
      } catch (e) {
        print("Silme Hatası: $e");
      }
    }
  }
}