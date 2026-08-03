import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_library/quran_library.dart';
import '../../../../core/theme/app_colors.dart';
import '../manager/quran_cubit.dart';
import '../manager/quran_state.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranCubit, IslamicQuranState>(
      builder: (context, state) {
        final isDark = state.isDark;
        final bgColor = isDark ? AppColors.background : const Color(0xFFFFFDF7);
        final textColor = isDark ? Colors.white : const Color(0xFF1F1F1F);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: QuranLibraryScreen(
              parentContext: context,
              withPageView: true,
              useDefaultAppBar: true,
              isShowAudioSlider: true,
              showAyahBookmarkedIcon: true,
              isDark: isDark,
              appLanguageCode: 'ar',
              backgroundColor: bgColor,
              textColor: textColor,
              ayahSelectedBackgroundColor: AppColors.primary.withAlpha(50),
              ayahIconColor: AppColors.primary,
              surahInfoStyle: SurahInfoStyle.defaults(
                isDark: isDark,
                context: context,
              ),
              basmalaStyle: BasmalaStyle(
                verticalPadding: 4.0,
                basmalaColor: textColor.withAlpha(200),
                basmalaFontSize: 25.0,
              ),
              ayahStyle: AyahAudioStyle.defaults(
                isDark: isDark,
                context: context,
              ),
              topBarStyle:
                  QuranTopBarStyle.defaults(
                    isDark: isDark,
                    context: context,
                  ).copyWith(
                    customTopBarWidgets: [
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: isDark ? Colors.amber : AppColors.primary,
                        ),
                        tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                        onPressed: () {
                          context.read<QuranCubit>().toggleTheme();
                        },
                      ),
                    ],
                  ),
              indexTabStyle: IndexTabStyle.defaults(
                isDark: isDark,
                context: context,
              ),
              searchTabStyle: SearchTabStyle.defaults(
                isDark: isDark,
                context: context,
              ),
              bookmarksTabStyle: BookmarksTabStyle.defaults(
                isDark: isDark,
                context: context,
              ),
              ayahMenuStyle: AyahMenuStyle.defaults(
                isDark: isDark,
                context: context,
              ),
              tafsirStyle: TafsirStyle.defaults(
                isDark: isDark,
                context: context,
              ),
              topBottomQuranStyle: TopBottomQuranStyle.defaults(
                isDark: isDark,
                context: context,
              ),
            ),
          ),
        );
      },
    );
  }
}
