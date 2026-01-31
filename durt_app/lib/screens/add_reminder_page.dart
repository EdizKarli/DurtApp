import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddReminderPage extends StatefulWidget {
  final DateTime initialDate;

  const AddReminderPage({super.key, required this.initialDate});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();
  
  String? _selectedType;
  
  // 1. SON TARİH
  DateTime _endDate = DateTime.now(); 
  
  // 2. HATIRLATMA SAATİ
  TimeOfDay _reminderTime = TimeOfDay.now();

  String _selectedFrequency = "1 Gün";
  final List<String> _frequencies = [
    "1 Gün",
    "2 Gün",
    "3 Gün",
    "Haftada Bir",
    "Ayda Bir",
    "Özel Hatırlatma"
  ];

  int? _customIntervalInDays; 
  final List<String> _types = ["Doktor Muayenesi", "İş Görüşmesi", "Sınav", "Özel Dürt"];

  @override
  void initState() {
    super.initState();
    
    DateTime now = DateTime.now();
    DateTime targetDate = widget.initialDate;

    // Eğer gelen tarih geçmişse, bugünü baz al
    if (targetDate.isBefore(DateTime(now.year, now.month, now.day))) {
      targetDate = now;
    }

    // --- KRİTİK DÜZELTME 1 ---
    // Son tarih başlangıçta "Şu an" değil, "Bugünün Sonu (23:59:59)" olmalı.
    // Yoksa saat 15:00 iken 18:00 seçerseniz döngü çalışmaz.
    _endDate = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

    _reminderTime = TimeOfDay.now();
  }

  // Bugün Kontrolü İçin Yardımcı Fonksiyon
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    // KURAL: Eğer son tarih BUGÜN ise, sıklık seçimi kilitlenmeli
    bool isFrequencyLocked = _isToday(_endDate);

    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Dürt Ekle"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TÜR SEÇİMİ ---
            const Text("Dürt Türü", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              hint: const Text("Bir tür seçiniz"),
              items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  if (value != "Özel Dürt") _customTypeController.clear();
                });
              },
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            
            if (_selectedType == "Özel Dürt") ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customTypeController,
                decoration: InputDecoration(
                  hintText: "Özel türü yazın",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: Colors.red.shade50,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // --- BAŞLIK ---
            const Text("Başlık", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(controller: _titleController, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),

            const SizedBox(height: 20),

            // --- SON TARİH ---
            const Text("Son Tarih (Hangi güne kadar?)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickEndDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(DateFormat('d MMMM yyyy', 'tr_TR').format(_endDate)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- SAAT ---
            const Text("Hatırlatma Saati (Saat kaçta?)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTimeCupertino, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text(
                      "${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- SIKLIK ---
            const Text("Hatırlatma Sıklığı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: isFrequencyLocked, 
              child: DropdownButtonFormField<String>(
                value: _selectedFrequency,
                items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: isFrequencyLocked ? null : (value) {
                  setState(() => _selectedFrequency = value!);
                  if (value == "Özel Hatırlatma") {
                    _showCustomIntervalDialog();
                  } else {
                    _customIntervalInDays = null;
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: isFrequencyLocked,
                  fillColor: isFrequencyLocked ? Colors.grey.shade200 : null,
                ),
              ),
            ),
            
            if (isFrequencyLocked)
              const Padding(
                padding: EdgeInsets.only(top: 5.0, left: 5.0),
                child: Text("Son tarih bugün olduğu için sıklık seçilemez.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            
            if (!isFrequencyLocked && _selectedFrequency == "Özel Hatırlatma" && _customIntervalInDays != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Seçilen Aralık: $_customIntervalInDays Gün'de bir",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 40),

            // OLUŞTUR BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _generateAndSaveReminders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Dürtleri Oluştur", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickEndDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: now,
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        // Gün sonuna sabitle (23:59:59)
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        
        if (_isToday(_endDate)) {
          _selectedFrequency = "1 Gün";
          _customIntervalInDays = null;
        }
      });
    }
  }

  void _pickTimeCupertino() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 300, 
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tamam", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(2024, 1, 1, _reminderTime.hour, _reminderTime.minute),
                  onDateTimeChanged: (DateTime newDateTime) {
                    
                    if (_isToday(_endDate)) {
                       final now = DateTime.now();
                       if (newDateTime.hour < now.hour || (newDateTime.hour == now.hour && newDateTime.minute < now.minute)) {
                         setState(() {
                           _reminderTime = TimeOfDay.fromDateTime(now);
                         });
                         return;
                       }
                    }
                    setState(() {
                      _reminderTime = TimeOfDay.fromDateTime(newDateTime);
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomIntervalDialog() {
    int value = 1;
    String unit = "Gün"; 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Özel Aralık Belirle"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Sayı"),
                          onChanged: (val) => value = int.tryParse(val) ?? 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: unit,
                          isExpanded: true,
                          items: ["Gün", "Hafta"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setDialogState(() => unit = val!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _selectedFrequency = "1 Gün");
                    Navigator.pop(context);
                  },
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    int days = 0;
                    if (unit == "Gün") days = value;
                    if (unit == "Hafta") days = value * 7;
                    if (days < 1) days = 1;
                    setState(() => _customIntervalInDays = days);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text("Ayarla"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateAndSaveReminders() async {
    // 1. Önce Başlık ve Tür Kontrolü
    if (_titleController.text.isEmpty || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen başlık ve tür seçiniz")));
      return;
    }

    DateTime now = DateTime.now();
    
    // Saniye hassasiyetini temizle (Karşılaştırma için)
    DateTime nowClean = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    
    // Hatırlatma Zamanı (Örn: Bugün 20:00 veya Bugün 14:00 olarak başlar)
    DateTime loopDate = DateTime(
      now.year, now.month, now.day, 
      _reminderTime.hour, _reminderTime.minute
    );

    // --- SIKLIK VE ARALIK HESABI (Öne çektik) ---
    // Bu hesabı loopDate kontrolünden önce yapmalıyız ki
    // eğer saat geçmişse ne kadar öteleyeceğimizi bilelim.
    int intervalDays = 1;
    String frequencyToSend = _selectedFrequency;

    if (_selectedFrequency == "Özel Hatırlatma") {
      intervalDays = _customIntervalInDays ?? 1;
    } else {
      switch (_selectedFrequency) {
        case "1 Gün": intervalDays = 1; break;
        case "2 Gün": intervalDays = 2; break;
        case "3 Gün": intervalDays = 3; break;
        case "Haftada Bir": intervalDays = 7; break;
        case "Ayda Bir": intervalDays = 30; break;
        default: intervalDays = 1;
      }
    }

    // --- KRİTİK MANTIK DÜZELTMESİ ---
    
    bool isEndDateToday = _isToday(_endDate);

    if (isEndDateToday) {
      // Eğer son tarih bugünse, sıklık "Tek Seferlik" olur.
      frequencyToSend = "Tek Seferlik"; 

      // Eğer saat geçmişteyse HATA VER (Bugüne ekleyemezsin)
      if (loopDate.isBefore(nowClean)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Geçmiş bir saate dürt eklenemez.")));
         return;
      }
      // Eğer saat gelecekteyse dokunma, loopDate BUGÜN olarak kalsın.
      
    } else {
      // Eğer son tarih ileri bir tarihse:
      
      if (loopDate.isBefore(nowClean)) {
        // SENARYO A: Saat 19:00, Seçilen 14:00 (Geçmiş)
        // Bugünü atla ve direkt olarak ARALIK kadar ileri git.
        // (Eskiden sadece 1 gün ekliyorduk, hata buydu. Artık 2 günse 2 gün ekliyoruz.)
        loopDate = loopDate.add(Duration(days: intervalDays));
      } 
      // SENARYO B: Saat 19:00, Seçilen 20:00 (Gelecek)
      // Hiçbir şey yapma. loopDate BUGÜN 20:00 olarak başlar. 
    }

    int count = 0;
    
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.red))
    );

    String finalType = _selectedType == "Özel Dürt" ? _customTypeController.text : _selectedType!;

    // Döngü
    while ((loopDate.isBefore(_endDate) || loopDate.isAtSameMomentAs(_endDate)) && count < 365) {
      await _sendToBackend(
        title: _titleController.text,
        type: finalType,
        date: loopDate,
        frequency: frequencyToSend 
      );
      
      if (isEndDateToday) {
        count++; 
        break;   
      }

      loopDate = loopDate.add(Duration(days: intervalDays));
      count++;
    }

    if (mounted) {
      Navigator.pop(context); 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Toplam $count adet dürt oluşturuldu!")));
    }
  }

  Future<void> _sendToBackend({required String title, required String type, required DateTime date, required String frequency}) async {
    final url = Uri.parse('http://localhost:3000/api/reminders');
    
    // ÇÖZÜM BURADA:
    // Tarihi formatlarken kütüphane kullanmak yerine elle oluşturuyoruz.
    // Böylece saat dilimi farkı (UTC+3) silinmeden, ekranda ne görüyorsak o gidiyor.
    String formattedDate = 
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:00";

    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'type': type,
          'reminder_time': formattedDate, // Saf metin olarak gönderiyoruz
          'frequency': frequency,
        }),
      );
    } catch (e) {
      print("Hata: $e");
    }
  }
}