import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran; 
import '../../../../core/theme/app_colors.dart'; 
import 'quran_reading_screen.dart';
import '../manager/quran_cubit.dart';
import '../manager/quran_state.dart';

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
        title: const Text('الفهرس', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 🎯 زر متابعة القراءة الذكي
          BlocBuilder<QuranCubit, QuranState>(
            builder: (context, state) {
              int lastPage = 1;
              if (state is QuranLoaded) {
                lastPage = state.currentPage; // تم التعديل ليقرأ الصفحة الحالية من الـ State الجديدة
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => QuranReadingScreen(initialPage: lastPage)));
                  },
                  icon: const Icon(Icons.menu_book, color: AppColors.background),
                  label: Text('متابعة القراءة (صفحة $lastPage)', style: const TextStyle(fontSize: 18, color: AppColors.background, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),

          // 🎯 قائمة سور القرآن الكريم
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: 114, 
              itemBuilder: (context, index) {
                final surahNumber = index + 1; 
                final surahName = quran.getSurahNameArabic(surahNumber);
                final versesCount = quran.getVerseCount(surahNumber);
                final placeOfRevelation = quran.getPlaceOfRevelation(surahNumber);
                final isMakki = placeOfRevelation.toLowerCase() == 'makkah';
                
                return _buildSurahCard(context, surahNumber, surahName, versesCount, isMakki);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahCard(BuildContext context, int surahNumber, String surahName, int versesCount, bool isMakki) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(50), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final startPage = quran.getPageNumber(surahNumber, 1);
          Navigator.push(context, MaterialPageRoute(builder: (context) => QuranReadingScreen(initialPage: startPage)));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 45, height: 45, alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary)),
                child: Text('$surahNumber', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('سُورَة $surahName', style: const TextStyle(color: AppColors.primary, fontSize: 22, fontFamily: 'Uthmanic', fontWeight: FontWeight.bold)),
                    Text('آياتها $versesCount', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
              SvgPicture.asset(isMakki ? 'assets/images/kaaba_icon.svg' : 'assets/images/dome_icon.svg', width: 38, height: 38),
            ],
          ),
        ),
      ),
    );
  }
}