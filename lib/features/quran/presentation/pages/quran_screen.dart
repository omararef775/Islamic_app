import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_library/quran_library.dart';
import '../../../../core/theme/app_colors.dart';
import '../manager/quran_cubit.dart';
import '../manager/quran_state.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<QuranCubit, IslamicQuranState>(
      buildWhen: (previous, current) => previous.isDark != current.isDark,
      builder: (context, state) {
        final isDark = state.isDark;
        final bgColor = isDark ? AppColors.background : const Color(0xFFFFFDF7);
        final textColor = isDark ? Colors.white : const Color(0xFF1F1F1F);

        final topBarStyle =
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
            );

        final surahInfoStyle = SurahInfoStyle.defaults(
          isDark: isDark,
          context: context,
        );
        final basmalaStyle = BasmalaStyle(
          verticalPadding: 4.0,
          basmalaColor: textColor.withAlpha(200),
          basmalaFontSize: 25.0,
        );
        final ayahStyle = AyahAudioStyle.defaults(
          isDark: isDark,
          context: context,
        );
        final indexTabStyle = IndexTabStyle.defaults(
          isDark: isDark,
          context: context,
        );
        final searchTabStyle = SearchTabStyle.defaults(
          isDark: isDark,
          context: context,
        );
        final bookmarksTabStyle = BookmarksTabStyle.defaults(
          isDark: isDark,
          context: context,
        );
        final ayahMenuStyle = AyahMenuStyle.defaults(
          isDark: isDark,
          context: context,
        );
        final tafsirStyle = TafsirStyle.defaults(
          isDark: isDark,
          context: context,
        );
        final topBottomQuranStyle = TopBottomQuranStyle.defaults(
          isDark: isDark,
          context: context,
        );

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: QuranLibraryScreen(
              parentContext: context,
              withPageView: true,
              useDefaultAppBar: true,
              isShowAudioSlider: true,
              showAyahBookmarkedIcon: true,
              isShowDisplayModeBar: false,
              enableWordSelection: false,
              isDark: isDark,
              appLanguageCode: 'ar',
              backgroundColor: bgColor,
              textColor: textColor,
              ayahSelectedBackgroundColor: AppColors.primary.withAlpha(50),
              ayahIconColor: AppColors.primary,
              surahInfoStyle: surahInfoStyle,
              basmalaStyle: basmalaStyle,
              ayahStyle: ayahStyle,
              topBarStyle: topBarStyle,
              indexTabStyle: indexTabStyle,
              searchTabStyle: searchTabStyle,
              bookmarksTabStyle: bookmarksTabStyle,
              ayahMenuStyle: ayahMenuStyle,
              tafsirStyle: tafsirStyle,
              topBottomQuranStyle: topBottomQuranStyle,
            ),
          ),
        );
      },
    );
  }
}
