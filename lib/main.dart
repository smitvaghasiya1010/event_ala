import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ALA3App());
}

// ─────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────
const kPrimary   = Color(0xFF6C63FF);
const kAccent    = Color(0xFF00BFA6);
const kBg        = Color(0xFFF5F6FA);
const kCard      = Colors.white;
const kText      = Color(0xFF1A1A2E);
const kSubText   = Color(0xFF888888);
const kRed       = Color(0xFFFF5252);

const kCats      = ['Meeting','Birthday','Reminder','Appointment','Trip','Party','Other','Work'];
const kCatColors = [
  Color(0xFF6C63FF), Color(0xFFFF6B8A), Color(0xFFFFAA00),
  Color(0xFF00BFA6), Color(0xFF2196F3), Color(0xFFE91E63),
  Color(0xFF9E9E9E), Color(0xFF4CAF50),
];
const kCatIcons  = [
  Icons.groups, Icons.cake, Icons.notifications,
  Icons.local_hospital, Icons.flight, Icons.celebration,
  Icons.bookmark, Icons.work,
];

// ─────────────────────────────────────────
//  EVENT MODEL
// ─────────────────────────────────────────
class Event {
  final String id;
  String title, description, location, category;
  DateTime date;
  TimeOfDay time;

  Event({
    required this.id, required this.title, required this.description,
    required this.location, required this.category,
    required this.date, required this.time,
  });

  bool get isToday {
    final n = DateTime.now();
    return date.year == n.year && date.month == n.month && date.day == n.day;
  }

  bool get isUpcoming =>
      date.isAfter(DateTime.now().subtract(const Duration(hours: 1)));

  Color get color {
    final i = kCats.indexOf(category);
    return kCatColors[i < 0 ? 0 : i % kCatColors.length];
  }

  IconData get icon {
    final i = kCats.indexOf(category);
    return kCatIcons[i < 0 ? 0 : i % kCatIcons.length];
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description,
    'location': location, 'category': category,
    'date': date.toIso8601String(),
    'th': time.hour, 'tm': time.minute,
  };

  factory Event.fromJson(Map<String, dynamic> j) => Event(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    location: j['location'] ?? '',
    category: j['category'] ?? 'Other',
    date: DateTime.parse(j['date']),
    time: TimeOfDay(hour: j['th'] ?? 9, minute: j['tm'] ?? 0),
  );
}

// ─────────────────────────────────────────
//  STORAGE
// ─────────────────────────────────────────
class Store {
  static const _eKey = 'v1_events';
  static const _nKey = 'v1_name';

  static Future<List<Event>> loadEvents() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_eKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Event.fromJson(e)).toList();
  }

  static Future<void> saveEvents(List<Event> events) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_eKey, jsonEncode(events.map((e) => e.toJson()).toList()));
  }

  static Future<String> loadName() async =>
      (await SharedPreferences.getInstance()).getString(_nKey) ?? 'Smit';

  static Future<void> saveName(String n) async =>
      (await SharedPreferences.getInstance()).setString(_nKey, n);
}

// ─────────────────────────────────────────
//  APP ROOT
// ─────────────────────────────────────────
class ALA3App extends StatefulWidget {
  const ALA3App({super.key});
  @override
  State<ALA3App> createState() => _ALA3AppState();
}

class _ALA3AppState extends State<ALA3App> {
  List<Event> _events = [];
  String _name = 'Smit';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name   = await Store.loadName();
    _events = await Store.loadEvents();
    if (_events.isEmpty) _events = _seed();
    setState(() => _ready = true);
  }

  List<Event> _seed() {
    final n = DateTime.now();
    return [
      Event(id: '1', title: 'Team Sprint Review',  description: 'Q4 sprint review.',         location: 'Conference Room A',  category: 'Meeting',     date: n.add(const Duration(days: 1)), time: const TimeOfDay(hour: 10, minute: 0)),
      Event(id: '2', title: "Riya's Birthday",      description: 'Birthday dinner.',           location: 'The Grand Hotel',    category: 'Birthday',    date: n.add(const Duration(days: 3)), time: const TimeOfDay(hour: 19, minute: 30)),
      Event(id: '3', title: 'Goa Trip',             description: 'Team outing to Goa.',        location: 'Airport Terminal 1', category: 'Trip',        date: n.add(const Duration(days: 7)), time: const TimeOfDay(hour: 6,  minute: 0)),
      Event(id: '4', title: 'Doctor Appointment',   description: 'Routine health checkup.',    location: 'City Hospital',      category: 'Appointment', date: n.add(const Duration(days: 2)), time: const TimeOfDay(hour: 11, minute: 0)),
      Event(id: '5', title: 'InnoApp 2025 Demo',    description: 'Final demo for InnoApp.',    location: 'RK University',      category: 'Work',        date: n,                              time: const TimeOfDay(hour: 14, minute: 0)),
    ];
  }

  void _setEvents(List<Event> v) { setState(() => _events = v); Store.saveEvents(v); }
  void _setName(String v)        { setState(() => _name = v);   Store.saveName(v); }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: kBg,
          body: const Center(child: CircularProgressIndicator(color: kPrimary)),
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ALA-3 Event Planner',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: kBg,
        primaryColor: kPrimary,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: const ColorScheme.light(primary: kPrimary, secondary: kAccent),
      ),
      home: RootScreen(
        events: _events, name: _name,
        onEvents: _setEvents, onName: _setName,
      ),
    );
  }
}

// ─────────────────────────────────────────
//  ROOT SCREEN
// ─────────────────────────────────────────
class RootScreen extends StatefulWidget {
  final List<Event> events;
  final String name;
  final ValueChanged<List<Event>> onEvents;
  final ValueChanged<String> onName;

  const RootScreen({super.key,
    required this.events, required this.name,
    required this.onEvents, required this.onName});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _tab = 0;

  void _openAdd() async {
    final e = await Navigator.push<Event>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditScreen()),
    );
    if (e != null) widget.onEvents([...widget.events, e]);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(events: widget.events, name: widget.name, onEvents: widget.onEvents),
      ProfileScreen(events: widget.events, name: widget.name, onName: widget.onName),
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: screens[_tab],
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(children: [
            Expanded(child: InkWell(
              onTap: () => setState(() => _tab = 0),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.home_rounded,
                    color: _tab == 0 ? kPrimary : kSubText, size: 26),
                Text('Home', style: TextStyle(
                    fontSize: 11,
                    color: _tab == 0 ? kPrimary : kSubText,
                    fontWeight: _tab == 0 ? FontWeight.w700 : FontWeight.w400)),
              ]),
            )),
            const SizedBox(width: 60), // FAB notch space
            Expanded(child: InkWell(
              onTap: () => setState(() => _tab = 1),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.person_rounded,
                    color: _tab == 1 ? kPrimary : kSubText, size: 26),
                Text('Profile', style: TextStyle(
                    fontSize: 11,
                    color: _tab == 1 ? kPrimary : kSubText,
                    fontWeight: _tab == 1 ? FontWeight.w700 : FontWeight.w400)),
              ]),
            )),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final List<Event> events;
  final String name;
  final ValueChanged<List<Event>> onEvents;

  const HomeScreen({super.key,
    required this.events, required this.name, required this.onEvents});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _q = '';

  List<Event> get _filtered => _q.isEmpty
      ? widget.events
      : widget.events.where((e) =>
  e.title.toLowerCase().contains(_q.toLowerCase()) ||
      e.location.toLowerCase().contains(_q.toLowerCase()) ||
      e.category.toLowerCase().contains(_q.toLowerCase())).toList();

  List<Event> get _today    => _filtered.where((e) => e.isToday).toList();
  List<Event> get _upcoming => _filtered.where((e) => e.isUpcoming && !e.isToday).toList();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _delete(String id) =>
      widget.onEvents(widget.events.where((e) => e.id != id).toList());

  void _edit(Event ev) async {
    final result = await Navigator.push<Event>(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(event: ev)),
    );
    if (result != null) {
      widget.onEvents(widget.events.map((e) => e.id == result.id ? result : e).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, top + 16, 16, 120),
      children: [

        // ── HEADER
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_greeting, style: const TextStyle(fontSize: 13, color: kSubText)),
            const SizedBox(height: 2),
            Text(widget.name,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
          ])),
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: kPrimary, size: 24),
          ),
        ]),
        const SizedBox(height: 18),

        // ── SEARCH
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.20)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: kSubText, size: 20),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              onChanged: (v) => setState(() => _q = v),
              style: const TextStyle(fontSize: 14, color: kText),
              decoration: const InputDecoration(
                hintText: 'Search events...',
                hintStyle: TextStyle(color: kSubText, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            )),
          ]),
        ),
        const SizedBox(height: 18),

        // ── STAT CHIPS
        Row(children: [
          _StatChip(
            label: 'Upcoming',
            value: '${widget.events.where((e) => e.isUpcoming).length}',
            color: kPrimary,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Today',
            value: '${widget.events.where((e) => e.isToday).length}',
            color: kAccent,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Total',
            value: '${widget.events.length}',
            color: const Color(0xFFFF6B8A),
          ),
        ]),
        const SizedBox(height: 22),

        // ── TODAY
        if (_today.isNotEmpty) ...[
          _SectionTitle(title: "Today's Events", icon: Icons.today_rounded),
          const SizedBox(height: 10),
          ..._today.map((e) => _EventCard(event: e, onDelete: _delete, onEdit: _edit)),
          const SizedBox(height: 10),
        ],

        // ── UPCOMING
        _SectionTitle(title: 'Upcoming Events', icon: Icons.schedule_rounded),
        const SizedBox(height: 10),
        if (_upcoming.isEmpty)
          _EmptyState()
        else
          ..._upcoming.map((e) => _EventCard(event: e, onDelete: _delete, onEdit: _edit)),
      ],
    );
  }
}

// ─────────────────────────────────────────
//  STAT CHIP
// ─────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kSubText, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────
//  SECTION TITLE
// ─────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: kPrimary, size: 18),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
  ]);
}

// ─────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Column(children: [
      Icon(Icons.event_note_rounded, color: kSubText.withOpacity(0.4), size: 48),
      const SizedBox(height: 10),
      const Text('No upcoming events', style: TextStyle(fontSize: 15, color: kSubText)),
      const SizedBox(height: 4),
      const Text('Tap + to add one', style: TextStyle(fontSize: 12, color: kSubText)),
    ]),
  );
}

// ─────────────────────────────────────────
//  EVENT CARD
// ─────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final Event event;
  final ValueChanged<String> onDelete;
  final ValueChanged<Event> onEdit;
  const _EventCard({required this.event, required this.onDelete, required this.onEdit});

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final mn = t.minute.toString().padLeft(2, '0');
    return '$h:$mn ${t.hour < 12 ? "AM" : "PM"}';
  }

  void _confirmDelete(BuildContext context) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Event', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Delete "${event.title}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kSubText))),
        TextButton(
            onPressed: () { Navigator.pop(context); onDelete(event.id); },
            child: const Text('Delete', style: TextStyle(color: kRed, fontWeight: FontWeight.w700))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _DetailSheet(event: event),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: event.color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(event.icon, color: event.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
            const SizedBox(height: 4),
            Text('${_fmtDate(event.date)}  ·  ${_fmtTime(event.time)}',
                style: const TextStyle(fontSize: 12, color: kSubText)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.location_on, size: 12, color: event.color),
              const SizedBox(width: 3),
              Expanded(child: Text(event.location,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: event.color, fontWeight: FontWeight.w500))),
            ]),
          ])),
          Column(children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: kSubText),
              onPressed: () => onEdit(event),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: kRed),
              onPressed: () => _confirmDelete(context),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  DETAIL BOTTOM SHEET
// ─────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final Event event;
  const _DetailSheet({required this.event});

  String _fmtDate(DateTime d) {
    const m = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    const wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${wd[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? "AM" : "PM"}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: event.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(event.icon, color: event.color, size: 30),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: event.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(event.category,
              style: TextStyle(color: event.color, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(event.title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            _DRow(icon: Icons.calendar_today, text: _fmtDate(event.date), color: event.color),
            _DRow(icon: Icons.access_time, text: _fmtTime(event.time), color: event.color),
            _DRow(icon: Icons.location_on, text: event.location, color: event.color),
            if (event.description.isNotEmpty)
              _DRow(icon: Icons.notes, text: event.description, color: event.color),
          ]),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _DRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _DRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 14, color: kText))),
    ]),
  );
}

// ─────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  final List<Event> events;
  final String name;
  final ValueChanged<String> onName;

  const ProfileScreen({super.key,
    required this.events, required this.name, required this.onName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.name);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final top      = MediaQuery.of(context).padding.top;
    final upcoming = widget.events.where((e) => e.isUpcoming).length;
    final total    = widget.events.length;
    final past     = total - upcoming;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, top + 16, 16, 100),
      children: [

        // ── HEADER
        const Text('Profile',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
        const SizedBox(height: 20),

        // ── AVATAR CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white.withOpacity(0.25),
              child: Text(
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Event Planner · ALA-3',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // ── STATS ROW
        Row(children: [
          _InfoBox(value: '$total',    label: 'Total',    color: kPrimary),
          const SizedBox(width: 10),
          _InfoBox(value: '$upcoming', label: 'Upcoming', color: kAccent),
          const SizedBox(width: 10),
          _InfoBox(value: '$past',     label: 'Past',     color: const Color(0xFFFF6B8A)),
        ]),
        const SizedBox(height: 20),

        // ── CALENDAR
        const Text('MY CALENDAR',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: kSubText)),
        const SizedBox(height: 10),
        _SimpleCalendar(events: widget.events),
        const SizedBox(height: 20),

        // ── ACCOUNT SETTINGS
        const Text('ACCOUNT',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: kSubText)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Column(children: [
            _SettingRow(
              icon: Icons.person_outline,
              label: 'Display Name',
              trailing: SizedBox(
                width: 140,
                child: TextField(
                  controller: _ctrl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true,
                      contentPadding: EdgeInsets.zero),
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            _SettingRow(
              icon: Icons.lock_outline,
              label: 'Storage',
              trailing: const Text('Local Only',
                  style: TextStyle(fontSize: 12, color: kAccent, fontWeight: FontWeight.w600)),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onName(_ctrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── APP INFO
        const Text('ABOUT',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: kSubText)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Column(children: [
            _SettingRow(icon: Icons.info_outline, label: 'Version',
                trailing: const Text('v1.0.0', style: TextStyle(fontSize: 12, color: kSubText))),
            Divider(height: 1, color: Colors.grey.shade100),
            _SettingRow(icon: Icons.code, label: 'Built With',
                trailing: const Text('Flutter', style: TextStyle(fontSize: 12, color: kSubText))),
          ]),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String value, label;
  final Color color;
  const _InfoBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: kSubText)),
      ]),
    ),
  );
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  const _SettingRow({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(children: [
      Icon(icon, size: 20, color: kPrimary),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
      const Spacer(),
      if (trailing != null) trailing!,
    ]),
  );
}

// ─────────────────────────────────────────
//  SIMPLE CALENDAR WIDGET (in Profile)
// ─────────────────────────────────────────
class _SimpleCalendar extends StatefulWidget {
  final List<Event> events;
  const _SimpleCalendar({required this.events});

  @override
  State<_SimpleCalendar> createState() => _SimpleCalendarState();
}

class _SimpleCalendarState extends State<_SimpleCalendar> {
  DateTime _focus    = DateTime.now();
  DateTime? _selected;

  void _prev() => setState(() {
    _focus = DateTime(_focus.year, _focus.month - 1);
    _selected = null;
  });

  void _next() => setState(() {
    _focus = DateTime(_focus.year, _focus.month + 1);
    _selected = null;
  });

  Set<int> get _dotDays => widget.events
      .where((e) => e.date.year == _focus.year && e.date.month == _focus.month)
      .map((e) => e.date.day).toSet();

  List<Event> get _selEvents => _selected == null ? [] : widget.events.where((e) =>
  e.date.year == _selected!.year &&
      e.date.month == _selected!.month &&
      e.date.day == _selected!.day).toList();

  @override
  Widget build(BuildContext context) {
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    final first       = DateTime(_focus.year, _focus.month, 1);
    final daysInMonth = DateTime(_focus.year, _focus.month + 1, 0).day;
    final offset      = first.weekday % 7;
    final dots        = _dotDays;
    final selEvents   = _selEvents;
    final now         = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        // Month nav
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Row(children: [
            Text('${months[_focus.month - 1]} ${_focus.year}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
            const Spacer(),
            IconButton(onPressed: _prev, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                icon: const Icon(Icons.chevron_left, color: kSubText, size: 22)),
            const SizedBox(width: 4),
            IconButton(onPressed: _next, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                icon: const Icon(Icons.chevron_right, color: kSubText, size: 22)),
            const SizedBox(width: 4),
          ]),
        ),

        // Weekday labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['S','M','T','W','T','F','S'].map((d) => Expanded(
              child: Center(child: Text(d,
                  style: const TextStyle(fontSize: 11, color: kSubText, fontWeight: FontWeight.w700))),
            )).toList(),
          ),
        ),
        const SizedBox(height: 6),

        // Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 1.0, mainAxisSpacing: 4, crossAxisSpacing: 4),
            itemCount: offset + daysInMonth,
            itemBuilder: (_, i) {
              if (i < offset) return const SizedBox();
              final day   = i - offset + 1;
              final date  = DateTime(_focus.year, _focus.month, day);
              final hasDot = dots.contains(day);
              final isSel  = _selected != null &&
                  _selected!.day == day &&
                  _selected!.month == _focus.month &&
                  _selected!.year == _focus.year;
              final isToday = date.day == now.day &&
                  date.month == now.month && date.year == now.year;

              return GestureDetector(
                onTap: () => setState(() => _selected = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSel ? kPrimary : (isToday ? kPrimary.withOpacity(0.12) : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSel ? Border.all(color: kPrimary, width: 1.5) : null,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$day', style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday || isSel ? FontWeight.w800 : FontWeight.w500,
                        color: isSel ? Colors.white : kText)),
                    if (hasDot)
                      Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel ? Colors.white : kAccent)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Selected events
        if (_selected != null) ...[
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    '${_selected!.day} ${["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][_selected!.month - 1]}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kText),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('${selEvents.length} event${selEvents.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 8),
                if (selEvents.isEmpty)
                  const Text('No events this day.',
                      style: TextStyle(fontSize: 12, color: kSubText))
                else
                  ...selEvents.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(width: 32, height: 32,
                          decoration: BoxDecoration(
                              color: e.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(9)),
                          child: Icon(e.icon, color: e.color, size: 16)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.title, style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13, color: kText)),
                        Text(e.location, style: const TextStyle(fontSize: 11, color: kSubText)),
                      ])),
                    ]),
                  )),
              ],
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.touch_app_outlined, size: 14, color: kSubText),
              SizedBox(width: 5),
              Text('Tap a date to see events', style: TextStyle(fontSize: 12, color: kSubText)),
            ]),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
//  ADD / EDIT SCREEN
// ─────────────────────────────────────────
class AddEditScreen extends StatefulWidget {
  final Event? event;
  const AddEditScreen({super.key, this.event});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _fKey = GlobalKey<FormState>();
  late TextEditingController _title, _desc, _loc;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  String _cat = 'Meeting';

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _title = TextEditingController(text: e?.title ?? '');
    _desc  = TextEditingController(text: e?.description ?? '');
    _loc   = TextEditingController(text: e?.location ?? '');
    if (e != null) { _date = e.date; _time = e.time; _cat = e.category; }
  }

  @override
  void dispose() { _title.dispose(); _desc.dispose(); _loc.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
        child: child!,
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? "AM" : "PM"}';
  }

  void _save() {
    if (!_fKey.currentState!.validate()) return;
    final e = Event(
      id: _isEdit ? widget.event!.id : '${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      description: _desc.text.trim(),
      location: _loc.text.trim(),
      category: _cat,
      date: _date,
      time: _time,
    );
    Navigator.pop(context, e);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: kBg,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, top + 12, 16, 40),
        children: [
          // Top bar
          Row(children: [
            IconButton(
              icon: const Icon(Icons.close, color: kText),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 10),
            Text(_isEdit ? 'Edit Event' : 'New Event',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
          ]),
          const SizedBox(height: 20),

          Form(key: _fKey, child: Column(children: [

            // Category chips
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: kCats.length,
                itemBuilder: (_, i) {
                  final sel = kCats[i] == _cat;
                  return GestureDetector(
                    onTap: () => setState(() => _cat = kCats[i]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? kCatColors[i] : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: sel ? kCatColors[i] : Colors.grey.shade300),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(kCatIcons[i],
                            color: sel ? Colors.white : kSubText, size: 14),
                        const SizedBox(width: 6),
                        Text(kCats[i], style: TextStyle(
                            color: sel ? Colors.white : kSubText,
                            fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Fields card
            _FormCard(children: [
              _FormField(ctrl: _title, label: 'Event Title', hint: 'e.g. Team Meeting',
                  icon: Icons.title,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null),
              _Divider(),
              _FormField(ctrl: _desc, label: 'Description', hint: 'What is this event?',
                  icon: Icons.notes, maxLines: 2),
            ]),
            const SizedBox(height: 12),

            // Date & Time
            _FormCard(children: [
              _PickerRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: _fmtDate(_date),
                onTap: _pickDate,
              ),
              _Divider(),
              _PickerRow(
                icon: Icons.access_time,
                label: 'Time',
                value: _fmtTime(_time),
                onTap: _pickTime,
              ),
            ]),
            const SizedBox(height: 12),

            // Location
            _FormCard(children: [
              _FormField(ctrl: _loc, label: 'Location', hint: 'Venue or address',
                  icon: Icons.location_on,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a location' : null),
            ]),
            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(_isEdit ? 'Update Event' : 'Save Event',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: kSubText)),
            ),
          ])),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(children: children),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;
  const _FormField({required this.ctrl, required this.label, required this.hint,
    required this.icon, this.maxLines = 1, this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    validator: validator,
    maxLines: maxLines,
    style: const TextStyle(fontSize: 14, color: kText),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: kSubText, fontSize: 13),
      labelStyle: const TextStyle(color: kSubText, fontSize: 13),
      prefixIcon: Icon(icon, color: kPrimary, size: 20),
      border: InputBorder.none,
      errorStyle: const TextStyle(color: kRed, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
    ),
  );
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  const _PickerRow({required this.icon, required this.label,
    required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Icon(icon, color: kPrimary, size: 20),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: kSubText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
        ]),
        const Spacer(),
        const Icon(Icons.chevron_right, color: kSubText, size: 20),
      ]),
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.grey.shade100);
}