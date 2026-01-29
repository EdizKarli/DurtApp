import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditReminderPage extends StatefulWidget {
  final Map<String, dynamic> reminder;
  final bool isReadOnly; // YENİ: Sadece inceleme modu mu?

  // isReadOnly varsayılan olarak false olsun ki normal çalışsın
  const EditReminderPage({
    super.key, 
    required this.reminder, 
    this.isReadOnly = false 
  });

  @override
  State<EditReminderPage> createState() => _EditReminderPageState();
}

class _EditReminderPageState extends State<EditReminderPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();
  
  String? _selectedType;
  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = "1 Gün Önce";

  final List<String> _types = ["Doktor Muayenesi", "İş Görüşmesi", "Sınav", "Özel Dürt"];
  final List<String> _frequencies = ["1 Gün Önce", "2 Gün Önce", "1 Hafta Önce"];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.reminder['title'];
    _selectedFrequency = widget.reminder['frequency'] ?? "1 Gün Önce";
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
    // Sadece okuma modundaysak kutular kilitli (enabled: false) olsun
    bool isEditingAllowed = !widget.isReadOnly; 

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReadOnly ? "Dürt Detayı" : "Dürt Düzenle"), // Başlık değişiyor
        backgroundColor: Colors.white, 
        foregroundColor: Colors.black, 
        elevation: 0
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dürt Türü", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            // Dropdown kilitlendi
            IgnorePointer(
              ignoring: !isEditingAllowed, // Tıklamayı engelle
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: isEditingAllowed ? (value) { // Değişiklik kapalıysa null yapmıyoruz ama IgnorePointer zaten engelliyor
                  setState(() {
                    _selectedType = value;
                    if (value != "Özel Dürt") _customTypeController.clear();
                  });
                } : null, // Görsel olarak da pasif dursun
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            
            if (_selectedType == "Özel Dürt") ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customTypeController,
                readOnly: !isEditingAllowed, // Klavye açılmaz
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true, 
                  fillColor: isEditingAllowed ? Colors.red.shade50 : Colors.grey.shade100, // Renk farkı
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            const Text("Başlık", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController, 
              readOnly: !isEditingAllowed, // Klavye açılmaz
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                fillColor: isEditingAllowed ? null : Colors.grey.shade100,
                filled: !isEditingAllowed,
              )
            ),
            
            const SizedBox(height: 20),

            const Text("Son Tarih", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: isEditingAllowed ? _pickDate : null, // Tıklanmaz
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: isEditingAllowed ? null : Colors.grey.shade100, // Arkaplan gri
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: isEditingAllowed ? Colors.blue : Colors.grey),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate),
                      style: TextStyle(fontSize: 16, color: isEditingAllowed ? Colors.black : Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            const Text("Sıklık", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
             IgnorePointer(
              ignoring: !isEditingAllowed,
               child: DropdownButtonFormField<String>(
                value: _selectedFrequency,
                items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: isEditingAllowed ? (value) => setState(() => _selectedFrequency = value!) : null,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                           ),
             ),

            const SizedBox(height: 40),

            // BUTONLAR SADECE DÜZENLEME MODUNDAYSA GÖZÜKÜR
            if (isEditingAllowed) ...[
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
            ] else ...[
              // İnceleme Modundaysa bilgilendirici bir yazı
              const Center(
                child: Text(
                  "Geçmiş dürtler üzerinde değişiklik yapılamaz.",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    // ... (Eski kodunuzla aynı) ...
     DateTime initial = _selectedDate;
    if (initial.isBefore(DateTime.now())) {
      initial = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,     
      firstDate: DateTime.now(), 
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'), 
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateReminder() async {
      // ... (Eski kodunuzla aynı) ...
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
      // ... (Eski kodunuzla aynı) ...
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