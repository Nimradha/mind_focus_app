import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/permission_service.dart';

class AlarmTab extends StatefulWidget {
  const AlarmTab({super.key});

  @override
  State<AlarmTab> createState() => _AlarmTabState();
}

class _AlarmTabState extends State<AlarmTab> {
  // Your list of alarms (Loaded from SharedPreferences, fallback to defaults)
  List<Map<String, dynamic>> alarms = [
    {'id': 1, 'time': '00:00', 'label': 'Tue, 24 Mar', 'isActive': false},
    {'id': 2, 'time': '05:30', 'label': 'Tue, 24 Mar', 'isActive': false},
    {'id': 3, 'time': '06:00', 'label': 'M T W T F S S', 'isActive': false},
  ];

  String _getTimeRemaining(DateTime alarmTime) {
    final now = DateTime.now();
    final difference = alarmTime.difference(now);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} from now";
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return "$hours hour${hours == 1 ? '' : 's'} and $minutes minute${minutes == 1 ? '' : 's'} from now";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedAlarms();
  }

  Future<void> _loadSavedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('user_alarms');
    if (savedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedJson);
        setState(() {
          alarms = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      } catch (e) {
        debugPrint("Error loading alarms: $e");
      }
    }
    _syncAlarmsWithSystem();
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_alarms', jsonEncode(alarms));
  }

  void _syncAlarmsWithSystem() {
    final activeAlarms = Alarm.getAlarms();
    final activeIds = activeAlarms.map((a) => a.id).toSet();
    bool changed = false;
    for (var alarm in alarms) {
      bool isCurrentlyActive = activeIds.contains(alarm['id']);
      if (alarm['isActive'] != isCurrentlyActive) {
        alarm['isActive'] = isCurrentlyActive;
        changed = true;
      }
    }
    if (changed) {
      _saveAlarms();
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncAlarmsWithSystem();
    // Logic to update the header text based on active switches
    bool anyActive = alarms.any((alarm) => alarm['isActive'] == true);
    String headerText = anyActive ? "Alarms are active" : "All alarms are off";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          headerText,
          style: GoogleFonts.ebGaramond(
            color: Colors.green,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green, size: 28),
            onPressed: () => _pickTime(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.green),
            onSelected: (value) {
              if (value == 'Sort') {
                _showSortOptions(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$value clicked")));
              }
            },
            itemBuilder: (BuildContext context) {
              return const [
                PopupMenuItem<String>(value: 'Edit', child: Text('Edit')),
                PopupMenuItem<String>(value: 'Sort', child: Text('Sort')),
                PopupMenuItem<String>(value: 'Settings', child: Text('Settings')),
              ];
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return _buildAlarmCard(alarm, index);
        },
      ),
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm, int index) {
    bool isActive = alarm['isActive'];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: Colors.green.shade100) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
             onTap: () => _pickTime(context, index: index), // PASS THE INDEX HERE
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm['time'],
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: isActive
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                     alarm['label'],
                     style: TextStyle(
                       color: isActive ? Colors.grey.shade600 : Colors.grey.shade400,
                       fontSize: 14,
                     ),
                  ),
                ],
             ),
          ),
          Switch(
            value: isActive,
            activeColor: Colors.white,
            activeTrackColor: Colors.green,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: (bool value) async{
              setState(() {
                alarms[index]['isActive'] = value;
              });
              _saveAlarms();
              if (value) {
                await PermissionService.checkAndRequestOverlayPermission(context);
                if (!mounted) return;
                // 2. Logic to turn the string "05:30" into a real time
                final now = DateTime.now();
                final timeParts = alarm['time'].split(':');
                int hour = int.parse(timeParts[0]);
                int minute = int.parse(timeParts[1]);

                DateTime alarmTime = DateTime(
                    now.year, now.month, now.day,
                    hour, minute
                );

                // 3. If the time already passed today, set it for tomorrow
                if (alarmTime.isBefore(now)) {
                  alarmTime = alarmTime.add(const Duration(days: 1));
                }

                String message = _getTimeRemaining(alarmTime);
                ScaffoldMessenger.of(context).clearSnackBars(); // Clear old ones first
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Alarm set for $message"),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                final settings = AlarmSettings(
                  id: alarm['id'], // Uses the ID from your list
                  dateTime: alarmTime,
                  assetAudioPath: 'assets/audio/SlowMorning.mp3',
                  loopAudio: true,
                  vibrate: true,
                  volume: 0.8,
                  notificationTitle: 'MindGym Alert',
                  notificationBody: 'Time for your focus session!',
                  enableNotificationOnKill: true,
                  androidFullScreenIntent: true,
                );

                // 4. Actually schedule the alarm in the system
                await Alarm.set(alarmSettings: settings);
              } else {
                // 5. If toggled off, cancel the alarm in the system
                await Alarm.stop(alarm['id']);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, {int? index}) async {

    TimeOfDay initialTime = TimeOfDay.now();
    if (index != null) {
      final timeParts = alarms[index]['time'].split(':');
      initialTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }

    await PermissionService.checkAndRequestOverlayPermission(context);
    if (!context.mounted) return;

    final res = await showTimePicker(context: context, initialTime: initialTime);
    if (res != null) {
      final now = DateTime.now();
      DateTime alarmTime = DateTime(now.year, now.month, now.day, res.hour, res.minute);
      if (alarmTime.isBefore(now)) alarmTime = alarmTime.add(const Duration(days: 1));

      // Formatting the time for the UI list
      String formattedTime = "${res.hour.toString().padLeft(2, '0')}:${res.minute.toString().padLeft(2, '0')}";
      String formattedDate = DateFormat('EEE, d MMM').format(alarmTime);

      int id = index != null ? alarms[index]['id'] : DateTime.now().millisecondsSinceEpoch % 10000;

      final settings = AlarmSettings(
        id: id,
        dateTime: alarmTime,
        assetAudioPath: 'assets/audio/SlowMorning.mp3',
        notificationTitle: 'MindGym Alert',
        notificationBody: 'Time for your session!',
        loopAudio: true,
        vibrate: true,
        volume: 0.8,
        enableNotificationOnKill: true,
        androidFullScreenIntent: true,
      );

      await Alarm.set(alarmSettings: settings);

      setState(() {
        if (index != null) {
          // UPDATE EXISTING ALARM
          alarms[index]['time'] = formattedTime;
          alarms[index]['label'] = formattedDate;
          alarms[index]['isActive'] = true;
        } else {
          // ADD NEW ALARM
          alarms.add({
            'id': settings.id,
            'time': formattedTime,
            'label': formattedDate,
            'isActive': true,
          });
        }
      });
      _saveAlarms();

      // 2. Show the specific message
      ScaffoldMessenger.of(context).clearSnackBars(); // Optional: clears any existing bars first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Alarm set for ${_getTimeRemaining(alarmTime)}"),
          behavior: SnackBarBehavior.floating, // Makes it look modern like your UI
          backgroundColor: Colors.green,       // Matches your MindGym theme
        ),
      );
    }
  }

  void _showSortOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sort Alarms'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.green),
                title: const Text('Alarm time order'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    alarms.sort((a, b) {
                      return a['time'].toString().compareTo(b['time'].toString());
                    });
                  });
                  _saveAlarms();
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_list_bulleted, color: Colors.green),
                title: const Text('Custom order'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Custom order selected'),
                      backgroundColor: Colors.green,
                    )
                  );
                },
              ),
            ],
          ),
        );
      }
    );
  }
}