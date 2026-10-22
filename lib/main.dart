import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

const Color kGreen = Color(0xFF126B50);
const Color kDeepGreen = Color(0xFF0A3F32);
const Color kGold = Color(0xFFD7B46A);
const Color kCanvas = Color(0xFFF6F7F2);

void main() => runApp(const NoorQuranApp());

class NoorQuranApp extends StatefulWidget {
  const NoorQuranApp({super.key});
  @override
  State<NoorQuranApp> createState() => _NoorQuranAppState();
}

class _NoorQuranAppState extends State<NoorQuranApp> {
  bool darkMode = false;
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kGreen,
      brightness: darkMode ? Brightness.dark : Brightness.light,
      primary: kGreen,
      secondary: kGold,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نور القرآن الكريم',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: darkMode ? const Color(0xFF101A17) : kCanvas,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 0,
          color: darkMode ? const Color(0xFF1A2924) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          margin: EdgeInsets.zero,
        ),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MainShell(
          darkMode: darkMode,
          onThemeChanged: (value) => setState(() => darkMode = value),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;
  const MainShell({super.key, required this.darkMode, required this.onThemeChanged});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;
  final QuranRepository repo = QuranRepository();
  final Set<int> favorites = {};
  int tasbihCount = 0;
  int khatmaPage = 0;
  bool loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      favorites.addAll((p.getStringList('favorites') ?? []).map(int.tryParse).whereType<int>());
      tasbihCount = p.getInt('tasbih_count') ?? 0;
      khatmaPage = p.getInt('khatma_page') ?? 0;
      loadingPrefs = false;
    });
  }

  Future<void> _saveFavorites() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('favorites', favorites.map((e) => e.toString()).toList());
  }

  Future<void> _toggleFavorite(int number) async {
    setState(() => favorites.contains(number) ? favorites.remove(number) : favorites.add(number));
    await _saveFavorites();
  }

  Future<void> _saveTasbih() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('tasbih_count', tasbihCount);
  }

  Future<void> _saveKhatma() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('khatma_page', khatmaPage);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onOpenQuran: () => setState(() => selectedIndex = 1),
        onOpenAdhkar: () => setState(() => selectedIndex = 2),
        khatmaPage: khatmaPage),
      QuranPage(repo: repo, favorites: favorites, onFavorite: _toggleFavorite),
      AdhkarPage(),
      TasbihPage(count: tasbihCount, onCountChanged: (v) { setState(() => tasbihCount = v); _saveTasbih(); }),
      MorePage(
        darkMode: widget.darkMode,
        onThemeChanged: widget.onThemeChanged,
        khatmaPage: khatmaPage,
        onKhatmaChanged: (v) { setState(() => khatmaPage = v); _saveKhatma(); },
        favoritesCount: favorites.length,
      ),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: selectedIndex, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (v) => setState(() => selectedIndex = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.menu_book_rounded), label: 'القرآن'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_rounded), label: 'الأذكار'),
          NavigationDestination(icon: Icon(Icons.radio_button_checked_rounded), label: 'المسبحة'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'المزيد'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback onOpenQuran;
  final VoidCallback onOpenAdhkar;
  final int khatmaPage;
  const HomePage({super.key, required this.onOpenQuran, required this.onOpenAdhkar, required this.khatmaPage});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kGreen, kDeepGreen]),
            borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 27)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('نور القرآن', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text('رفيقك اليومي مع كتاب الله', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ])),
          IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يمكنك متابعة القراءة والأذكار من القائمة السفلية.'))),
            icon: const Icon(Icons.notifications_none_rounded)),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [kGreen, kDeepGreen]),
            boxShadow: [BoxShadow(color: kGreen.withOpacity(.18), blurRadius: 24, offset: const Offset(0, 12))],
          ),
          child: Stack(children: [
            const Positioned(left: -6, bottom: -20, child: Icon(Icons.auto_awesome, color: Color(0x33FFFFFF), size: 100)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(20)),
                child: const Text('وَرْدُكَ اليومي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              const SizedBox(height: 18),
              const Text('وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ',
                style: TextStyle(color: Colors.white, fontSize: 23, height: 1.9, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('سورة القمر · 17', style: TextStyle(color: Colors.white.withOpacity(.75))),
              const SizedBox(height: 22),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: kDeepGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                onPressed: onOpenQuran, icon: const Icon(Icons.menu_book_rounded),
                label: const Text('ابدأ القراءة', style: TextStyle(fontWeight: FontWeight.bold))),
            ]),
          ]),
        ),
        const SizedBox(height: 22),
        const SectionHeading(title: 'مساحتك اليومية', subtitle: 'خطوات صغيرة تصنع أثرًا كبيرًا'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: StatCard(icon: Icons.bookmark_added_rounded, title: 'تقدّم الختمة',
            value: '$khatmaPage / 604', color: kGreen)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(icon: Icons.favorite_rounded, title: 'السكينة', value: 'بذكر الله', color: const Color(0xFFB47C46))),
        ]),
        const SizedBox(height: 22),
        const SectionHeading(title: 'اختصارات سريعة', subtitle: 'اختر ما تحتاجه الآن'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: QuickAction(icon: Icons.menu_book_rounded, label: 'القرآن الكريم', onTap: onOpenQuran)),
          const SizedBox(width: 10),
          Expanded(child: QuickAction(icon: Icons.volunteer_activism_rounded, label: 'الأذكار', onTap: onOpenAdhkar)),
        ]),
        const SizedBox(height: 22),
        Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            const Icon(Icons.lightbulb_outline_rounded, color: kGold, size: 30),
            const SizedBox(width: 12),
            const Expanded(child: Text('اجعل لك وردًا ثابتًا، ولو آيات قليلة كل يوم.', style: TextStyle(height: 1.7))),
          ])),
      ],
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title, subtitle;
  const SectionHeading({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ])),
  ]);
}

class StatCard extends StatelessWidget {
  final IconData icon; final String title, value; final Color color;
  const StatCard({super.key, required this.icon, required this.title, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(22)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 25), const SizedBox(height: 13),
      Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 5), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
    ]));
}

class QuickAction extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const QuickAction({super.key, required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20),
    child: Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [Icon(icon, color: kGreen, size: 30), const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700))])));
}

class QuranRepository {
  static const base = 'https://api.alquran.cloud/v1';
  Future<List<Surah>> getSurahs() async {
    final response = await http.get(Uri.parse('$base/surah')).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('تعذر تحميل فهرس السور (${response.statusCode})');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['data'] as List).map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
  }
  Future<List<Ayah>> getAyahs(int number) async {
    final response = await http.get(Uri.parse('$base/surah/$number/quran-uthmani')).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) throw Exception('تعذر تحميل الآيات (${response.statusCode})');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['data']['ayahs'] as List).map((e) => Ayah.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class Surah {
  final int number, ayahs;
  final String name, englishName, revelationType;
  Surah({required this.number, required this.ayahs, required this.name, required this.englishName, required this.revelationType});
  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
    number: j['number'] as int, ayahs: j['numberOfAyahs'] as int,
    name: j['name'] as String, englishName: j['englishName'] as String,
    revelationType: j['revelationType'] as String);
}

class Ayah {
  final int number, numberInSurah;
  final String text;
  Ayah({required this.number, required this.numberInSurah, required this.text});
  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
    number: j['number'] as int, numberInSurah: j['numberInSurah'] as int, text: j['text'] as String);
}

class QuranPage extends StatefulWidget {
  final QuranRepository repo; final Set<int> favorites; final Future<void> Function(int) onFavorite;
  const QuranPage({super.key, required this.repo, required this.favorites, required this.onFavorite});
  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  late Future<List<Surah>> future;
  final search = TextEditingController();
  String query = '';
  @override
  void initState() { super.initState(); future = widget.repo.getSurahs(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('القرآن الكريم', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), const Text('اقرأ وتدبّر وواصل وردك', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 16),
      TextField(controller: search, onChanged: (v) => setState(() => query = v),
        decoration: InputDecoration(hintText: 'ابحث عن سورة...', prefixIcon: const Icon(Icons.search),
          filled: true, fillColor: Theme.of(context).cardTheme.color,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
    ])),
    Expanded(child: FutureBuilder<List<Surah>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() => future = widget.repo.getSurahs()));
      final surahs = snapshot.data!.where((s) => s.name.contains(query) || s.englishName.toLowerCase().contains(query.toLowerCase()) || '${s.number}'.contains(query)).toList();
      return RefreshIndicator(onRefresh: () async { setState(() => future = widget.repo.getSurahs()); await future; },
        child: ListView.separated(padding: const EdgeInsets.fromLTRB(20, 2, 20, 20), itemCount: surahs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final s = surahs[index];
            return Card(child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(width: 44, height: 44, alignment: Alignment.center,
                decoration: BoxDecoration(color: kGreen.withOpacity(.09), borderRadius: BorderRadius.circular(14)),
                child: Text('${s.number}', style: const TextStyle(color: kGreen, fontWeight: FontWeight.w800))),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              subtitle: Text('${s.revelationType == 'Meccan' ? 'مكية' : 'مدنية'} · ${s.ayahs} آية'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderPage(surah: s, repo: widget.repo, favorites: widget.favorites, onFavorite: widget.onFavorite))),
            ));
          }));
    })),
  ]);
}

class ReaderPage extends StatefulWidget {
  final Surah surah; final QuranRepository repo; final Set<int> favorites; final Future<void> Function(int) onFavorite;
  const ReaderPage({super.key, required this.surah, required this.repo, required this.favorites, required this.onFavorite});
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late Future<List<Ayah>> future;
  final AudioPlayer player = AudioPlayer();
  int? playingAyah;
  bool audioLoading = false;
  @override
  void initState() { super.initState(); future = widget.repo.getAyahs(widget.surah.number); }
  @override
  void dispose() { player.dispose(); super.dispose(); }

  Future<void> playAyah(Ayah ayah) async {
    setState(() { audioLoading = true; playingAyah = ayah.numberInSurah; });
    try {
      // The Quran audio endpoint provides recitation for the global ayah number.
      await player.setUrl('https://cdn.islamic.network/quran/audio/128/ar.alafasy/${ayah.number}.mp3');
      await player.play();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تشغيل التلاوة. تحقق من الإنترنت.')));
    } finally { if (mounted) setState(() => audioLoading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.surah.name), actions: [
      IconButton(tooltip: 'إيقاف التلاوة', onPressed: () async { await player.stop(); if (mounted) setState(() => playingAyah = null); }, icon: const Icon(Icons.stop_circle_outlined)),
    ]),
    body: FutureBuilder<List<Ayah>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() => future = widget.repo.getAyahs(widget.surah.number)));
      return ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kGreen, kDeepGreen]),
          borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            Text(widget.surah.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6), Text('${widget.surah.ayahs} آية · ${widget.surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية'}',
              style: TextStyle(color: Colors.white.withOpacity(.8))),
            if (widget.surah.number != 1 && widget.surah.number != 9) ...[
              const SizedBox(height: 18),
              const Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', style: TextStyle(color: Colors.white, fontSize: 23, height: 1.8)),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        ...snapshot.data!.map((ayah) => Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(width: 34, height: 34, alignment: Alignment.center,
                decoration: BoxDecoration(color: kGreen.withOpacity(.09), shape: BoxShape.circle),
                child: Text('${ayah.numberInSurah}', style: const TextStyle(color: kGreen, fontWeight: FontWeight.bold))),
              const Spacer(),
              IconButton(tooltip: 'تشغيل التلاوة', onPressed: () => playAyah(ayah), icon: Icon(
                playingAyah == ayah.numberInSurah ? Icons.pause_circle_filled_rounded : Icons.play_circle_outline_rounded, color: kGreen)),
              IconButton(tooltip: 'إضافة للمفضلة', onPressed: () => widget.onFavorite(ayah.number),
                icon: Icon(widget.favorites.contains(ayah.number) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: widget.favorites.contains(ayah.number) ? Colors.redAccent : Colors.grey)),
            ]),
            const SizedBox(height: 6),
            Text(ayah.text, textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 25, height: 2.0, fontWeight: FontWeight.w500)),
            if (audioLoading && playingAyah == ayah.numberInSurah)
              const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(minHeight: 2)),
          ]),
        )),
      ]);
    }),
  );
}

class AdhkarPage extends StatefulWidget {
  const AdhkarPage({super.key});
  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  final Map<int, int> counts = {};
  final List<Map<String, Object>> items = const [
    {'title':'سبحان الله وبحمده', 'desc':'من أذكار التسبيح', 'target':100},
    {'title':'أستغفر الله وأتوب إليه', 'desc':'الاستغفار', 'target':100},
    {'title':'لا إله إلا الله وحده لا شريك له', 'desc':'ذكر التوحيد', 'target':100},
    {'title':'اللهم صل وسلم على نبينا محمد', 'desc':'الصلاة على النبي ﷺ', 'target':100},
    {'title':'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر', 'desc':'من جوامع الذكر', 'target':33},
    {'title':'أعوذ بكلمات الله التامات من شر ما خلق', 'desc':'ذكر مأثور', 'target':3},
  ];
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('الأذكار', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), const Text('اجعل لسانك رطبًا بذكر الله', style: TextStyle(color: Colors.grey)),
    const SizedBox(height: 18),
    ...List.generate(items.length, (i) {
      final item = items[i]; final count = counts[i] ?? 0; final target = item['target'] as int;
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(item['desc'] as String, style: const TextStyle(color: kGreen, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 9), Text(item['title'] as String, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, height: 1.8, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [Text('$count / $target', style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(), TextButton(onPressed: () => setState(() => counts[i] = 0), child: const Text('إعادة'))]),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(
            value: (count / target).clamp(0.0, 1.0).toDouble(), minHeight: 6, color: kGreen, backgroundColor: kGreen.withOpacity(.1))),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => setState(() => counts[i] = count >= target ? 0 : count + 1),
            icon: const Icon(Icons.touch_app_rounded), label: Text(count >= target ? 'اكتمل الذكر · ابدأ من جديد' : 'تسبيح  ($count)')),
        ]));
    }),
  ]);
}

class TasbihPage extends StatelessWidget {
  final int count; final ValueChanged<int> onCountChanged;
  const TasbihPage({super.key, required this.count, required this.onCountChanged});
  @override
  Widget build(BuildContext context) {
    final progress = (count % 33) / 33;
    return ListView(padding: const EdgeInsets.all(22), children: [
      const Text('المسبحة الإلكترونية', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), const Text('سبّح واستغفر واحتسب الأجر', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 32),
      Center(child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 250, height: 250, child: CircularProgressIndicator(value: progress, strokeWidth: 9,
          backgroundColor: kGreen.withOpacity(.10), color: kGreen)),
        Container(width: 220, height: 220, decoration: BoxDecoration(
          shape: BoxShape.circle, color: Theme.of(context).cardTheme.color,
          boxShadow: [BoxShadow(color: kGreen.withOpacity(.08), blurRadius: 30, spreadRadius: 4)]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.spa_rounded, color: kGold, size: 32),
            const SizedBox(height: 12), Text('$count', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900)),
            const Text('إجمالي التسبيحات', style: TextStyle(color: Colors.grey)),
          ])),
      ])),
      const SizedBox(height: 28),
      SizedBox(height: 64, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        onPressed: () => onCountChanged(count + 1), icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
        label: const Text('سبّح', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () => onCountChanged(0), icon: const Icon(Icons.refresh_rounded), label: const Text('تصفير العداد')),
      const SizedBox(height: 20),
      const Text('قال رسول الله ﷺ: «أحب الكلام إلى الله أربع: سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر».', textAlign: TextAlign.center,
        style: TextStyle(height: 1.8, color: Colors.grey)),
    ]);
  }
}

class MorePage extends StatelessWidget {
  final bool darkMode; final ValueChanged<bool> onThemeChanged;
  final int khatmaPage, favoritesCount; final ValueChanged<int> onKhatmaChanged;
  const MorePage({super.key, required this.darkMode, required this.onThemeChanged, required this.khatmaPage,
    required this.onKhatmaChanged, required this.favoritesCount});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('المزيد', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), const Text('إعداداتك وأدواتك اليومية', style: TextStyle(color: Colors.grey)),
    const SizedBox(height: 20),
    _MoreTile(icon: Icons.dark_mode_rounded, title: 'الوضع الليلي', subtitle: 'تغيير مظهر التطبيق',
      trailing: Switch(value: darkMode, onChanged: onThemeChanged)),
    const SizedBox(height: 10),
    _MoreTile(icon: Icons.favorite_rounded, title: 'المفضلة', subtitle: '$favoritesCount آية محفوظة محليًا',
      trailing: const Icon(Icons.chevron_left_rounded)),
    const SizedBox(height: 10),
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.flag_rounded, color: kGreen), SizedBox(width: 10),
          Text('خطة ختم القرآن', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 12), Text('أنجزت $khatmaPage صفحة من أصل 604'),
        const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
          value: (khatmaPage / 604).clamp(0.0, 1.0).toDouble(), minHeight: 8, color: kGreen, backgroundColor: kGreen.withOpacity(.1))),
        const SizedBox(height: 14),
        Row(children: [
          OutlinedButton(onPressed: () => onKhatmaChanged((khatmaPage - 1).clamp(0, 604).toInt()), child: const Icon(Icons.remove)),
          const Spacer(), Text('$khatmaPage / 604', style: const TextStyle(fontWeight: FontWeight.w900)),
          const Spacer(), FilledButton(onPressed: () => onKhatmaChanged((khatmaPage + 1).clamp(0, 604).toInt()), child: const Icon(Icons.add)),
        ]),
        TextButton(onPressed: () => onKhatmaChanged(0), child: const Text('إعادة الخطة')),
      ]),
    ),
    const SizedBox(height: 10),
    const _MoreTile(icon: Icons.cloud_done_rounded, title: 'مصدر بيانات القرآن', subtitle: 'AlQuran Cloud API · يتطلب اتصالًا بالإنترنت', trailing: Icon(Icons.open_in_new_rounded)),
    const SizedBox(height: 10),
    const _MoreTile(icon: Icons.info_outline_rounded, title: 'حول التطبيق', subtitle: 'نور القرآن الكريم · الإصدار 1.0.0', trailing: Icon(Icons.chevron_left_rounded)),
    const SizedBox(height: 18),
    const Text('تنبيه: مواقيت الصلاة والقبلة والتفسير المتخصص والمزامنة السحابية ليست مفعّلة في هذه النسخة.', style: TextStyle(color: Colors.grey, height: 1.7, fontSize: 12)),
  ]);
}

class _MoreTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Widget trailing;
  const _MoreTile({required this.icon, required this.title, required this.subtitle, required this.trailing});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20)),
    child: ListTile(contentPadding: EdgeInsets.zero, leading: Container(width: 44, height: 44,
      decoration: BoxDecoration(color: kGreen.withOpacity(.09), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: kGreen)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)), trailing: trailing));
}

class ErrorPanel extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const ErrorPanel({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(26),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey),
      const SizedBox(height: 14), const Text('لم نتمكن من تحميل البيانات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), Text('تحقق من اتصال الإنترنت ثم أعد المحاولة.\n$message',
        textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.6)),
      const SizedBox(height: 16), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
    ])));
}