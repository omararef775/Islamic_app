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

class _AdhkarScreenState extends State<AdhkarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AdhkarCubit>().loadAdhkar('morning');
    
    _tabController.addListener(() {
      if (_tabController.index != _lastIndex && !_tabController.indexIsChanging) {
        _lastIndex = _tabController.index;
        _fetchAdhkarByIndex(_lastIndex);
        // 🎯 تم إزالة setState(() {}) من هنا لمنع إعادة بناء الشاشة بالكامل
      }
    });
  }

  void _fetchAdhkarByIndex(int index) {
    if (index == 0) {
      context.read<AdhkarCubit>().loadAdhkar('morning');
    } else if (index == 1) {
      context.read<AdhkarCubit>().loadAdhkar('evening');
    } else if (index == 2) {
      context.read<AdhkarCubit>().loadAdhkar('custom');
    }
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
        title: const Text('الأذكار', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (state is AdhkarError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is AdhkarLoaded) {
            
            if (state.adhkar.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد أذكار هنا بعد.\nأضف أذكارك الخاصة!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
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
                  onDecrement: () => context.read<AdhkarCubit>().decrementDhikr(dhikr, state.currentCategory),
                  onEdit: dhikr.isCustom ? () => _showCustomDhikrSheet(context, dhikrToEdit: dhikr) : null,
                  onDelete: dhikr.isCustom ? () => context.read<AdhkarCubit>().deleteCustomDhikr(dhikr.id!) : null,
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
      
      // 🎯 هندسة الأداء: ربط الزر العائم بمراقب حركة ذكي لا يعيد بناء كامل الشاشة
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return _tabController.index == 2
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  onPressed: () => _showCustomDhikrSheet(context),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  // النافذة السفلية العصرية لإضافة/تعديل الذكر المخصص
  void _showCustomDhikrSheet(BuildContext context, {AdhkarModel? dhikrToEdit}) {
    final cubit = context.read<AdhkarCubit>();
    final isEditing = dhikrToEdit != null;
    final textController = TextEditingController(text: isEditing ? dhikrToEdit.text : '');
    final countController = TextEditingController(text: isEditing ? dhikrToEdit.targetCount.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) { 
        return BlocProvider.value(
          value: cubit,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              left: 24, right: 24, top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'تعديل الذكر' : 'إضافة ذكر جديد',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: textController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'نص الذكر',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary.withAlpha(128)), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'عدد التكرار',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary.withAlpha(128)), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final text = textController.text.trim();
                      final count = int.tryParse(countController.text.trim()) ?? 0;
                      if (text.isNotEmpty && count > 0) {
                        if (isEditing) {
                          cubit.updateCustomDhikr(dhikrToEdit.id!, text, count);
                        } else {
                          cubit.addCustomDhikr(text, count);
                        }
                        Navigator.pop(sheetContext);
                      }
                    },
                    child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة', style: const TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}