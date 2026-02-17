# logbook_app_089
Tugas Pemrograman Mobile - Politeknik Negeri Bandung

## Deskripsi Tugas

---

## 📂 MODUL 1: Basic Counter Logic

### Task 1: The Multi-Step Counter (Low Order Thinking - LOTS)
**Fokus:** Implementasi logika dasar dan manipulasi variabel.
Modifikasi aplikasi Counter agar memiliki nilai **"Step"** (Langkah) yang dinamis.

**Spesifikasi & Kriteria:**
- [x] **Controller:** Menambahkan variabel `_step` (default: 1) dan fungsi untuk mengubah nilainya.
- [x] **Logic:** Fungsi `increment` dan `decrement` menggunakan nilai `_step`.
- [x] **View:** Menambahkan `TextField` pada `CounterView` untuk menentukan besarnya nilai step.

### Task 2: The History Logger (High Order Thinking - HOTS)
**Fokus:** Analisis struktur data dan manajemen state.
Fitur "Riwayat" sederhana untuk mencatat aktivitas pengguna.

**Spesifikasi & Kriteria:**
- [x] **Analysis:** Menggunakan tipe data `List<String>` atau `List<Object>` untuk menampung riwayat.
- [x] **Controller:** Implementasi List private. Setiap aksi otomatis menambahkan catatan baru.
- [x] **Twist:** Logika agar riwayat dibatasi (misal: 5 aktivitas terakhir).

---

## 🔐 MODUL 2: Authentication & Navigation

Pada modul ini, aplikasi menerapkan arsitektur **Modular** (`features/auth`, `features/logbook`, `features/onboarding`) dan bertindak sebagai Gatekeeper.

### Task 1: Tugas Pendahuluan (UI & Assets)
**Fokus:** Persiapan aset dan Onboarding.

**Implementasi:**
- [x] **Assets:** Menambahkan gambar ilustrasi ke dalam folder `assets/images` dan mendaftarkannya di `pubspec.yaml`.
- [x] **Onboarding:** Membuat halaman pengenalan dengan navigasi `pushReplacement` menuju Login.

### Task 2: The Login Portal (LOTS)
**Fokus:** Validasi Input, Security Logic, dan Multiple Users.

**Spesifikasi & Kriteria:**
- [x] **Multiple Users:** Controller menggunakan `Map<String, String>` untuk menyimpan banyak akun (contoh: admin, budi).
- [x] **Security:** Jika salah password 3 kali, tombol login terkunci (disabled) selama 10 detik.
- [x] **UX:** Fitur *Show/Hide Password* (ikon mata) dan Validasi Form (tidak boleh kosong).

### Task 3: Persistent History Logger (HOTS)
**Fokus:** Data Persistence (Shared Preferences) dan JSON Serialization.

**Spesifikasi & Kriteria:**
- [x] **Persistence:** Menggunakan library `shared_preferences` agar data angka dan riwayat **tidak hilang** saat aplikasi ditutup/restart.
- [x] **Serialization:** Mengubah data Objek Riwayat menjadi JSON String agar bisa disimpan di memori lokal.
- [x] **Integration:** Mengirimkan nama user (`username`) dari halaman Login ke Counter untuk dicatat di riwayat (Passing Data).

---

## 📸 Screenshots

### Modul 1: Counter & Logic
| Multi-Step Counter | History Logger |
|:---:|:---:|
| ![Task 1 Modul 1](gambar_praktikum/IMG1.png) | ![Task 2 Modul 1](gambar_praktikum/IMG2.png) |
### Modul 2: Auth & Persistence
| Halaman Login | Halaman Counter (User) | Alert Logout |
|:---:|:---:|:---:|
| ![Login View](gambar_praktikum/Gambar1.jpeg) | ![Counter View](gambar_praktikum/Gambar2.jpeg) | ![Logout Dialog](gambar_praktikum/Gambar6.peg) |

---

## 🧠 Self Reflection (Lesson Learnt)

### Modul 1
Prinsip SRP membuat logika counter dan pencatatan riwayat terpisah di `CounterController`.

### Modul 2
1. **Arsitektur Modular:** Memisahkan fitur ke dalam folder `features/` membuat kode lebih rapi, meskipun harus teliti dalam mengatur *import path*.
2. **Navigation Stack:** Memahami perbedaan `pushReplacement` (untuk Login) dan `pushAndRemoveUntil` (untuk Logout) sangat penting demi keamanan alur aplikasi.
3. **Data Persistence:** Tantangan terbesar adalah menyimpan List Object ke Shared Preferences yang membutuhkan proses encode/decode JSON.