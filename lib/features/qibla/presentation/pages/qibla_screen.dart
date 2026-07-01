import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:permission_handler/permission_handler.dart';

import '../manager/qiblah_cubit.dart';
import '../manager/qiblah_state.dart';
import '../../../../core/theme/app_colors.dart';

// ==============================================================
// 🕋 شاشة القبلة الرئيسية (StatefulWidget للتحكم في تنعيم الحركة)
// ==============================================================
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  // 🎯 قيم التنعيم الحالية
  double _smoothedCompass = 0.0;
  double _smoothedNeedle = 0.0;
  bool _isFirstReading = true; // لتهيئة القيم من أول قراءة حقيقية فوراً

  // 🎯 عامل التنعيم: (0.15 = متوازن بين السلاسة والاستجابة)
  static const double _alpha = 0.15;

  /// تطبيع أي زاوية لتكون دائماً في نطاق [0, 360)
  double _normalize(double angle) {
    return ((angle % 360) + 360) % 360;
  }

  /// خوارزمية Low-Pass Filter مع معالجة القفز الزاوي (مثال: 359°→1°)
  double _lowPass(double newValue, double prevValue) {
    newValue = _normalize(newValue);
    prevValue = _normalize(prevValue);
    double diff = newValue - prevValue;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return _normalize(prevValue + _alpha * diff);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'اتجاه القبلة',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<QiblaCubit, QiblaState>(
        builder: (context, state) {
          // ── حالة التحميل والانتظار ──
          if (state is QiblaLoading || state is QiblaInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // ── حالة عدم وجود مستشعر في الهاتف ──
          if (state is QiblaNoSensor) {
            return _buildMessage(
              context: context,
              icon: Icons.compass_calibration_outlined,
              message: state.message,
            );
          }

          // ── حالة الخطأ (صلاحيات أو GPS) ──
          if (state is QiblaError) {
            return _buildMessage(
              context: context,
              icon: Icons.location_off_rounded,
              message: state.message,
              showSettingsButton: state.isPermissionError,
              showGpsButton: !state.isPermissionError,
            );
          }

          // ── الحالة الجاهزة: تشغيل البوصلة ──
          if (state is QiblaReady) {
            return StreamBuilder<QiblahDirection>(
              stream: FlutterQiblah.qiblahStream,
              builder: (context, snapshot) {
                // انتظار أول قراءة من المستشعر
                if (!snapshot.hasData ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'جاري قراءة المستشعر...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final qd = snapshot.data!;

                // 🛡️ فحص صحة البيانات القادمة من المستشعر
                if (qd.direction.isNaN || qd.qiblah.isNaN) {
                  return _buildMessage(
                    context: context,
                    icon: Icons.explore_off_outlined,
                    message:
                        'المستشعر يحتاج معايرة\nحرّك هاتفك ببطء على شكل رقم 8 (∞)',
                    showRetryButton: true,
                  );
                }

                // ============================================================
                // 🎯 المعادلة الصحيحة النهائية:
                //
                // من مصدر المكتبة:
                //   offset  = زاوية مكة الثابتة من الشمال الجغرافي (بالموقع فقط)
                //   direction = اتجاه الهاتف الحالي من الشمال المغناطيسي
                //   qiblah  = direction + (360 - offset)  ← تجميع المكتبة
                //
                // الطريقة الأكثر وضوحاً وصحة:
                //   ─ إطار البوصلة يدور بـ (-direction) ← يبقي الشمال ثابتاً فوق
                //   ─ مؤشر مكة يشير لـ (offset) من الشمال ← لأن offset = bearing إلى مكة
                //     لكن بما أن إطار البوصلة نفسه يدور، نطبق:
                //     needleAngle = offset - direction  (الزاوية النسبية للمؤشر داخل الإطار
                //                                        المتحرك)
                //
                // ملاحظة: هذا مكافئ تماماً لـ (qiblah * pi/180 * -1) لكن بدون تراكم القيم
                // ============================================================

                // تهيئة القيم من أول قراءة حقيقية لتجنب القفز عند البداية
                final double rawCompass = _normalize(qd.direction);
                // الزاوية التي يجب أن يشير إليها المؤشر نسبةً للشمال (= offset from North)
                final double rawNeedle = _normalize(qd.offset - qd.direction);

                if (_isFirstReading) {
                  _smoothedCompass = rawCompass;
                  _smoothedNeedle = rawNeedle;
                  _isFirstReading = false;
                } else {
                  _smoothedCompass = _lowPass(rawCompass, _smoothedCompass);
                  _smoothedNeedle = _lowPass(rawNeedle, _smoothedNeedle);
                }

                final double compassRad =
                    _smoothedCompass * (math.pi / 180) * -1;
                final double needleRad =
                    _smoothedNeedle * (math.pi / 180);

                return _buildCompassView(
                  compassRad: compassRad,
                  needleRad: needleRad,
                  offsetDegrees: qd.offset,
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ==============================================================
  // 🧭 بناء واجهة البوصلة الرئيسية
  // ==============================================================
  Widget _buildCompassView({
    required double compassRad,
    required double needleRad,
    required double offsetDegrees,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── البوصلة المرسومة بـ CustomPainter (بدون صور ببخلفية بيضاء) ──
          RepaintBoundary(
            child: SizedBox(
              width: 290,
              height: 290,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // الطبقة 1: إطار البوصلة (يدور لإبقاء الشمال ثابتاً)
                  Transform.rotate(
                    angle: compassRad,
                    child: CustomPaint(
                      size: const Size(290, 290),
                      painter: _CompassFacePainter(),
                    ),
                  ),

                  // الطبقة 2: مؤشر القبلة (يشير نحو مكة في كل الأحوال)
                  Transform.rotate(
                    angle: needleRad,
                    child: CustomPaint(
                      size: const Size(290, 290),
                      painter: _QiblaNeedlePainter(),
                    ),
                  ),

                  // الطبقة 3: النقطة المركزية
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(150),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 36),

          // ── بطاقة معلومات الاتجاه ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withAlpha(80),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'زاوية القبلة من الشمال',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${offsetDegrees.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mosque_rounded,
                        color: AppColors.primary, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'استدر حتى يشير الذهبي نحو الأعلى',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 🧩 واجهة الرسائل (أخطاء، معايرة، صلاحيات)
  // ==============================================================
  Widget _buildMessage({
    required BuildContext context,
    required IconData icon,
    required String message,
    bool showSettingsButton = false,
    bool showGpsButton = false,
    bool showRetryButton = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.withAlpha(140)),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // زر فتح إعدادات التطبيق (لصلاحية الموقع المرفوضة)
            if (showSettingsButton)
              _buildActionButton(
                icon: Icons.settings_rounded,
                label: 'فتح الإعدادات',
                onPressed: () async {
                  await openAppSettings();
                  if (context.mounted) {
                    context
                        .read<QiblaCubit>()
                        .checkPermissionsAndInitialize();
                  }
                },
              ),

            // زر إعادة المحاولة (لمشكلة GPS)
            if (showGpsButton)
              _buildActionButton(
                icon: Icons.gps_fixed_rounded,
                label: 'إعادة المحاولة',
                onPressed: () {
                  context
                      .read<QiblaCubit>()
                      .checkPermissionsAndInitialize();
                },
              ),

            // زر إعادة المعايرة (لمشكلة المستشعر)
            if (showRetryButton)
              _buildActionButton(
                icon: Icons.refresh_rounded,
                label: 'إعادة المعايرة',
                onPressed: () {
                  context
                      .read<QiblaCubit>()
                      .checkPermissionsAndInitialize();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.background, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.background,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ==============================================================
// 🎨 رسام وجه البوصلة (الإطار الخارجي مع الدرجات والاتجاهات)
// ==============================================================
class _CompassFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // الحلقة الخارجية الذهبية
    canvas.drawCircle(
      center,
      radius - 3,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // الحلقة الداخلية الخفيفة
    canvas.drawCircle(
      center,
      radius - 22,
      Paint()
        ..color = AppColors.primary.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // رسم علامات الدرجات (كل 5 درجات)
    for (int deg = 0; deg < 360; deg += 5) {
      final angleRad = deg * math.pi / 180;
      final isMajor = deg % 90 == 0; // 0, 90, 180, 270
      final isSemi = deg % 45 == 0 && !isMajor; // 45, 135, 225, 315
      final tickLen = isMajor ? 18.0 : (isSemi ? 12.0 : 6.0);
      final tickWidth = isMajor ? 2.5 : (isSemi ? 1.5 : 0.8);
      final tickColor = isMajor
          ? AppColors.primary
          : AppColors.primary.withAlpha(isSemi ? 160 : 80);

      final sinA = math.sin(angleRad);
      final cosA = math.cos(angleRad);
      final outerR = radius - 4;

      canvas.drawLine(
        Offset(center.dx + outerR * sinA, center.dy - outerR * cosA),
        Offset(
          center.dx + (outerR - tickLen) * sinA,
          center.dy - (outerR - tickLen) * cosA,
        ),
        Paint()
          ..color = tickColor
          ..strokeWidth = tickWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // رسم حروف الاتجاهات الأربعة
    const labels = ['N', 'E', 'S', 'W'];
    const angles = [0.0, math.pi / 2, math.pi, -math.pi / 2];
    final labelRadius = radius - 40;

    for (int i = 0; i < 4; i++) {
      final isNorth = i == 0;
      final lx = center.dx + labelRadius * math.sin(angles[i]);
      final ly = center.dy - labelRadius * math.cos(angles[i]);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            // الشمال باللون الأحمر (تقليد البوصلات الحقيقية)
            color: isNorth ? Colors.redAccent : AppColors.primary,
            fontSize: isNorth ? 19 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(lx - tp.width / 2, ly - tp.height / 2),
      );
    }
  }

  // الإطار لا يتغير → shouldRepaint = false لأداء ممتاز
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==============================================================
// 🕌 رسام مؤشر القبلة (السهم الذهبي نحو مكة المكرمة)
// ==============================================================
class _QiblaNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final goldPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final dimPaint = Paint()
      ..color = AppColors.primary.withAlpha(90)
      ..style = PaintingStyle.fill;

    // ── السهم الرئيسي (نحو مكة، يشير للأعلى) ──
    final arrowTip = Offset(center.dx, center.dy - (radius - 48));
    final arrowLeft = Offset(center.dx - 10, center.dy - 18);
    final arrowRight = Offset(center.dx + 10, center.dy - 18);
    final arrowBaseCenter = Offset(center.dx, center.dy - 8);

    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowLeft.dx, arrowLeft.dy)
      ..lineTo(arrowBaseCenter.dx, arrowBaseCenter.dy)
      ..lineTo(arrowRight.dx, arrowRight.dy)
      ..close();

    // ظل خفيف للعمق
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = AppColors.primary.withAlpha(50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(arrowPath, goldPaint);

    // ── ذيل السهم (الجهة المعاكسة، بلون خافت) ──
    final tailTip = Offset(center.dx, center.dy + (radius - 60));
    final tailLeft = Offset(center.dx - 7, center.dy + 18);
    final tailRight = Offset(center.dx + 7, center.dy + 18);
    final tailBaseCenter = Offset(center.dx, center.dy + 8);

    final tailPath = Path()
      ..moveTo(tailTip.dx, tailTip.dy)
      ..lineTo(tailLeft.dx, tailLeft.dy)
      ..lineTo(tailBaseCenter.dx, tailBaseCenter.dy)
      ..lineTo(tailRight.dx, tailRight.dy)
      ..close();

    canvas.drawPath(tailPath, dimPaint);

    // ── رمز الكعبة الصغير عند رأس السهم ──
    final kaabaCenter =
        Offset(center.dx, center.dy - (radius - 34));
    final kaabaRect = Rect.fromCenter(
      center: kaabaCenter,
      width: 20,
      height: 15,
    );

    // جسم الكعبة (مستطيل داكن)
    canvas.drawRRect(
      RRect.fromRectAndRadius(kaabaRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF1A2744),
    );

    // الحزام الذهبي للكعبة
    canvas.drawRect(
      Rect.fromLTWH(
        kaabaRect.left,
        kaabaCenter.dy - 2,
        kaabaRect.width,
        3,
      ),
      Paint()..color = AppColors.primary,
    );

    // حدود ذهبية للكعبة
    canvas.drawRRect(
      RRect.fromRectAndRadius(kaabaRect, const Radius.circular(2)),
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  // المؤشر لا يتغير شكله، فقط موضعه الزاوي يتغير → shouldRepaint = false
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}