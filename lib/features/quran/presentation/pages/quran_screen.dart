import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quran/quran.dart' as quran; // 🎯 استدعاء مكتبة القرآن
import '../../../../core/theme/app_colors.dart'; 
import 'quran_reading_screen.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الفهرس',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // 🎯 ListView.builder: أداة قوية لبناء القوائم الطويلة بكفاءة
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: 114, // عدد سور القرآن
        itemBuilder: (context, index) {
          final surahNumber = index + 1; // المكتبة تبدأ العد من 1
          
          // 1. جلب البيانات من المكتبة السحرية
          final surahName = quran.getSurahNameArabic(surahNumber);
          final versesCount = quran.getVerseCount(surahNumber);
          final placeOfRevelation = quran.getPlaceOfRevelation(surahNumber);
          
          // 2. فحص مكان النزول لاختيار الأيقونة المناسبة
          final isMakki = placeOfRevelation.toLowerCase() == 'makkah';

          return _buildSurahCard(context, surahNumber, surahName, versesCount, isMakki);
        },
      ),
    );
  }

  // 🎯 دالة رسم بطاقة السورة
  Widget _buildSurahCard(BuildContext context, int surahNumber, String surahName, int versesCount, bool isMakki) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cards, // لون البطاقة الكحلي
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(50), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
        final startPage = quran.getPageNumber(surahNumber, 1);
          
          // 2. الانتقال الملاحي (Navigation) لشاشة التلاوة وإعطائها رقم الصفحة
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuranReadingScreen(initialPage: startPage),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // --- المربع الذي يحتوي على رقم السورة ---
              Container(
                width: 45,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle, // يمكنك جعلها BoxShape.circle إذا فضلت الدائرة
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(
                  '$surahNumber',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),
              
              // --- اسم السورة وعدد آياتها ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سُورَة $surahName',
                      // 🎯 تطبيق الخط العثماني الذي قمنا بتثبيته
                      style: const TextStyle(
                        color: AppColors.primary, 
                        fontSize: 22, 
                        fontFamily: 'Uthmanic', // اسم الخط من ملف pubspec
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'آياتها $versesCount',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              // --- رسم أيقونة الكعبة أو القبة (SVG) ---
              SvgPicture.asset(
                isMakki ? 'assets/images/kaaba_icon.svg' : 'assets/images/dome_icon.svg',
                width: 38,
                height: 38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}