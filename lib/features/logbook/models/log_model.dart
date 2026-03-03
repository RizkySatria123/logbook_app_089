import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id; // Wajib untuk identitas unik di Cloud [cite: 753, 755]
  final String title;
  final String description;
  final String date;
  final String category;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
  });

  // Membongkar data dari Cloud menjadi objek Flutter [cite: 752, 756]
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      category: map['category'] ?? 'Pribadi',
    );
  }

  // Memasukkan data ke Map untuk dikirim ke Cloud [cite: 752, 756]
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'title': title,
      'description': description,
      'date': date,
      'category': category,
    };
  }
}
