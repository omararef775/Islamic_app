import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_state.dart';

class QuranCubit extends Cubit<IslamicQuranState> {
  QuranCubit() : super(const IslamicQuranState());

  static const String _isDarkKey = 'quran_is_dark';

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_isDarkKey) ?? true;
    emit(state.copyWith(isDark: isDark));
  }

  Future<void> toggleTheme() async {
    final newIsDark = !state.isDark;
    emit(state.copyWith(isDark: newIsDark));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkKey, newIsDark);
  }

  Future<void> setThemeMode({required bool isDark}) async {
    emit(state.copyWith(isDark: isDark));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkKey, isDark);
  }
}

