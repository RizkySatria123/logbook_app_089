import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_089/features/logbook/models/log_model.dart';

void main() {
  test('RBAC Security Check: Private logs should NOT be visible to teammates', () {
    // ---------------------------------------------------------
    // 1. SETUP DATA (Membangun Skenario)
    // ---------------------------------------------------------
    // Ceritanya, User A ("Rizky Satria") memiliki 2 catatan di database:
    final logPrivateRizky = LogModel(
      title: "Rahasia Rizky",
      description: "Ide project rahasia",
      date: "2026-03-30",
      category: "Pribadi",
      authorId: "Rizky Satria", // <-- Nama diubah jadi Rizky Satria
      teamId: "KELOMPOK_1",
      isPublic: false, // 🔴 STATUS: PRIVATE
    );

    final logPublicRizky = LogModel(
      title: "Laporan Kelompok",
      description: "Progres bab 1",
      date: "2026-03-30",
      category: "Pekerjaan",
      authorId: "Rizky Satria", // <-- Nama diubah jadi Rizky Satria
      teamId: "KELOMPOK_1",
      isPublic: true, // 🟢 STATUS: PUBLIC
    );

    // Anggap ini adalah tumpukan data mentah yang ditarik dari MongoDB
    List<LogModel> allLogsFromDB = [logPrivateRizky, logPublicRizky];

    // ---------------------------------------------------------
    // 2. ACTION (Tindakan)
    // ---------------------------------------------------------
    // Sekarang, User B ("Iksan Satriadi") sedang login dan membuka aplikasi
    String currentLoggedInUser =
        "Iksan Satriadi"; // <-- User yang login adalah Iksan

    // Ini adalah simulasi logika filter "Gatekeeper" yang ada di log_view.dart kita
    List<LogModel> visibleLogsForIksan = allLogsFromDB.where((log) {
      return log.authorId == currentLoggedInUser || log.isPublic == true;
    }).toList();

    // ---------------------------------------------------------
    // 3. ASSERT (Validasi & Pembuktian)
    // ---------------------------------------------------------
    // Iksan BUKAN Rizky, jadi Iksan HANYA boleh melihat 1 catatan (yang Public)
    expect(
      visibleLogsForIksan.length,
      1,
      reason:
          "GAGAL: Iksan Satriadi seharusnya hanya bisa melihat 1 catatan publik!",
    );

    // Pastikan catatan yang berhasil dilihat Iksan benar-benar yang 'Laporan Kelompok'
    expect(
      visibleLogsForIksan.first.title,
      "Laporan Kelompok",
      reason:
          "KEBOCORAN DATA: Catatan rahasia Rizky Satria bocor ke Iksan Satriadi!",
    );

    // Pastikan status catatan tersebut memang public
    expect(visibleLogsForIksan.first.isPublic, true);
  });
}
