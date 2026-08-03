class IslamicQuranState {
  final bool isDark;
  final bool isLoading;

  const IslamicQuranState({
    this.isDark = true,
    this.isLoading = false,
  });

  IslamicQuranState copyWith({
    bool? isDark,
    bool? isLoading,
  }) {
    return IslamicQuranState(
      isDark: isDark ?? this.isDark,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
