import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import '../../../../core/theme/app_colors.dart';
import '../manager/quran_cubit.dart';

class QuranReadingScreen extends StatefulWidget {
  final int initialPage;
  const QuranReadingScreen({super.key, required this.initialPage});

  @override
  State<QuranReadingScreen> createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends State<QuranReadingScreen> {
  late PageController _pageController;
  bool _isMenuVisible = false;
  int _lastJuz = 0;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    
    final pageData = quran.getPageData(widget.initialPage);
    if (pageData.isNotEmpty) {
      _lastJuz = quran.getJuzNumber(pageData.first['surah'] as int, pageData.first['start'] as int);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showHizbToast(String message) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: Colors.black.withAlpha(200), borderRadius: BorderRadius.circular(12)),
          child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Uthmanic')),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 2), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _onPageChanged(int index) {
    final pageNumber = index + 1;
    context.read<QuranCubit>().saveBookmark(pageNumber);

    final pageData = quran.getPageData(pageNumber);
    if (pageData.isNotEmpty) {
      final currentJuz = quran.getJuzNumber(pageData.first['surah'] as int, pageData.first['start'] as int);
      if (currentJuz != _lastJuz) {
        _showHizbToast('الجُزْءُ ${_toArabicNumber(currentJuz)}');
        _lastJuz = currentJuz;
      }
    }
  }

  // 🤲 دعاء الختم الكامل والصحيح
  void _showKhatmDuaSheet(BuildContext context) {
    const String fullKhatmDua = '''صَدَقَ اللهُ العَظِيمُ وَبَلَّغَ رَسُولُهُ الكَرِيمُ، وَنَحْنُ عَلَى ذَلِكَ مِنَ الشَّاهِدِينَ.
اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ وَاجْعَلْهُ لِي إِمَامًا وَنُورًا وَهُدًى وَرَحْمَةً. اللَّهُمَّ ذَكِّرْنِي مِنْهُ مَا نَسِيتُ، وَعَلِّمْنِي مِنْهُ مَا جَهِلْتُ، وَارْزُقْنِي تِلَاوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ، وَاجْعَلْهُ لِي حُجَّةً يَا رَبَّ العَالَمِينَ.
اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي، وَاجْعَلِ الحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ، وَاجْعَلِ المَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ.
اللَّهُمَّ اجْعَلْ خَيْرَ عُمْرِي آخِرَهُ، وَخَيْرَ عَمَلِي خَوَاتِمَهُ، وَخَيْرَ أَيَّامِي يَوْمَ أَلْقَاكَ فِيهِ.
اللَّهُمَّ إِنِّي أَسْأَلُكَ عِيشَةً هَنِيَّةً، وَمِيتَةً سَوِيَّةً، وَمَرَدًّا غَيْرَ مُخْزٍ وَلَا فَاضِحٍ.
اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ المَسْأَلَةِ، وَخَيْرَ الدُّعَاءِ، وَخَيْرَ النَّجَاحِ، وَخَيْرَ العِلْمِ، وَخَيْرَ العَمَلِ، وَخَيْرَ الثَّوَابِ، وَخَيْرَ الحَيَاةِ، وَخَيْرَ المَمَاتِ، وَثَبِّتْنِي وَثَقِّلْ مَوَازِينِي، وَحَقِّقْ إِيمَانِي، وَارْفَعْ دَرَجَتِي، وَتَقَبَّلْ صَلَاتِي، وَاغْفِرْ خَطِيئَاتِي، وَأَسْأَلُكَ العُلَا مِنَ الجَنَّةِ.
اللَّهُمَّ أَحْسِنْ عَاقِبَتَنَا فِي الأُمُورِ كُلِّهَا، وَأَجِرْنَا مِنْ خِزْيِ الدُّنْيَا وَعَذَابِ الآخِرَةِ.
اللَّهُمَّ اقْسِمْ لَنَا مِنْ خَشْيَتِكَ مَا تَحُولُ بِهِ بَيْنَنَا وَبَيْنَ مَعْصِيَتِكَ، وَمِنْ طَاعَتِكَ مَا تُبَلِّغُنَا بِهَا جَنَّتَكَ، وَمِنَ اليَقِينِ مَا تُهَوِّنُ بِهِ عَلَيْنَا مَصَائِبَ الدُّنْيَا، وَمَتِّعْنَا بِأَسْمَاعِنَا وَأَبْصَارِنَا وَقُوَّتِنَا مَا أَحْيَيْتَنَا، وَاجْعَلْهُ الوَارِثَ مِنَّا، وَاجْعَلْ ثَأْرَنَا عَلَى مَنْ ظَلَمَنَا، وَانْصُرْنَا عَلَى مَنْ عَادَانَا، وَلَا تَجْعَلْ مُصِيبَتَنَا فِي دِينِنَا، وَلَا تَجْعَلِ الدُّنْيَا أَكْبَرَ هَمِّنَا وَلَا مَبْلَغَ عِلْمِنَا، وَلَا تُسَلِّطْ عَلَيْنَا مَنْ لَا يَرْحَمُنَا.
اللَّهُمَّ لَا تَدَعْ لَنَا ذَنْبًا إِلَّا غَفَرْتَهُ، وَلَا هَمًّا إِلَّا فَرَّجْتَهُ، وَلَا دَيْنًا إِلَّا قَضَيْتَهُ، وَلَا حَاجَةً مِنْ حَوَائِجِ الدُّنْيَا وَالآخِرَةِ إِلَّا قَضَيْتَهَا يَا أَرْحَمَ الرَّاحِمِينَ.
رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ، وَصَلَّى اللهُ عَلَى سَيِّدِنَا وَنَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَأَصْحَابِهِ الأَخْيَارِ وَسَلَّمَ تَسْلِيمًا كَثِيرًا.''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFDF6E3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  const Center(child: Text('دُعَاءُ خَتْمِ القُرْآنِ الكَرِيمِ', style: TextStyle(fontFamily: 'Uthmanic', fontSize: 28, color: Color(0xFF8B0000), fontWeight: FontWeight.bold))),
                  const SizedBox(height: 24),
                  const Text(
                    fullKhatmDua,
                    textAlign: TextAlign.justify, textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: 'Uthmanic', fontSize: 22, color: Colors.black87, height: 1.8),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), 
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isMenuVisible = !_isMenuVisible),
              child: PageView.builder(
                controller: _pageController,
                reverse: true,
                itemCount: 604,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _buildMushafPage(index + 1);
                },
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _isMenuVisible ? 0 : -80, left: 0, right: 0,
              child: Container(
                height: 60, color: AppColors.background.withAlpha(242),
                child: Center(child: Text('المصحف الشريف', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 18))),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _isMenuVisible ? 0 : -80, left: 0, right: 0,
              child: Container(
                height: 70, color: AppColors.background.withAlpha(242),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () { setState(() => _isMenuVisible = false); _showKhatmDuaSheet(context); },
                      icon: const Icon(Icons.menu_book, color: AppColors.primary),
                      label: const Text('دعاء الختم', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                    Container(width: 1, height: 40, color: AppColors.textSecondary.withAlpha(128)),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.list, color: AppColors.primary),
                      label: const Text('الفهرس', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 🏛️ هندسة الورقة القرآنية (محاكاة دقيقة وخالية من العيوب)
  // =========================================================================

  Widget _buildMushafPage(int pageNumber) {
    final pageData = quran.getPageData(pageNumber);
    if (pageData.isEmpty) return const SizedBox();

    final firstSurah = pageData.first['surah'] as int;
    final juzNumber = quran.getJuzNumber(firstSurah, pageData.first['start'] as int);

    return Container(
      color: const Color(0xFFFDF6E3), 
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
        child: Column(
          children: [
            // 🥇 الترويسة العلوية خارج الإطار (رقم الجزء ورقم الصفحة)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0, left: 8.0, right: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الجُزْءُ ${_toArabicNumber(juzNumber)}', style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 18, color: Colors.black)),
                  Text(_toArabicNumber(pageNumber), style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // 🥈 الإطار المزدوج الصارم 
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 2.0)),
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 1.0)),
                  
                  // 🎯 السحر الهندسي: التوسيط العامودي للآيات (لحل مشكلة فراغ الفاتحة)
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center, // 🎯 هنا يتم التوسيط
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _buildPageContent(pageData),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 بناء المحتوى الداخلي للورقة
  List<Widget> _buildPageContent(List<dynamic> pageData) {
    List<Widget> content = [];

    for (var data in pageData) {
      final surah = data['surah'] as int;
      final startVerse = data['start'] as int;
      final endVerse = data['end'] as int;

      // 1. رسم الترويسة والبسملة 
      if (startVerse == 1) {
        content.add(_buildSurahHeader(surah));

        if (surah == 1) {
          // الفاتحة: البسملة هي الآية 1 (نرسمها متمركزة مع رمز الآية الأصلي)
          content.add(
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Text('${quran.basmala} \u06DD١', style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 26, color: Colors.black)),
              ),
            ),
          );
        } else if (surah != 9) {
          // باقي السور: بسملة صافية
          content.add(
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: Text(quran.basmala, style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 24, color: Colors.black)),
              ),
            ),
          );
        }
      }

      // 2. تجميع الآيات (كشيدة تامة)
      String surahTextBlock = '';
      for (int i = startVerse; i <= endVerse; i++) {
        if (surah == 1 && i == 1) continue; // تم رسم الفاتحة

        // 🎯 تنظيف الآية من أي رموز مخفية مسبقاً لمنع التكرار
        String rawVerse = quran.getVerse(surah, i, verseEndSymbol: false).replaceAll('\u06DD', '').trim();

        // 🔪 المشرط الجراحي الأقوى: يمحو البسملة المخفية في بداية الآية 1 تماماً
        if (i == 1 && surah != 1 && surah != 9) {
          List<String> words = rawVerse.split(RegExp(r'\s+'));
          if (words.length > 4) {
            String firstFourWords = words.sublist(0, 4).join(' ');
            if (firstFourWords.contains('سم') && firstFourWords.contains('رحيم')) {
              rawVerse = words.sublist(4).join(' ');
            }
          }
        }

        // 🎯 الاعتماد على الرمز السحري للخط العثماني \u06DD مع الرقم العربي
        String arabicNumber = _toArabicNumber(i);
        surahTextBlock += '$rawVerse \u06DD$arabicNumber ';
      }

      if (surahTextBlock.isNotEmpty) {
        content.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              surahTextBlock.trim(),
              textAlign: TextAlign.justify, // الكشيدة المثالية
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Uthmanic',
                fontSize: 24, // الحجم المطابق لصورك
                height: 1.7,
                color: Colors.black,
              ),
            ),
          ),
        );
      }
    }
    return content;
  }

  // 🎯 رسم الترويسة المزخرفة (مطابقة لمعيار المصحف)
  Widget _buildSurahHeader(int surah) {
    final surahName = quran.getSurahNameArabic(surah);
    final versesCount = quran.getVerseCount(surah);

    return Container(
      height: 46,
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0, right: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE5CD), 
        border: Border.all(color: Colors.black87, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Center(child: Text('آيَاتُهَا\n${_toArabicNumber(versesCount)}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 12, height: 1.2, color: Colors.black)))),
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.black87, width: 1.5))),
              child: Center(child: Text('سُورَةُ $surahName', style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black))),
            ),
          ),
          Expanded(child: Center(child: Text('تَرْتِيبُهَا\n${_toArabicNumber(surah)}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 12, height: 1.2, color: Colors.black)))),
        ],
      ),
    );
  }

  // أداة تحويل الأرقام للإصدار العربي
  String _toArabicNumber(int number) {
    const englishToArabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((e) => englishToArabic[int.parse(e)]).join();
  }
}