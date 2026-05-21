import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import '../../../../core/theme/app_colors.dart';
import '../manager/quran_cubit.dart';
import '../manager/quran_state.dart';
import '../../data/quran_db_helper.dart';
import '../../domain/ayah_model.dart';
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
    for (int i = 0; i < 10; i++) res = res.replaceAll(en[i], ar[i]);
    return res;
  }

  // 🎯 دالة القص الجراحية الصارمة: تحسب 19 حرفاً وتتجاهل التشكيل كلياً
  String _cleanVerseOne(String verse) {
    String cleanText = verse.trim();
    // إزالة كل شيء عدا الحروف الأبجدية للمطابقة
    String noDiacritics = cleanText.replaceAll(RegExp(r'[^\u0621-\u064A]'), '');

    if (noDiacritics.startsWith('بسماللهالرحمنالرحيم')) {
      int letterCount = 0;
      int sliceIndex = 0;

      // البحث عن نقطة القطع الدقيقة في النص الأصلي مع الحفاظ على تشكيله
      for (int i = 0; i < cleanText.length; i++) {
        if (RegExp(r'[\u0621-\u064A]').hasMatch(cleanText[i])) {
          letterCount++;
        }
        if (letterCount == 19) {
          // عدد حروف البسملة
          sliceIndex = i + 1;
          break;
        }
      }
      return cleanText.substring(sliceIndex).trim();
    }
    return cleanText;
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

  Widget _buildMushafPage(int pageNumber, List<AyahModel> verses) {
    int juz = verses.first.jozz;

    return Column(
      children: [
        // الهيدر
        Padding(
          padding: const EdgeInsets.only(
            top: 10.0,
            bottom: 8.0,
            left: 24.0,
            right: 24.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الجُزْءُ ${_toArabic(juz)}',
                style: const TextStyle(
                  fontFamily: 'Uthmanic',
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              Text(
                'سُورَةُ ${verses.first.soraNameAr}',
                style: const TextStyle(
                  fontFamily: 'Uthmanic',
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // الإطار الثابت وحساب الخط الدقيق
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 2.5),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 1.0),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 🎯 حساب حجم الخط ليتسع لـ 15 سطراً بدقة (مصحف المدينة)
                  double calculatedFontSize = constraints.maxHeight / 27.5;
                  if (calculatedFontSize > 26)
                    calculatedFontSize = 26; // حد أقصى للخط

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      // توسيط النصوص للصفحات القصيرة مثل الفاتحة وجزء عم
                      mainAxisAlignment: (pageNumber == 1 || pageNumber == 2)
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildVerses(
                        verses,
                        calculatedFontSize,
                        pageNumber,
                        context,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // الفوتر
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                ' ــ ',
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
              Text(
                _toArabic(pageNumber),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                ' ــ ',
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildVerses(
    List<AyahModel> allVersesOnPage,
    double fontSize,
    int pageNumber,
    BuildContext context,
  ) {
    List<Widget> widgets = [];
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

      // إضافة الترويسة والبسملة المستقلة (لغير الفاتحة والتوبة)
      if (ayahList.first.ayaNo == 1) {
        widgets.add(_buildSurahBanner(ayahList.first.soraNameAr, fontSize));

        if (sNum != 1 && sNum != 9) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
              child: Center(
                child: Text(
                  quran.basmala,
                  style: TextStyle(
                    fontFamily: 'Uthmanic',
                    fontSize: fontSize * 1.1,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
      }

      // تجهيز نصوص الآيات
      List<InlineSpan> spans = [];
      for (var ayah in ayahList) {
        String vText = ayah.text;

        // قص البسملة المدمجة للآية الأولى لغير الفاتحة والتوبة
        if (ayah.ayaNo == 1 && sNum != 1 && sNum != 9) {
          vText = _cleanVerseOne(vText);
        }

        final recognizer = LongPressGestureRecognizer()
          ..onLongPress = () {
            _showTafseerSheet(context, ayah);
          };

        // 🎯 وضع علامة \u200F قبل وبعد النص لضبط اتجاه الأرقام RTL
        spans.add(
          TextSpan(
            text: '\u200F$vText \u200F',
            style: TextStyle(
              fontFamily: 'Uthmanic',
              fontSize: fontSize,
              color: Colors.black,
              height: 1.8,
            ),
            recognizer: recognizer,
          ),
        );

        spans.add(_buildAyahMarker(ayah.ayaNo, fontSize, context, ayah));
        spans.add(const TextSpan(text: ' '));
      }

      if (spans.isNotEmpty) {
        widgets.add(
          RichText(
            // الفاتحة والصفحات القصيرة جداً يتم توسيطها لحل مشكلة التمدد
            textAlign: (pageNumber == 1 || pageNumber == 2)
                ? TextAlign.center
                : TextAlign.justify,
            textDirection: TextDirection.rtl,
            text: TextSpan(children: spans),
          ),
        );
      }
    }
    return widgets;
  }

  // 🎯 الأيقونة مضبوطة تماماً في المنتصف
  InlineSpan _buildAyahMarker(
    int ayahNo,
    double fontSize,
    BuildContext context,
    AyahModel ayah,
  ) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onLongPress: () => _showTafseerSheet(context, ayah),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: fontSize * 1.5,
          height: fontSize * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.string(
                '''<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
                     <path d="M 50 5 C 65 20, 93 35, 93 60 C 93 85, 75 95, 50 95 C 25 95, 7 85, 7 60 C 7 35, 35 20, 50 5 Z" stroke="black" stroke-width="4.5" fill="none" />
                     <circle cx="50" cy="60" r="26" stroke="black" stroke-width="2.5" fill="none" />
                   </svg>''',
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 6.0,
                ), // وزن الخط العثماني يتطلب إزاحة بسيطة للأسفل
                child: Text(
                  _toArabic(ayahNo),
                  style: TextStyle(
                    fontFamily: 'Uthmanic',
                    fontSize: fontSize * 0.75,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahBanner(String surahName, double fontSize) {
    return Container(
      height: fontSize * 2.5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8D3),
        border: Border.all(color: Colors.black87, width: 2.0),
      ),
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 1.0),
        ),
        child: Center(
          child: Text(
            'سُورَةُ $surahName',
            style: TextStyle(
              fontFamily: 'Uthmanic',
              fontSize: fontSize * 1.2,
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
                  fontFamily: 'Uthmanic',
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
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showKhatmDuaSheet(BuildContext context) {
    showModalBottomSheet(
      // ... نفس كود دعاء الختم السابق تماماً لعدم الإطالة
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
