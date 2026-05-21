class AyahModel {
  final int id;
  final int jozz;
  final int sora;
  final String soraNameAr;
  final int page;
  final int ayaNo;
  final String text; // aya_text
  final String textEmlaey; 
  final String maany;
  final String tafseerSaadi;
  final String reasonsOfRevelation;

  AyahModel({
    required this.id,
    required this.jozz,
    required this.sora,
    required this.soraNameAr,
    required this.page,
    required this.ayaNo,
    required this.text,
    required this.textEmlaey,
    required this.maany,
    required this.tafseerSaadi,
    required this.reasonsOfRevelation,
  });

  factory AyahModel.fromMap(Map<String, dynamic> map) {
    return AyahModel(
      id: map['id'] ?? 0,
      jozz: map['jozz'] ?? 0,
      sora: map['sora'] ?? 0,
      soraNameAr: map['sora_name_ar'] ?? '',
      page: map['page'] ?? 0,
      ayaNo: map['aya_no'] ?? 0,
      text: map['aya_text'] ?? '',
      textEmlaey: map['aya_text_emlaey'] ?? '',
      maany: map['maany_aya'] ?? 'لا يوجد معاني متوفرة.',
      tafseerSaadi: map['tafseer_saadi'] ?? 'لا يوجد تفسير متوفر.',
      reasonsOfRevelation: map['reasons_of_verses'] ?? '',
    );
  }
}