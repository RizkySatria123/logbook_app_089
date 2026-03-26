import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Matrix perizinan: Ketua bisa semua, Anggota hanya bisa Create & Read
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota': [actionCreate, actionRead],
  };

  // Fungsi utama penjaga gerbang
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    final permissions = _rolePermissions[role] ?? [];
    bool hasBasicPermission = permissions.contains(action);

    // Aturan tambahan: Anggota hanya bisa Update/Delete jika dia pemilik data
    if (role == 'Anggota' &&
        (action == actionUpdate || action == actionDelete)) {
      return isOwner;
    }

    return hasBasicPermission;
  }
}
