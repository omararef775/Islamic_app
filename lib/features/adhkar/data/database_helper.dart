import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // 1. نمط النسخة الواحدة (Singleton Pattern)
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // 2. دالة الاتصال بقاعدة البيانات
  Future<Database> get database async {
    // إذا كانت قاعدة البيانات مفتوحة مسبقاً، أعدها فوراً (لتوفير الذاكرة)
    if (_database != null) return _database!;
    // إذا لم تكن مفتوحة، قم بإنشائها أو فتحها
    _database = await _initDB('islamic_app.db');
    return _database!;
  }

  // 3. دالة تحديد المسار والإنشاء
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath(); // يجلب المسار المخفي الآمن في الأندرويد
    final path = join(dbPath, filePath); // يدمج المسار مع اسم الملف

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB, // تعمل هذه الدالة مرة واحدة فقط عند تثبيت التطبيق
    );
  }

Future _createDB(Database db, int version) async {
    // 1. إنشاء الجدول
    await db.execute('''
    CREATE TABLE adhkar (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      text TEXT NOT NULL,
      category TEXT NOT NULL,
      target_count INTEGER NOT NULL,
      current_count INTEGER NOT NULL,
      is_custom INTEGER NOT NULL DEFAULT 0
    )
    ''');

    // 2. حقن الأذكار الأساسية فور إنشاء الجدول
    await _insertInitialAdhkar(db);
  }

  // دالة الحقن الشاملة لأذكار الصباح والمساء (بالنصوص الكاملة والصحيحة)
  Future _insertInitialAdhkar(Database db) async {
    // ☀️ قائمة أذكار الصباح الكاملة
    final morningAdhkar = [
      {
        'text': '''أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ
اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ وَلَا يَئُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ''',
        'category': 'morning', 'target_count': 1, 'current_count': 1, 'is_custom': 0
      },
      {
        'text': '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ''',
        'category': 'morning', 'target_count': 3, 'current_count': 3, 'is_custom': 0
      },
      {
        'text': '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِنْ شَرِّ مَا خَلَقَ ۝ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ''',
        'category': 'morning', 'target_count': 3, 'current_count': 3, 'is_custom': 0
      },
      {
        'text': '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَهِ النَّاسِ ۝ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ''',
        'category': 'morning', 'target_count': 3, 'current_count': 3, 'is_custom': 0
      },
      {
        'text': '''أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ''',
        'category': 'morning', 'target_count': 1, 'current_count': 1, 'is_custom': 0
      },
      {
        'text': '''اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إلاَّ أَنْتَ''',
        'category': 'morning', 'target_count': 1, 'current_count': 1, 'is_custom': 0
      },
      {
        'text': '''اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ وَمِنْ خَلْفِي وَعَنْ يَمِينِي وَعَنْ شِمَالِي وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي''',
        'category': 'morning', 'target_count': 1, 'current_count': 1, 'is_custom': 0
      },
      {
        'text': 'بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ', 
        'category': 'morning', 'target_count': 3, 'current_count': 3, 'is_custom': 0
      },
      {
        'text': 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالإِسْلاَمِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا', 
        'category': 'morning', 'target_count': 3, 'current_count': 3, 'is_custom': 0
      },
      {
        'text': 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ', 
        'category': 'morning', 'target_count': 1, 'current_count': 1, 'is_custom': 0
      },
      {
        'text': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 
        'category': 'morning', 'target_count': 100, 'current_count': 100, 'is_custom': 0
      },
      {
        'text': 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ', 
        'category': 'morning', 'target_count': 100, 'current_count': 100, 'is_custom': 0
      },
    ];

    // 🌙 قائمة أذكار المساء الكاملة
    final eveningAdhkar = [
      {
        'text': '''أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ
اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ وَلَا يَئُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ''',
        'category': 'evening', 'target_count': 1, 'current_count': 1, 'is_custom': 0
      },
      {
        'text': '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ''',
        'category': 'evening', 'target_count': 3, 'current_count': 3, 'is_custom': 0
      },
      {
        'text': '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِنْ شَرِّ مَا خَلَقَ ۝ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ''',
        'category': 'evening', 'target_count': 3, 'current_count': 3, 'is_custom': 0
      },
      {
        'text': '''بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَهِ النَّاسِ ۝ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ''',
        'category': 'evening', 'target_count': 3, 'current_count': 3, 'is_custom': 0
      },
      {
        'text': '''أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ''',
        'category': 'evening', 'target_count': 1, 'current_count': 1, 'is_custom': 0
      },
      {
        'text': '''اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إلاَّ أَنْتَ''',
        'category': 'evening', 'target_count': 1, 'current_count': 1, 'is_custom': 0
      },
      {
        'text': '''اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ وَمِنْ خَلْفِي وَعَنْ يَمِينِي وَعَنْ شِمَالِي وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي''',
        'category': 'evening', 'target_count': 1, 'current_count': 1, 'is_custom': 0
      },
      {
        'text': 'بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ', 
        'category': 'evening', 'target_count': 3, 'current_count': 3, 'is_custom': 0
      },
      {
        'text': 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالإِسْلاَمِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا', 
        'category': 'evening', 'target_count': 3, 'current_count': 3, 'is_custom': 0
      },
      {
        'text': 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ', 
        'category': 'evening', 'target_count': 1, 'current_count': 1, 'is_custom': 0
      },
      {
        'text': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 
        'category': 'evening', 'target_count': 100, 'current_count': 100, 'is_custom': 0
      },
      {
        'text': 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ', 
        'category': 'evening', 'target_count': 100, 'current_count': 100, 'is_custom': 0
      },
    ];

    // 🚀 تنفيذ الإدخال الآمن (Batch Insert)
    Batch batch = db.batch();
    for (var dhikr in morningAdhkar) {
      batch.insert('adhkar', dhikr);
    }
    for (var dhikr in eveningAdhkar) {
      batch.insert('adhkar', dhikr);
    }
    await batch.commit(noResult: true);
  }


  // إضافة ذكر جديد (للأذكار الأساسية والمخصصة)
  Future<int> insertDhikr(Map<String, dynamic> dhikr) async {
    final db = await instance.database;
    return await db.insert('adhkar', dhikr);
  }

  // قراءة الأذكار حسب الفئة (صباح، مساء، مخصص)
  Future<List<Map<String, dynamic>>> getAdhkarByCategory(String category) async {
    final db = await instance.database;
    return await db.query(
      'adhkar',
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  // تحديث العداد الحالي (عندما يضغط المستخدم على البطاقة)
  Future<int> updateCurrentCount(int id, int newCount) async {
    final db = await instance.database;
    return await db.update(
      'adhkar',
      {'current_count': newCount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // تصفير جميع العدادات (خوارزمية بداية اليوم الجديد)
  Future<int> resetAllCounters() async {
    final db = await instance.database;
    // هذا الأمر يجعل العداد الحالي يساوي العداد المستهدف لجميع الأذكار
    return await db.rawUpdate('''
      UPDATE adhkar 
      SET current_count = target_count
    ''');
  }

  // تعديل نص أو عدد ذكر مخصص 
  Future<int> updateCustomDhikr(int id, String newText, int newTarget) async {
    final db = await instance.database;
    return await db.update(
      'adhkar',
      {
        'text': newText,
        'target_count': newTarget,
        'current_count': newTarget // نعيد ضبطه للرقم الجديد
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // حذف ذكر مخصص نهائياً
  Future<int> deleteDhikr(int id) async {
    final db = await instance.database;
    return await db.delete(
      'adhkar',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}