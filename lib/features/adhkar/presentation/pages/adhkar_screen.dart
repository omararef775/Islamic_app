import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../manager/adhkar_cubit.dart';
import '../manager/adhkar_state.dart';
import '../widgets/dhikr_card_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/adhkar_model.dart';

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _lastIndex = 0;

  // 🎯 خريطة تربط رقم التبويب بالفئة الفعلية في قاعدة البيانات
  final Map<int, String> _tabToCategory = {
    0: 'morning',
    1: 'evening',
    2: 'custom',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AdhkarCubit>().loadAdhkar('morning');

    _tabController.addListener(() {
      if (_tabController.index != _lastIndex && !_tabController.indexIsChanging) {
        _lastIndex = _tabController.index;
        _fetchAdhkarByIndex(_lastIndex);
      }
    });
  }

  void _fetchAdhkarByIndex(int index) {
    final category = _tabToCategory[index] ?? 'morning';
    context.read<AdhkarCubit>().loadAdhkar(category);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'الأذكار',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'الصباح'),
            Tab(text: 'المساء'),
            Tab(text: 'أذكاري'),
          ],
        ),
      ),

      body: BlocBuilder<AdhkarCubit, AdhkarState>(
        builder: (context, state) {
          if (state is AdhkarLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          } else if (state is AdhkarError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (state is AdhkarLoaded) {
            if (state.adhkar.isEmpty) {
              // 🎯 رسالة مناسبة لكل فئة
              final isCustomTab = state.currentCategory == 'custom';
              final emptyMessage = isCustomTab
                  ? 'لا توجد أذكار مخصصة بعد.\nاضغط + لإضافة ذكرك الأول!'
                  : 'لا توجد أذكار مضافة في هذا القسم بعد.\nاضغط + لإضافة ذكر جديد!';

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 60,
                      color: Colors.grey.withAlpha(180),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              itemCount: state.adhkar.length,
              itemBuilder: (context, index) {
                final dhikr = state.adhkar[index];
                return DhikrCardWidget(
                  dhikr: dhikr,
                  onDecrement: () => context
                      .read<AdhkarCubit>()
                      .decrementDhikr(dhikr, state.currentCategory),
                  // 🎯 أزرار التعديل والحذف للأذكار المخصصة فقط (التي أضافها المستخدم)
                  onEdit: dhikr.isCustom
                      ? () => _showDhikrSheet(
                            context,
                            currentCategory: state.currentCategory,
                            dhikrToEdit: dhikr,
                          )
                      : null,
                  onDelete: dhikr.isCustom
                      ? () => context
                          .read<AdhkarCubit>()
                          .deleteCustomDhikr(dhikr.id!, state.currentCategory)
                      : null,
                );
              },
            );
          }
          return const SizedBox();
        },
      ),

      // 🎯 زر الإضافة يظهر في كل التبويبات الثلاثة
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return FloatingActionButton(
            backgroundColor: AppColors.primary,
            // 🎯 نمرر الفئة الحالية للتبويب المفتوح لتحديدها تلقائياً في النافذة
            onPressed: () => _showDhikrSheet(
              context,
              currentCategory: _tabToCategory[_tabController.index] ?? 'morning',
            ),
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  /// نافذة الإضافة والتعديل الموحّدة
  /// [currentCategory] → القسم الحالي (لتحديده تلقائياً عند الفتح)
  /// [dhikrToEdit]     → إذا مُرِّر يعني وضع التعديل، وإلا وضع الإضافة
  void _showDhikrSheet(
    BuildContext context, {
    required String currentCategory,
    AdhkarModel? dhikrToEdit,
  }) {
    final cubit = context.read<AdhkarCubit>();
    final isEditing = dhikrToEdit != null;

    final textController =
        TextEditingController(text: isEditing ? dhikrToEdit.text : '');
    final countController = TextEditingController(
      text: isEditing ? dhikrToEdit.targetCount.toString() : '',
    );

    // 🎯 القسم المختار: في وضع التعديل يبقى قسم الذكر الأصلي؛
    //    في وضع الإضافة يبدأ من القسم المفتوح حالياً
    String selectedCategory =
        isEditing ? dhikrToEdit.category : currentCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── العنوان ──
                    Center(
                      child: Text(
                        isEditing ? 'تعديل الذكر' : 'إضافة ذكر جديد',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── اختيار القسم (يُخفى في وضع التعديل) ──
                    if (!isEditing) ...[
                      const Text(
                        'أضف إلى:',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _CategoryChip(
                            label: '☀️ الصباح',
                            value: 'morning',
                            selectedValue: selectedCategory,
                            onSelected: (val) =>
                                setSheetState(() => selectedCategory = val),
                          ),
                          const SizedBox(width: 8),
                          _CategoryChip(
                            label: '🌙 المساء',
                            value: 'evening',
                            selectedValue: selectedCategory,
                            onSelected: (val) =>
                                setSheetState(() => selectedCategory = val),
                          ),
                          const SizedBox(width: 8),
                          _CategoryChip(
                            label: '⭐ أذكاري',
                            value: 'custom',
                            selectedValue: selectedCategory,
                            onSelected: (val) =>
                                setSheetState(() => selectedCategory = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── حقل نص الذكر ──
                    TextField(
                      controller: textController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: 3,
                      minLines: 1,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'نص الذكر',
                        labelStyle: const TextStyle(color: Colors.grey),
                        alignLabelWithHint: true,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary.withAlpha(128),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── حقل عدد التكرار ──
                    TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'عدد التكرار',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary.withAlpha(128),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── زر الحفظ / الإضافة ──
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final text = textController.text.trim();
                          final count =
                              int.tryParse(countController.text.trim()) ?? 0;

                          if (text.isNotEmpty && count > 0) {
                            if (isEditing) {
                              // 🎯 التعديل: نمرر الفئة الأصلية لإعادة تحميل القسم الصحيح
                              cubit.updateCustomDhikr(
                                dhikrToEdit.id!,
                                text,
                                count,
                                dhikrToEdit.category,
                              );
                            } else {
                              // 🎯 الإضافة: نمرر الفئة التي اختارها المستخدم
                              cubit.addCustomDhikr(text, count, selectedCategory);
                            }
                            Navigator.pop(sheetContext);
                          }
                        },
                        child: Text(
                          isEditing ? 'حفظ التعديلات' : 'إضافة',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Widget مستقل لزر اختيار الفئة ──
class _CategoryChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _CategoryChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withAlpha(80),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}