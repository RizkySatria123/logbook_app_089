import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart'; // Wajib ada agar generator bisa membuat file adaptor [cite: 162]

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id; // Diubah jadi String agar Hive mudah menyimpannya secara offline [cite: 165]

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String date;

  @HiveField(4)
  final String category; // FITUR LAMA: Kategori tetap aman!

  @HiveField(5)
  final String authorId; // BARU Modul 5: ID pembuat log [cite: 190]

  @HiveField(6)
  final String teamId; // BARU Modul 5: ID kelompok kolaborasi [cite: 190]

  @HiveField(7)
  final bool isPublic; // BARU Modul 5: Status privasi data [cite: 309]

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    required this.authorId,
    required this.teamId,
    this.isPublic = false, // Default: catatan bersifat private [cite: 303]
  });

  Map<String, dynamic> toMap() => {
    // Convert kembali ke ObjectId saat mau dikirim ke MongoDB Atlas
    '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
    'title': title,
    'description': description,
    'date': date,
    'category': category,
    'authorId': authorId,
    'teamId': teamId,
    'isPublic': isPublic,
  };

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      // Ekstrak ObjectId menjadi String
      id: (map['_id'] as ObjectId?)?.toHexString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      category: map['category'] ?? 'Pribadi',
      authorId:
          map['authorId'] ?? 'unknown_user', // Cegah error null [cite: 165]
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? false,
    );
  }
}
