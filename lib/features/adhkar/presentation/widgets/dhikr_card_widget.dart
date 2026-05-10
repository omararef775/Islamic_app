import 'package:flutter/material.dart';
import '../../domain/adhkar_model.dart';
import '../../../../core/theme/app_colors.dart';

class DhikrCardWidget extends StatelessWidget {
  final AdhkarModel dhikr;
  final VoidCallback onDecrement;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DhikrCardWidget({
    super.key,
    required this.dhikr,
    required this.onDecrement,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = dhikr.currentCount == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // 🎯 تحديث حديث: استخدام withAlpha بدلاً من withOpacity
        // 25 تعادل شفافية 10%، و 76 تعادل شفافية 30%
        color: isDone ? AppColors.primary.withAlpha(25) : AppColors.primary.withAlpha(76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // 128 تعادل شفافية 50%
          color: isDone ? Colors.green.withAlpha(128) : AppColors.primary.withAlpha(128),
          width: 1.5,
        ),
      ),
      // 🎯 استخدام Material و InkWell لإضافة تأثير التموج (Ripple Effect)
      child: Material(
        color: Colors.transparent, // شفاف لكي يظهر لون الـ AnimatedContainer من تحته
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16), // لكي لا يخرج التموج عن حواف البطاقة
          onTap: isDone ? null : onDecrement,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أزرار التعديل والحذف للأذكار المخصصة فقط
                if (dhikr.isCustom)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 22),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                
                // نص الذكر
                Center(
                  child: Text(
                    dhikr.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDone ? Colors.grey : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // العداد أو علامة الصح
                Center(
                  child: isDone
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 45)
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Text(
                            '${dhikr.currentCount}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}