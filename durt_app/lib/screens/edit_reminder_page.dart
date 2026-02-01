import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart'; 

class EditReminderPage extends StatefulWidget {
  final Map<String, dynamic> reminder;
  final bool isReadOnly;

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
  DateTime _selectedDate = DateTime.now(); // Limit (Bitiş) Tarihi
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedFrequency;
  
  final List<String> _frequencies = [
    "1 Gün", "2 Gün", "3 Gün", "Haftada Bir", "Ayda Bir", "Özel Hatırlatma"
  ];
  final List<String> _types = ["Doktor Muayenesi", "İş Görüşmesi", "Sınav", "Özel Dürt"];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.reminder['title'];
    
    DateTime fullDate = DateTime.parse(widget.reminder['reminder_time']).toLocal();
    _selectedDate = fullDate;
    _selectedTime = TimeOfDay.fromDateTime(fullDate);

    String incomingType = widget.reminder['type'];
    if (_types.contains(incomingType)) {
      _selectedType = incomingType;
    } else {
      _selectedType = "Özel Dürt";
      _customTypeController.text = incomingType;
    }

    String incomingFreq = widget.reminder['frequency'] ?? "1 Gün";
    if (_frequencies.contains(incomingFreq)) {
      _selectedFrequency = incomingFreq;
    } else {
      _frequencies.add(incomingFreq); 
      _selectedFrequency = incomingFreq;
    }
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
             DropdownButtonFormField<String>(
                value: _selectedType,
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: isEditingAllowed ? (v) => setState(() => _selectedType = v) : null,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              if (_selectedType == "Özel Dürt") ...[
                const SizedBox(height: 10),
                TextField(controller: _customTypeController, readOnly: !isEditingAllowed, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.red.shade50)),
              ],
              const SizedBox(height: 20),
            
            // BAŞLIK
            TextField(controller: _titleController, readOnly: !isEditingAllowed, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 20),

            // TARİH KUTUSU
            InkWell(
              onTap: isEditingAllowed ? _pickDate : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Colors.blue), 
                    const SizedBox(width: 10), 
                    Text(DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate))
                  ]
                ),
              ),
            ),
            if (isEditingAllowed)
              const Padding(
                padding: EdgeInsets.only(top: 5, left: 5),
                child: Text(
                  "* 'Bu ve Sonrakiler' derseniz, bu tarih SERİ BİTİŞ tarihi olur.", 
                  style: TextStyle(fontSize: 11, color: Colors.grey),
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
            const SizedBox(height: 20),

            // SIKLIK
            DropdownButtonFormField<String>(
                value: _selectedFrequency,
                items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: isEditingAllowed ? (v) => setState(() => _selectedFrequency = v) : null,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 40),

            // BUTONLAR
            if (isEditingAllowed) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleSaveButton, 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text("Değişiklikleri Kaydet", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(), 
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _handleDeleteButton, 
                  icon: const Icon(Icons.delete),
                  label: const Text("Bu Dürtü Sil", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 139, 0, 0), foregroundColor: Colors.white),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, 
      initialDate: _selectedDate, 
      firstDate: DateTime.now().subtract(const Duration(days: 365)), 
      lastDate: DateTime(2030), 
      locale: const Locale('tr', 'TR')
    );
    if (picked != null) {
      // Gün sonuna sabitle
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
    }
  }

  Future<void> _pickTime() async {
    showModalBottomSheet(context: context, builder: (c) => SizedBox(height: 250, child: CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time, use24hFormat: true,
      initialDateTime: DateTime(2024, 1, 1, _selectedTime.hour, _selectedTime.minute),
      onDateTimeChanged: (t) => setState(() => _selectedTime = TimeOfDay.fromDateTime(t))
    )));
  }

  // ==========================================
  //      KAYDETME MANTIĞI
  // ==========================================
  void _handleSaveButton() {
    String? groupId = widget.reminder['group_id'];

    if (groupId == null || groupId.isEmpty) {
      _forkNewSeries(); // Grubu yoksa yeni seri başlat
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Düzenleme Seçeneği"),
        content: const Text("Bu değişiklik nasıl uygulansın?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _forkNewSeries(); // Sadece Bu
            },
            child: const Text("Sadece Bu"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rewriteFutureSeries(groupId); // Bu ve Sonrakiler
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text("Bu ve Sonrakiler"),
          ),
        ],
      ),
    );
  }

  // SENARYO 1: SADECE BU (Fork)
  // Mevcut kaydı güncelle (yeni grup ID ile) ve ileriye doğru yeni seri üret.
  // Eski grubun geleceğine dokunulmaz.
  Future<void> _forkNewSeries() async {
    String newGroupId = const Uuid().v4();
    // Mevcut kaydı güncelle
    await _generateSeriesLogic(newGroupId, shouldUpdateCurrent: true);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Yeni seri oluşturuldu!")));
    }
  }

  // SENARYO 2: BU VE SONRAKİLER (Tamamen Yenileme)
  Future<void> _rewriteFutureSeries(String currentGroupId) async {
    // 1. MEVCUT VE GELECEK KAYITLARI SİL
    // "Reminder Time" > "Orijinal Tarih - 1 saniye" diyerek
    // Orijinal kaydı da, gelecekteki kayıtları da siliyoruz.
    String oldDateStr = widget.reminder['reminder_time']; 
    DateTime oldDate = DateTime.parse(oldDateStr);
    
    // Geriye doğru 1 saniye gidiyoruz ki mevcut kayıt da kapsama alanına girsin.
    DateTime wipeDate = oldDate.subtract(const Duration(seconds: 1));
    String wipeDateStr = "${wipeDate.year}-${wipeDate.month.toString().padLeft(2, '0')}-${wipeDate.day.toString().padLeft(2, '0')} ${wipeDate.hour.toString().padLeft(2, '0')}:${wipeDate.minute.toString().padLeft(2, '0')}:${wipeDate.second.toString().padLeft(2, '0')}";

    final deleteUrl = Uri.parse('http://localhost:3000/api/reminders/group/$currentGroupId/future?date=$wipeDateStr');
    await http.delete(deleteUrl);

    // 2. HER ŞEYİ SIFIRDAN OLUŞTUR (CREATE, NOT UPDATE)
    // Eski kayıt silindiği için "Update" (PUT) yapamayız. "Create" (POST) yapacağız.
    await _generateSeriesLogic(currentGroupId, shouldUpdateCurrent: false);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Seri güncellendi!")));
    }
  }

  // --- ANA MANTIK MOTORU ---
  Future<void> _generateSeriesLogic(String groupId, {required bool shouldUpdateCurrent}) async {
    // BAŞLANGIÇ: Orijinal kartın tarihi (Yıl/Ay/Gün) + Yeni seçilen Saat
    DateTime originalReminderDate = DateTime.parse(widget.reminder['reminder_time']).toLocal();
    
    DateTime startDate = DateTime(
      originalReminderDate.year, 
      originalReminderDate.month, 
      originalReminderDate.day, 
      _selectedTime.hour, 
      _selectedTime.minute
    );
    
    // BİTİŞ: Kullanıcının seçtiği tarih
    DateTime limitDate = _selectedDate;

    // GEÇMİŞ KONTROLÜ (Sadece "Bugün" ise ve geçmişteyse)
    DateTime now = DateTime.now();
    DateTime nowClean = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    
    int intervalDays = _getIntervalDays();
    if (startDate.year == now.year && startDate.month == now.month && startDate.day == now.day) {
       if (startDate.isBefore(nowClean)) {
          startDate = startDate.add(Duration(days: intervalDays));
       }
    }

    // ADIM 1: İLK KARTI İŞLE (Mevcut Günü)
    if (shouldUpdateCurrent) {
      // "Sadece Bu" modunda mevcut kart duruyor, onu güncelliyoruz (PUT).
      await _updateCurrentRow(startDate, groupId);
    } else {
      // "Bu ve Sonrakiler" modunda mevcut kartı silmiştik, YENİDEN YARATIYORUZ (POST).
      await _createNewRow(startDate, groupId);
    }

    // ADIM 2: GELECEK DÜRTLERİ ÜRET (Hepsi POST)
    DateTime loopDate = startDate.add(Duration(days: intervalDays));
    int count = 0;

    while ((loopDate.isBefore(limitDate) || loopDate.isAtSameMomentAs(limitDate)) && count < 100) {
      await _createNewRow(loopDate, groupId);
      loopDate = loopDate.add(Duration(days: intervalDays));
      count++;
    }
  }

  // Yardımcı: PUT (Güncelle)
  Future<void> _updateCurrentRow(DateTime targetDate, String groupId) async {
    String formattedDate = _formatDate(targetDate);
    String finalType = _selectedType == "Özel Dürt" ? _customTypeController.text : _selectedType!;
    final url = Uri.parse('http://localhost:3000/api/reminders/${widget.reminder['id']}');
    
    await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': _titleController.text,
        'type': finalType,
        'reminder_time': formattedDate,
        'frequency': _selectedFrequency,
        'group_id': groupId,
      }),
    );
  }

  // Yardımcı: POST (Yeni Yarat)
  Future<void> _createNewRow(DateTime targetDate, String groupId) async {
    String formattedDate = _formatDate(targetDate);
    String finalType = _selectedType == "Özel Dürt" ? _customTypeController.text : _selectedType!;
    final url = Uri.parse('http://localhost:3000/api/reminders');

    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': _titleController.text,
        'type': finalType,
        'reminder_time': formattedDate,
        'frequency': _selectedFrequency,
        'group_id': groupId, 
      }),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:00";
  }

  int _getIntervalDays() {
    switch (_selectedFrequency) {
        case "1 Gün": return 1;
        case "2 Gün": return 2;
        case "3 Gün": return 3;
        case "Haftada Bir": return 7;
        case "Ayda Bir": return 30;
        default: return 1;
    }
  }

  // --- SİLME BUTONU ---
  void _handleDeleteButton() {
    String? groupId = widget.reminder['group_id'];
    if (groupId == null || groupId.isEmpty) {
      _confirmDeleteSingle();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Silme Seçeneği"),
        content: const Text("Hangi dürtler silinsin?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSingleReminder(); 
            },
            child: const Text("Sadece Bu"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteThisAndFutureReminders(groupId);
              if (mounted) Navigator.pop(context); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Bu ve Sonrakiler"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSingle() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu dürt kalıcı olarak silinecektir."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSingleReminder();
            }, 
            child: const Text("Sil", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSingleReminder() async {
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

  Future<void> _deleteThisAndFutureReminders(String groupId) async {
    String oldDateStr = widget.reminder['reminder_time']; 
    // Silme butonuna basınca da "Mevcut + Sonrası" mantığı aynıdır.
    // O yüzden 1 saniye geriye gidip oradan sonrasını siliyoruz.
    DateTime oldDate = DateTime.parse(oldDateStr);
    DateTime wipeDate = oldDate.subtract(const Duration(seconds: 1));
    String wipeDateStr = "${wipeDate.year}-${wipeDate.month.toString().padLeft(2, '0')}-${wipeDate.day.toString().padLeft(2, '0')} ${wipeDate.hour.toString().padLeft(2, '0')}:${wipeDate.minute.toString().padLeft(2, '0')}:${wipeDate.second.toString().padLeft(2, '0')}";

    final deleteFutureUrl = Uri.parse('http://localhost:3000/api/reminders/group/$groupId/future?date=$wipeDateStr');
    await http.delete(deleteFutureUrl);
    
    // Not: Burada ayrıca _deleteSingleReminder() çağırmaya gerek yok çünkü
    // "wipeDate" (1 saniye öncesi) sayesinde mevcut kayıt da silinecektir.
  }
}