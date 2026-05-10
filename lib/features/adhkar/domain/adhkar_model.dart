class AdhkarModel {
  final int? id;
  final String text;
  final String category;
  final int targetCount;
  final int currentCount;
  final bool isCustom; // 🎯 حولنا رقم الصفر والواحد إلى قيمة منطقية (صح/خطأ)

  // 1. المُنشئ الأساسي (Constructor)
  AdhkarModel({
    this.id,
    required this.text,
    required this.category,
    required this.targetCount,
    required this.currentCount,
    this.isCustom = false,
  });

  // 2. المترجم من قاعدة البيانات إلى التطبيق (Deserialize)
  factory AdhkarModel.fromMap(Map<String, dynamic> map) {
    return AdhkarModel(
      id: map['id'],
      text: map['text'],
      category: map['category'],
      targetCount: map['target_count'],
      currentCount: map['current_count'],
      isCustom: map['is_custom'] == 1, // إذا كان الرقم 1 يعني True، غير ذلك False
    );
  }

  // 3. المترجم من التطبيق إلى قاعدة البيانات (Serialize)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'target_count': targetCount,
      'current_count': currentCount,
      'is_custom': isCustom ? 1 : 0, // إذا كان True نخزنه كـ 1، غير ذلك 0
    };
  }

  // 4. دالة النسخ الذكي (لإدارة الحالة وتحديث العدادات)
  AdhkarModel copyWith({
    int? id,
    String? text,
    String? category,
    int? targetCount, 
    int? currentCount,
    bool? isCustom,
  }) {
    return AdhkarModel(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}