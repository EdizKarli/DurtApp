import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart'; 

class EditReminderPage extends StatefulWidget {
  final Map<String, dynamic> reminder;
  final bool isReadOnly;

  const EditReminderPage({super.key, required this.reminder, this.isReadOnly = false});

  @override
  State<EditReminderPage> createState() => _EditReminderPageState();
}

class _EditReminderPageState extends State<EditReminderPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();
  
  String? _selectedType;
  DateTime _selectedDate = DateTime.now(); 
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  String? _selectedFrequency;
  final List<String> _frequencies = [
    "Sadece Bu Gün İçin",
    "1 Gün", "2 Gün", "3 Gün", "Haftada Bir", "Ayda Bir", "Özel Hatırlatma"
  ];
  final List<String> _types = ["Doktor Muayenesi", "İş Görüşmesi", "Sınav", "Doğum Günü", "Evlilik Yıldönümü", "İlişki Yıldönümü", "Eğlence", "Özel Dürt"];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.reminder['title'];
    DateTime fullDate = DateTime.parse(widget.reminder['reminder_time']).toLocal();
    _selectedDate = fullDate; 
    _selectedTime = TimeOfDay.fromDateTime(fullDate);

    String incomingType = widget.reminder['type'];
    if (_types.contains(incomingType)) _selectedType = incomingType;
    else { _selectedType = "Özel Dürt"; _customTypeController.text = incomingType; }

    String incomingFreq = widget.reminder['frequency'] ?? "1 Gün";
    if (incomingFreq == "Tek Seferlik") incomingFreq = "Sadece Bu Gün İçin"; 

    if (_frequencies.contains(incomingFreq)) _selectedFrequency = incomingFreq;
    else { _frequencies.add(incomingFreq); _selectedFrequency = incomingFreq; }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditingAllowed = !widget.isReadOnly; 
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.isReadOnly ? "Dürt Detayı" : "Dürt Düzenle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TÜR
             DropdownButtonFormField<String>(value: _selectedType, items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: isEditingAllowed ? (v) => setState(() => _selectedType = v) : null, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              if (_selectedType == "Özel Dürt") ...[ const SizedBox(height: 10), TextField(controller: _customTypeController, readOnly: !isEditingAllowed, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.red.shade50))],
              const SizedBox(height: 20),
            
            // BAŞLIK
            TextField(controller: _titleController, readOnly: !isEditingAllowed, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 20),

            // SIKLIK (ÜSTTE)
            DropdownButtonFormField<String>(
                value: _selectedFrequency,
                items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: isEditingAllowed ? (v) => setState(() => _selectedFrequency = v) : null,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 20),

            // TARİH KUTUSU
            InkWell(
              onTap: isEditingAllowed ? _pickDate : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [const Icon(Icons.event, color: Colors.blue), const SizedBox(width: 10), Text(DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate))]),
              ),
            ),
            
            const SizedBox(height: 20), 

            // SAAT
            InkWell(
              onTap: isEditingAllowed ? _pickTime : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [const Icon(Icons.access_time), const SizedBox(width: 10), Text("${_selectedTime.hour.toString().padLeft(2,'0')}:${_selectedTime.minute.toString().padLeft(2,'0')}") ]),
              ),
            ),
            const SizedBox(height: 40),

            // BUTONLAR
            if (isEditingAllowed) ...[
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _handleSaveButton, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), child: const Text("Değişiklikleri Kaydet", style: TextStyle(fontSize: 18)))),
              const SizedBox(height: 20), const Divider(), const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _handleDeleteButton, icon: const Icon(Icons.delete), label: const Text("Bu Dürtü Sil", style: TextStyle(fontSize: 18)), style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 139, 0, 0), foregroundColor: Colors.white))),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2030), locale: const Locale('tr', 'TR'));
    if (picked != null) setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
  }

  Future<void> _pickTime() async {
    showModalBottomSheet(context: context, builder: (c) => SizedBox(height: 250, child: CupertinoDatePicker(mode: CupertinoDatePickerMode.time, use24hFormat: true, initialDateTime: DateTime(2024, 1, 1, _selectedTime.hour, _selectedTime.minute), onDateTimeChanged: (t) => setState(() => _selectedTime = TimeOfDay.fromDateTime(t)))));
  }

  void _handleSaveButton() {
    String? groupId = widget.reminder['group_id'];
    if (groupId == null || groupId.isEmpty || _selectedFrequency == "Sadece Bu Gün İçin") {
      _forkNewSeries(); 
      return;
    }
    showDialog(
      context: context, builder: (context) => AlertDialog(
        title: const Text("Düzenleme Seçeneği"), content: const Text("Bu değişiklik nasıl uygulansın?"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _forkNewSeries(); }, child: const Text("Sadece Bu")),
          ElevatedButton(onPressed: () { Navigator.pop(context); _rewriteFutureSeries(groupId); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), child: const Text("Bu ve Sonrakiler")),
        ],
      ),
    );
  }

  Future<void> _forkNewSeries() async {
    String newGroupId = const Uuid().v4();
    await _generateSeriesLogic(newGroupId, isRewrite: false);
    if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Güncellendi!"))); }
  }

  Future<void> _rewriteFutureSeries(String currentGroupId) async {
    // 1. MEVCUT VE GELECEK KAYITLARI SİL
    // "Reminder Time" > "Orijinal Tarih - 1 saniye" diyerek
    // Orijinal kaydı da, gelecekteki kayıtları da siliyoruz.
    String oldDateStr = widget.reminder['reminder_time']; 
    DateTime oldDate = DateTime.parse(oldDateStr);
    
    // Geriye doğru 1 saniye gidiyoruz ki mevcut kayıt da kapsama alanına girsin ve silinsin.
    DateTime wipeDate = oldDate.subtract(const Duration(seconds: 1));
    String wipeDateStr = "${wipeDate.year}-${wipeDate.month.toString().padLeft(2, '0')}-${wipeDate.day.toString().padLeft(2, '0')} ${wipeDate.hour.toString().padLeft(2, '0')}:${wipeDate.minute.toString().padLeft(2, '0')}:${wipeDate.second.toString().padLeft(2, '0')}";

    final deleteUrl = Uri.parse('http://localhost:3000/api/reminders/group/$currentGroupId/future?date=$wipeDateStr');
    await http.delete(deleteUrl);

    // 2. YENİDEN OLUŞTUR (CREATE)
    // Artık tertemiz bir sayfa açtık, hem bugünü hem geleceği tekrar oluşturacağız.
    await _generateSeriesLogic(currentGroupId, isRewrite: true);
    
    if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Seri güncellendi!"))); }
  }

  Future<void> _generateSeriesLogic(String groupId, {required bool isRewrite}) async {
    // BAŞLANGIÇ: Düzenlediğimiz kartın orijinal günü + Yeni seçilen saat
    DateTime originalReminderDate = DateTime.parse(widget.reminder['reminder_time']).toLocal();
    DateTime startDate = DateTime(originalReminderDate.year, originalReminderDate.month, originalReminderDate.day, _selectedTime.hour, _selectedTime.minute);
    
    // BİTİŞ LİMİTİ
    DateTime limitDate = _selectedDate;
    if (_selectedFrequency == "Sadece Bu Gün İçin") {
       limitDate = DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
    }

    // --- DÜZELTME BURADA YAPILDI ---
    // Daha önceki kodda burada "if (startDate.isBefore(now)) startDate.add(1 gün)" kodu vardı.
    // DÜZENLEME yaparken bu olmamalı. Kullanıcı 3 Şubat'ı düzenliyorsa, saat geçmiş bile olsa 3 Şubat'ta kalmalıdır.
    // O yüzden o kontrol bloğu tamamen kaldırıldı.
    
    // 1. BAŞLANGIÇ KARTINI OLUŞTUR/GÜNCELLE
    // Eğer "Sadece Bu Gün" ise tarihi seçilen tarih yap (fork mantığı için)
    if (_selectedFrequency == "Sadece Bu Gün İçin") {
       startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    }

    // Mevcut kartı işle (Rewrite ise POST, Fork ise PUT)
    if (isRewrite) {
        // Rewrite modunda eskiyi sildiğimiz için YENİDEN OLUŞTUR (POST)
        await _createNewRow(startDate, groupId);
    } else {
        // Fork modunda eski duruyor, GÜNCELLE (PUT)
        await _updateCurrentRow(startDate, groupId);
    }

    // 2. GELECEĞİ OLUŞTUR
    if (_selectedFrequency != "Sadece Bu Gün İçin") {
        int intervalDays = _getIntervalDays();
        DateTime loopDate = startDate.add(Duration(days: intervalDays));
        int count = 0;
        //String finalType = _selectedType == "Özel Dürt" ? _customTypeController.text : _selectedType!;

        while ((loopDate.isBefore(limitDate) || loopDate.isAtSameMomentAs(limitDate)) && count < 100) {
          await _createNewRow(loopDate, groupId);
          loopDate = loopDate.add(Duration(days: intervalDays));
          count++;
        }
    }
  }

  // Yardımcı: PUT (Sadece Bu / Fork)
  Future<void> _updateCurrentRow(DateTime targetDate, String groupId) async {
    String formattedDate = _formatDate(targetDate);
    String finalType = _selectedType == "Özel Dürt" ? _customTypeController.text : _selectedType!;
    String finalFreq = _selectedFrequency == "Sadece Bu Gün İçin" ? "Tek Seferlik" : _selectedFrequency!;

    final url = Uri.parse('http://localhost:3000/api/reminders/${widget.reminder['id']}');
    await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'title': _titleController.text, 'type': finalType, 'reminder_time': formattedDate, 'frequency': finalFreq, 'group_id': groupId}));
  }

  // Yardımcı: POST (Bu ve Sonrakiler / Rewrite)
  Future<void> _createNewRow(DateTime targetDate, String groupId) async {
    String formattedDate = _formatDate(targetDate);
    String finalType = _selectedType == "Özel Dürt" ? _customTypeController.text : _selectedType!;
    //String finalFreq = _selectedFrequency == "Sadece Bu Gün İçin" ? "Tek Seferlik" : _selectedFrequency!; // Burası seri içinde 'Tek Seferlik' olmamalı aslında ama grup mantığı için frekansı koruyabiliriz. Düzeltme:
    // Eğer seri oluşturuyorsak frekans ismi doğru gitmeli.
    String loopFreq = _selectedFrequency!;
    if (_selectedFrequency == "Sadece Bu Gün İçin") loopFreq = "Tek Seferlik";

    final url = Uri.parse('http://localhost:3000/api/reminders');
    await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'title': _titleController.text, 'type': finalType, 'reminder_time': formattedDate, 'frequency': loopFreq, 'group_id': groupId}));
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:00";
  }

  int _getIntervalDays() {
    switch (_selectedFrequency) {
        case "1 Gün": return 1; case "2 Gün": return 2; case "3 Gün": return 3; case "Haftada Bir": return 7; case "Ayda Bir": return 30; default: return 1;
    }
  }

  void _handleDeleteButton() {
    String? groupId = widget.reminder['group_id'];
    if (groupId == null || groupId.isEmpty) { _confirmDeleteSingle(); return; }
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Silme Seçeneği"), content: const Text("Hangi dürtler silinsin?"), actions: [TextButton(onPressed: () { Navigator.pop(context); _deleteSingleReminder(); }, child: const Text("Sadece Bu")), ElevatedButton(onPressed: () { Navigator.pop(context); _deleteThisAndFutureReminders(groupId); if (mounted) Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Bu ve Sonrakiler"))]));
  }

  void _confirmDeleteSingle() {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Emin misiniz?"), content: const Text("Bu dürt kalıcı olarak silinecektir."), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")), TextButton(onPressed: () { Navigator.pop(context); _deleteSingleReminder(); }, child: const Text("Sil", style: TextStyle(color: Colors.red)))]));
  }

  Future<void> _deleteSingleReminder() async {
    final url = Uri.parse('http://localhost:3000/api/reminders/${widget.reminder['id']}');
    try { await http.delete(url); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ Silindi"))); } } catch (e) { print("Silme Hatası: $e"); }
  }

  Future<void> _deleteThisAndFutureReminders(String groupId) async {
    String oldDateStr = widget.reminder['reminder_time']; DateTime oldDate = DateTime.parse(oldDateStr); DateTime wipeDate = oldDate.subtract(const Duration(seconds: 1)); String wipeDateStr = "${wipeDate.year}-${wipeDate.month.toString().padLeft(2, '0')}-${wipeDate.day.toString().padLeft(2, '0')} ${wipeDate.hour.toString().padLeft(2, '0')}:${wipeDate.minute.toString().padLeft(2, '0')}:${wipeDate.second.toString().padLeft(2, '0')}";
    final deleteFutureUrl = Uri.parse('http://localhost:3000/api/reminders/group/$groupId/future?date=$wipeDateStr');
    await http.delete(deleteFutureUrl);
  }
}