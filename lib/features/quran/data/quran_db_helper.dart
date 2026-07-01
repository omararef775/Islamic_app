import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QuranDatabaseHelper {
  static final QuranDatabaseHelper instance = QuranDatabaseHelper._init();
  static Database? _database;

  QuranDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quran.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    // التحقق مما إذا كانت القاعدة موجودة مسبقاً في الهاتف
    final exists = await databaseExists(path);

    if (!exists) {
      // إذا لم تكن موجودة، نقوم بنسخها من مجلد assets
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load('assets/databases/$fileName');
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        throw Exception('خطأ في نسخ قاعدة بيانات القرآن: $e');
      }
    }

    return await openDatabase(path, readOnly: true); // نفتحها للقراءة فقط
  }

  // 🎯 دالة جلب آيات صفحة معينة
  Future<List<Map<String, dynamic>>> getVersesByPage(int pageNumber) async {
    final db = await instance.database;
    return await db.query(
      'quran',
      where: 'page = ?',
      whereArgs: [pageNumber],
      orderBy: 'aya_no ASC', // ترتيب الآيات
    );
  }
}
