class LogModel {
  final String title;
  final String date;
  final String description;
  final String category; // BARU: Tambahan untuk Homework

  LogModel({
    required this.title,
    required this.date,
    required this.description,
    this.category = 'Pribadi', // Default agar data lama tidak error
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Pribadi', // Baca kategori dari JSON
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'description': description,
      'category': category, // Simpan kategori ke JSON
    };
  }
}
