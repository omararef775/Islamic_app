import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import '../../../../core/theme/app_colors.dart';
import '../manager/quran_cubit.dart';
import 'quran_screen.dart'; 

class QuranReadingScreen extends StatefulWidget {
  final int initialPage;
  const QuranReadingScreen({super.key, required this.initialPage});

  @override
  State<QuranReadingScreen> createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends State<QuranReadingScreen> {
  late PageController _pageController;
  bool _showControlUI = false;
  int _lastJuz = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _toArabic(int n) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String res = n.toString();
    for (int i = 0; i < 10; i++) res = res.replaceAll(en[i], ar[i]);
    return res;
  }

  // المشرط الجراحي لضمان عدم تكرار البسملة
  String _cleanVerseOne(String verse) {
    String text = verse.replaceAll(quran.basmala, '').trim();
    if (text.contains('بِسْمِ') || text.contains('بسم')) {
      List<String> words = text.split(RegExp(r'\s+'));
      int rahimIndex = words.indexWhere((w) => w.contains('رَّحِيمِ') || w.contains('رحيم'));
      if (rahimIndex != -1 && rahimIndex <= 5) {
        text = words.sublist(rahimIndex + 1).join(' '); 
      } else if (words.length > 4) {
        text = words.sublist(4).join(' '); 
      }
    }
    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3), // لون خلفية مريح يملأ الشاشة
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showControlUI = !_showControlUI),
              child: PageView.builder(
                controller: _pageController,
                reverse: true,
                itemCount: 604,
                onPageChanged: (index) {
                  int currentPage = index + 1;
                  context.read<QuranCubit>().saveBookmark(currentPage);
                  
                  final pageData = quran.getPageData(currentPage);
                  if (pageData.isNotEmpty) {
                    final currentJuz = quran.getJuzNumber(pageData.first['surah'] as int, pageData.first['start'] as int);
                    if (currentJuz != _lastJuz) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('بداية الجزء ${_toArabic(currentJuz)}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 18)), duration: const Duration(seconds: 2))
                      );
                      _lastJuz = currentJuz;
                    }
                  }
                },
                itemBuilder: (context, index) => _buildMushafPage(index + 1),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _showControlUI ? 0 : -100, left: 0, right: 0,
              child: _buildTopMenu(),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _showControlUI ? 0 : -100, left: 0, right: 0,
              child: _buildBottomMenu(),
            ),
          ],
        ),
      ),
    );
  }

  // 🏛️ هندسة الورقة القرآنية المتجاوبة (بدون أرقام ثابتة)
  Widget _buildMushafPage(int pageNumber) {
    final pageData = quran.getPageData(pageNumber);
    if (pageData.isEmpty) return const SizedBox();
    
    int firstSurah = pageData.first['surah'];
    int juz = quran.getJuzNumber(firstSurah, pageData.first['start']);

    return Column(
      children: [
        // 🥇 الهيدر (رقم الجزء والسورة)
        Padding(
          padding: const EdgeInsets.only(top: 15.0, bottom: 8.0, left: 24.0, right: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الجُزْءُ ${_toArabic(juz)}', style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 22, color: Colors.black87)),
              Text('سُورَةُ ${quran.getSurahNameArabic(firstSurah)}', style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 22, color: Colors.black87)),
            ],
          ),
        ),

        // 🥈 الإطار المزدوج المرن (يتمدد ليملأ كامل مساحة الشاشة المتوفرة)
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 3.0)), 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 1.0)), 
              
              // 🎯 التصميم المتجاوب الذكي (LayoutBuilder)
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // حساب حجم الخط ديناميكياً بناءً على عرض الشاشة
                  final double responsiveFontSize = constraints.maxWidth * 0.062;
                  
                  return FittedBox(
                    fit: BoxFit.scaleDown, // يتدخل فقط إذا طفحت الصفحة، فيقوم بتصغيرها بنسبة بسيطة ليمنع الخطأ الأحمر
                   alignment: (pageNumber == 1 || pageNumber == 2) 
                        ? Alignment.center 
                        : Alignment.topCenter,
                    child: SizedBox(
                      width: constraints.maxWidth, // يملأ العرض المتاح بالكامل
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start, 
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildVerses(pageData, responsiveFontSize),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

    // 🥉 الفوتر (رقم الصفحة) بدون زخارف الخط العثماني
        Padding(
          padding: const EdgeInsets.only(top: 15.0, bottom: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(' ــ ', style: TextStyle(fontSize: 20, color: Colors.black54)),
              Text(
                _toArabic(pageNumber), 
                // 🎯 حذفنا الخط العثماني من هنا لكي يظهر الرقم عادياً ومجتمعاً
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
              const Text(' ــ ', style: TextStyle(fontSize: 20, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }

  // 🎯 بناء الآيات باستخدام الحجم الديناميكي
  List<Widget> _buildVerses(List<dynamic> pageData, double baseFontSize) {
    List<Widget> widgets = [];
    
    for (var data in pageData) {
      int sNum = data['surah'];
      int start = data['start'];
      int end = data['end'];

      if (start == 1) {
        widgets.add(_buildSurahBanner(sNum, baseFontSize));
        if (sNum != 9) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Center(child: Text(quran.basmala, style: TextStyle(fontFamily: 'Uthmanic', fontSize: baseFontSize * 1.2, color: Colors.black))),
            )
          );
        }
      }

      List<InlineSpan> spans = [];
      for (int i = start; i <= end; i++) {
        if (sNum == 1 && i == 1) continue; 
        
        String vText = quran.getVerse(sNum, i, verseEndSymbol: false).trim();
        
        if (i == 1 && sNum != 1 && sNum != 9) {
          vText = _cleanVerseOne(vText);
        }

        // استخدام حجم الخط الديناميكي وتباعد الأسطر المريح (1.85)
        spans.add(TextSpan(text: '$vText ', style: TextStyle(fontFamily: 'Uthmanic', fontSize: baseFontSize, color: Colors.black, height: 1.85)));
        
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text('\u06DD', style: TextStyle(fontFamily: 'Uthmanic', fontSize: baseFontSize * 1.5, color: Colors.black)), 
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(_toArabic(i), style: TextStyle(fontFamily: 'Uthmanic', fontSize: baseFontSize * 1.3, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                ],
              ),
            ),
          )
        );
        spans.add(const TextSpan(text: ' '));
      }

      if (spans.isNotEmpty) {
        widgets.add(
          RichText(
            textAlign: TextAlign.justify, 
            textDirection: TextDirection.rtl,
            text: TextSpan(children: spans),
          )
        );
      }
    }
    return widgets;
  }

  // الترويسة الديناميكية
  Widget _buildSurahBanner(int surah, double baseFontSize) {
    return Container(
      height: baseFontSize * 2.3,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8D3),
        border: Border.all(color: Colors.black87, width: 2.0),
      ),
      child: Row(
        children: [
          Expanded(child: Center(child: Text('آيَاتُهَا\n${_toArabic(quran.getVerseCount(surah))}', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Uthmanic', fontSize: baseFontSize * 0.45, height: 1.2, color: Colors.black)))),
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.black87, width: 2.0))),
              child: Center(child: Text('سُورَةُ ${quran.getSurahNameArabic(surah)}', style: TextStyle(fontFamily: 'Uthmanic', fontSize: baseFontSize * 0.95, fontWeight: FontWeight.bold, color: Colors.black))),
            ),
          ),
          Expanded(child: Center(child: Text('تَرْتِيبُهَا\n${_toArabic(surah)}', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Uthmanic', fontSize: baseFontSize * 0.45, height: 1.2, color: Colors.black)))),
        ],
      ),
    );
  }

  Widget _buildTopMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      color: Colors.black.withAlpha(220),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
          const Spacer(),
          const Text('المصحف الشريف', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Uthmanic', fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const QuranScreen())), icon: const Icon(Icons.list_alt, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBottomMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.black.withAlpha(220),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: () => _showKhatmDuaSheet(context),
            icon: const Icon(Icons.auto_stories, color: AppColors.primary),
            label: const Text('دعاء الختم', style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          Container(width: 1, height: 35, color: Colors.white24),
          Text(
            'صفحة: ${_toArabic(_pageController.hasClients ? _pageController.page!.toInt() + 1 : widget.initialPage)}', 
            style: const TextStyle(color: Colors.white, fontSize: 18)
          ),
        ],
      ),
    );
  }

void _showKhatmDuaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Color(0xFFFDF6E3), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(), // إضافة حركة مرنة ومريحة للسحب
            padding: const EdgeInsets.all(30),
            children: [
              const Center(child: Text('دُعَاءُ خَتْمِ القُرْآنِ الكَرِيمِ', style: TextStyle(fontFamily: 'Uthmanic', fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF8B0000)))),
              const Divider(thickness: 2, height: 40),
              
              // 🎯 النص الكامل لدعاء الختم
              const Text(
                'صَدَقَ اللهُ العَظِيمُ وَبَلَّغَ رَسُولُهُ الكَرِيمُ، وَنَحْنُ عَلَى ذَلِكَ مِنَ الشَّاهِدِينَ.\n\n'
                'اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ وَاجْعَلْهُ لِي إِمَامًا وَنُورًا وَهُدًى وَرَحْمَةً.\n\n'
                'اللَّهُمَّ ذَكِّرْنِي مِنْهُ مَا نَسِيتُ، وَعَلِّمْنِي مِنْهُ مَا جَهِلْتُ، وَارْزُقْنِي تِلَاوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ، وَاجْعَلْهُ لِي حُجَّةً يَا رَبَّ العَالَمِينَ.\n\n'
                'اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي، وَاجْعَلِ الحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ، وَاجْعَلِ المَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ.\n\n'
                'اللَّهُمَّ اجْعَلْ خَيْرَ عُمْرِي آخِرَهُ، وَخَيْرَ عَمَلِي خَوَاتِمَهُ، وَخَيْرَ أَيَّامِي يَوْمَ أَلْقَاكَ فِيهِ.\n\n'
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِيشَةً هَنِيَّةً، وَمِيتَةً سَوِيَّةً، وَمَرَدًّا غَيْرَ مُخْزٍ وَلَا فَاضِحٍ.\n\n'
                'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ المَسْأَلَةِ، وَخَيْرَ الدُّعَاءِ، وَخَيْرَ النَّجَاحِ، وَخَيْرَ العِلْمِ، وَخَيْرَ العَمَلِ، وَخَيْرَ الثَّوَابِ، وَخَيْرَ الحَيَاةِ، وَخَيْرَ المَمَاتِ، وَثَبِّتْنِي وَثَقِّلْ مَوَازِينِي، وَحَقِّقْ إِيمَانِي، وَارْفَعْ دَرَجَتِي، وَتَقَبَّلْ صَلَاتِي، وَاغْفِرْ خَطِيئَاتِي، وَأَسْأَلُكَ العُلَا مِنَ الجَنَّةِ.\n\n'
                'اللَّهُمَّ أَحْسِنْ عَاقِبَتَنَا فِي الأُمُورِ كُلِّهَا، وَأَجِرْنَا مِنْ خِزْيِ الدُّنْيَا وَعَذَابِ الآخِرَةِ.\n\n'
                'اللَّهُمَّ اقْسِمْ لَنَا مِنْ خَشْيَتِكَ مَا تَحُولُ بِهِ بَيْنَنَا وَبَيْنَ مَعْصِيَتِكَ، وَمِنْ طَاعَتِكَ مَا تُبَلِّغُنَا بِهَا جَنَّتَكَ، وَمِنَ اليَقِينِ مَا تُهَوِّنُ بِهِ عَلَيْنَا مَصَائِبَ الدُّنْيَا، وَمَتِّعْنَا بِأَسْمَاعِنَا وَأَبْصَارِنَا وَقُوَّتِنَا مَا أَحْيَيْتَنَا، وَاجْعَلْهُ الوَارِثَ مِنَّا، وَاجْعَلْ ثَأْرَنَا عَلَى مَنْ ظَلَمَنَا، وَانْصُرْنَا عَلَى مَنْ عَادَانَا، وَلَا تَجْعَلْ مُصِيبَتَنَا فِي دِينِنَا، وَلَا تَجْعَلِ الدُّنْيَا أَكْبَرَ هَمِّنَا وَلَا مَبْلَغَ عِلْمِنَا، وَلَا تُسَلِّطْ عَلَيْنَا مَنْ لَا يَرْحَمُنَا.\n\n'
                'اللَّهُمَّ لَا تَدَعْ لَنَا ذَنْبًا إِلَّا غَفَرْتَهُ، وَلَا هَمًّا إِلَّا فَرَّجْتَهُ، وَلَا دَيْنًا إِلَّا قَضَيْتَهُ، وَلَا حَاجَةً مِنْ حَوَائِجِ الدُّنْيَا وَالآخِرَةِ إِلَّا قَضَيْتَهَا يَا أَرْحَمَ الرَّاحِمِينَ.\n\n'
                'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ، وَصَلَّى اللهُ عَلَى سَيِّدِنَا وَنَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَأَصْحَابِهِ الأَخْيَارِ وَسَلَّمَ تَسْلِيمًا كَثِيرًا.',
                textAlign: TextAlign.justify, // لضبط نهايات الأسطر وجعلها متساوية (كشيدة)
                textDirection: TextDirection.rtl, // لضمان اتجاه النص من اليمين لليسار
                style: TextStyle(fontFamily: 'Uthmanic', fontSize: 24, height: 1.8, color: Colors.black87),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(15)),
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}