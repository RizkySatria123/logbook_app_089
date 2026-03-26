class AccessControlService {
  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    // TASK 5: KEDAULATAN DATA (Sovereignty)
    // Tidak peduli dia Ketua atau Anggota, HANYA PEMILIK yang boleh Edit/Hapus
    if (action == actionUpdate || action == actionDelete) {
      return isOwner;
    }
    // Untuk Read dan Create, semua diizinkan (visibilitasnya nanti difilter di UI)
    return true;
  }
}
