import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import '../../../../core/theme/app_colors.dart';
import '../manager/quran_cubit.dart';
import '../../data/quran_db_helper.dart';
import '../../domain/ayah_model.dart';
import 'quran_screen.dart';
import 'dart:math' as math;

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

  final Map<int, Future<List<AyahModel>>> _pageCache = {};

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

  Future<List<AyahModel>> _getPageVerses(int pageNumber) {
    if (!_pageCache.containsKey(pageNumber)) {
      _pageCache[pageNumber] = QuranDatabaseHelper.instance
          .getVersesByPage(pageNumber)
          .then((data) => data.map((v) => AyahModel.fromMap(v)).toList());
    }
    return _pageCache[pageNumber]!;
  }

  String _toArabic(int n) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String res = n.toString();
    for (int i = 0; i < 10; i++) { res = res.replaceAll(en[i], ar[i]); }
    return res;
  }

  // 🎯 المشرط الجراحي الذكي: يزيل التشكيل مؤقتاً ليتعرف على البسملة ويبترها بدقة
//  String _cleanVerseOne(String verse) {
//   String text = verse.trim();
  
//   // دالة داخلية لتجريد النص تماماً من التشكيل وتوحيد الحروف للمقارنة فقط
//   String normalizeForChecking(String input) {
//     return input
//         .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u06DF\u06E0\u06E1\u06E2\u06E3\u06E4\u06E5\u06E6\u06E7\u06E8\u06E9\u06EA\u06EB\u06EC\u06ED]'), '') // التشكيل والضبط
//         .replaceAll(RegExp(r'[\u0671\u0622\u0623\u0625]'), 'ا') // تحويل (ٱ، آ، أ، إ) إلى ألف عادية لضمان التطابق
//         .trim();
//   }

//   String normalizedText = normalizeForChecking(text);
//   List<String> words = normalizedText.split(RegExp(r'\s+'));

//   // التحقق الفعلي من الكلمات الأربع الأولى للبسملة بعد التوحيد
//   if (words.length >= 4 &&
//       words[0] == 'بسم' &&
//       words[1] == 'الله' &&
//       words[2] == 'رحمن' &&
//       words[3] == 'رحيم') {
    
//     List<String> originalWords = text.split(RegExp(r'\s+'));
//     if (originalWords.length >= 4) {
//       // إرجاع الآية بعد قطع الكلمات الأربع الأولى المشكلة
//       return originalWords.sublist(4).join(' ').trim();
//     }
//   }
  
//   return text;
// }

// دالة محصنة 100% تقبل الموديل كاملاً لفحص النص الإملائي
// 🎯 دالة محصنة ونهائية لتجريد وبتر البسملة
String _getCleanVerseText(AyahModel ayah) {
  if (ayah.ayaNo == 1 && ayah.sora != 1 && ayah.sora != 9) {
    
    // 1. تجريد النص العثماني تماماً من كل الحركات وعلامات الوقف والألف الخنجرية باستخدام نطاقات اليونيكود
    String clean = ayah.text.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
    
    // 2. توحيد كل أشكال الألف (أ، إ، آ، ٱ) إلى ألف عادية لتسهيل المطابقة
    clean = clean.replaceAll(RegExp(r'[ٱآأإ]'), 'ا');

    // الآن النص أصبح نظيفاً تماماً ويبدو هكذا: "بسم الله الرحمن الرحيم الم"
    if (clean.startsWith('بسم الله الرحمن الرحيم')) {
      // نعود للنص الأصلي المشكل، ونقطعه بناءً على المسافات
      List<String> uthmaniWords = ayah.text.trim().split(RegExp(r'\s+'));
      if (uthmaniWords.length >= 4) {
        // نتجاوز الكلمات الأربع الأولى (البسملة) ونرجع الباقي
        return uthmaniWords.sublist(4).join(' '); 
      }
    }
  }
  return ayah.text;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
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
                    final currentJuz = quran.getJuzNumber(
                      pageData.first['surah'] as int,
                      pageData.first['start'] as int,
                    );
                    if (currentJuz != _lastJuz) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'بداية الجزء ${_toArabic(currentJuz)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Uthmanic',
                              fontSize: 18,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      _lastJuz = currentJuz;
                    }
                  }
                },
                itemBuilder: (context, index) {
                  return FutureBuilder<List<AyahModel>>(
                    future: _getPageVerses(index + 1),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('صفحة فارغة'));
                      }
                      return _buildMushafPage(index + 1, snapshot.data!);
                    },
                  );
                },
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showControlUI ? 0 : -100,
              left: 0,
              right: 0,
              child: _buildTopMenu(),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showControlUI ? 0 : -100,
              left: 0,
              right: 0,
              child: _buildBottomMenu(),
            ),
          ],
        ),
      ),
    );
  }

  // 🏛️ هندسة الورقة القرآنية (مطابقة لمصحف المدينة)
Widget _buildMushafPage(int pageNumber, List<AyahModel> verses) {
  int juz = verses.first.jozz;
  return Column(
    children: [
      // 🥇 الهيدر
      Padding(
        padding: const EdgeInsets.only(top: 0.5, bottom: 0.5, left: 24.0, right: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الجُزْءُ ${_toArabic(juz)}',
              style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 15, color: Colors.black87),
            ),
            Text(
              'سُورَةُ ${verses.first.soraNameAr}',
              style: const TextStyle(fontFamily: 'Uthmanic', fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
      ),

      // 🥈 الإطار المزدوج الثابت والمطور (عرض كامل بدون انكماش)
    // 🥈 الإطار المزدوج الثابت والاحترافي (بدون FittedBox وبدون Scroll)
       // 🥈 الإطار المزدوج الثابت والاحترافي (الحل النهائي لمنع القص)
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14.0),
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 1.5),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 🎯 المعادلة السحرية المضبوطة بدقة:
                double maxFontSizeByWidth = constraints.maxWidth / 14.5;
                
                // 🛑 رفعنا المعامل هنا إلى 29.5 لضمان عدم تجاوز النص لارتفاع الشاشة إطلاقاً
                double maxFontSizeByHeight = constraints.maxHeight / 29.5;
                
                double finalFontSize = math.min(maxFontSizeByWidth, maxFontSizeByHeight);
                double targetWidth = constraints.maxWidth - 16; 

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black87, width: 1.0),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.topCenter,
                  // 🛡️ درع الحماية الأخير ضد القص: ScrollView مقفل التمرير
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: targetWidth,
                      child: RichText(
                        textAlign: TextAlign.justify, 
                        textDirection: TextDirection.rtl,
                        // 🛑 1. التعديل الجذري هنا: إجبار فلاتر على ارتفاع موحد صارم
                      strutStyle: StrutStyle(
                        fontFamily: 'KFGQPC_HAFS',
                        fontSize: finalFontSize,
                        height: 1.3, // 👈 ضع هنا نفس الرقم الذي اخترته للارتفاع في دالة _buildVersesSpans
                        forceStrutHeight: true, // هذه الخاصية هي التي تمنع تمدد السطور بسبب التشكيل
                      ),
                      
                      // 🛑 2. ضمان عدم تمدد السطر الأول والأخير
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: true,
                        applyHeightToLastDescent: true,
                      ),
                        text: TextSpan(
                          children: _buildVersesSpans(verses, finalFontSize, targetWidth, context),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

      // 🥉 الفوتر
      Padding(
        padding: const EdgeInsets.only(top: 0.5, bottom: 0.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(' ــ ', style: TextStyle(fontSize: 15, color: Colors.black54)),
            Text(
              _toArabic(pageNumber),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Text(' ــ ', style: TextStyle(fontSize: 15, color: Colors.black54)),
          ],
        ),
      ),
    ],
  );
}

  // 🎯 بناء كتلة النص المتصلة (تجميع الترويسات والآيات والبسملة)
 List<InlineSpan> _buildVersesSpans(
  List<AyahModel> allVersesOnPage,
  double fontSize,
  double targetWidth,
  BuildContext context,
) {
  List<InlineSpan> spans = [];
  Map<int, List<AyahModel>> surahsOnPage = {};

  for (var ayah in allVersesOnPage) {
    if (!surahsOnPage.containsKey(ayah.sora)) {
      surahsOnPage[ayah.sora] = [];
    }
    surahsOnPage[ayah.sora]!.add(ayah);
  }

  for (var entry in surahsOnPage.entries) {
    int sNum = entry.key;
    List<AyahModel> ayahList = entry.value;

    // أ. الترويسة والبسملة اليدوية
    if (ayahList.first.ayaNo == 1) {
      spans.add(
        WidgetSpan(
          child: Container(
            width: targetWidth,
            alignment: Alignment.center,
            child: _buildSurahBanner(ayahList.first.soraNameAr, fontSize),
          ),
        ),
      );

      if (sNum != 9) {
        String basmalahText = quran.basmala;
        if (sNum == 1) {
          basmalahText += ' ﴿١﴾';
        }

  spans.add(
          WidgetSpan(
            // 🛑 العصا السحرية: تسمح لك بإزاحة البسملة يدوياً متجاهلة قيود الصفحة
            child: Transform.translate(
              // 👈 قم بتكبير رقم 12 (مثلاً 18 أو 20) إذا أردت دفع البسملة للأسفل أكثر باتجاه الآيات
              // 👈 أو استخدم قيمة سالبة (-5) لرفعها للأعلى باتجاه ترويسة السورة
              offset: const Offset(1, 2), 
              child: Container(
                width: targetWidth,
                alignment: Alignment.center,
                padding: EdgeInsets.zero, // تصفير البادينغ تماماً
                child: Text(
                  basmalahText,
                  style: TextStyle(
                    fontFamily: 'KFGQPC_HAFS',
                    fontSize: fontSize * 1.1,
                    color: Colors.black,
                    // 🛑 قص الفراغ الوهمي السفلي المحجوز داخل ملف الخط نفسه
                    height: 0.5, 
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    // ب. سرد نص الآيات متصلاً
 // استبدل هذا الجزء داخل حلقة (for) التي تسرد الآيات
for (var ayah in ayahList) {
  if (sNum == 1 && ayah.ayaNo == 1) continue;

  // استخدام الدالة الجديدة المحصنة
  String vText = _getCleanVerseText(ayah);

  final recognizer = LongPressGestureRecognizer()
    ..onLongPress = () {
      _showTafseerSheet(context, ayah);
    };
  // ... باقي الكود الخاص بـ TextSpan كما هو
      spans.add(
        TextSpan(
          text: '$vText ',
          style: TextStyle(
            fontFamily: 'KFGQPC_HAFS',
            fontSize: fontSize *0.85,
            color: Colors.black,
            height: 1.3, // مسافة عمودية كافية تمنع تداخل التشكيل تماماً
          ),
          recognizer: recognizer,
        ),
      );

      // وضع رقم الآية محصناً داخل نفس سياق النص
      spans.add(
        TextSpan(
          text: '﴿${_toArabic(ayah.ayaNo)}﴾ ',
          style: TextStyle(
            fontFamily: 'KFGQPC_HAFS',
            fontSize: fontSize * 0.9,
            color: AppColors.primary,
          ),
          recognizer: recognizer,
        ),
      );
    }
  }
  return spans;
}

  // 🎯 ترويسة السورة المعدلة لتعمل داخل الـ WidgetSpan
  Widget _buildSurahBanner(String surahName, double fontSize) {
    return Container(
      height: fontSize * 1.2,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8D3),
        border: Border.all(color: Colors.black87, width: 0.3),
      ),
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 0.3),
        ),
        child: Center(
          child: Text(
            'سُورَةُ $surahName',
            style: TextStyle(
              fontFamily: 'Uthmanic',
              fontSize: fontSize * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      color: Colors.black.withAlpha(220),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Spacer(),
          const Text(
            'المصحف الشريف',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Uthmanic',
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const QuranScreen()),
            ),
            icon: const Icon(Icons.list_alt, color: Colors.white),
          ),
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
            label: const Text(
              'دعاء الختم',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Container(width: 1, height: 35, color: Colors.white24),
          Text(
            'صفحة: ${_toArabic(_pageController.hasClients ? _pageController.page!.toInt() + 1 : widget.initialPage)}',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  void _showTafseerSheet(BuildContext context, AyahModel ayah) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFDF6E3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'سُورَةُ ${ayah.soraNameAr} - آيَة ${_toArabic(ayah.ayaNo)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Uthmanic',
                  fontSize: 24,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(thickness: 1, height: 30),
              Text(
                '{ ${ayah.text} }',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Uthmanic', // يمكن تغييرها لاحقاً لـ KFGQPC_HAFS إذا أردت
                  fontSize: 26,
                  color: Colors.black87,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 30),
              if (ayah.maany.trim().isNotEmpty &&
                  ayah.maany != 'لا يوجد معاني متوفرة.') ...[
                const Text(
                  '📚 معاني الكلمات:',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  ayah.maany,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (ayah.tafseerSaadi.trim().isNotEmpty) ...[
                const Text(
                  '📖 تفسير السعدي:',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  ayah.tafseerSaadi,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 🤲 دعاء الختم الكامل (محفوظ بالكامل كما أرسلته)
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
          decoration: const BoxDecoration(
            color: Color(0xFFFDF6E3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(30),
            children: [
              const Center(
                child: Text(
                  'دُعَاءُ خَتْمِ القُرْآنِ الكَرِيمِ',
                  style: TextStyle(
                    fontFamily: 'Uthmanic',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
              ),
              const Divider(thickness: 2, height: 40),
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
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Uthmanic',
                  fontSize: 24,
                  height: 1.8,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}