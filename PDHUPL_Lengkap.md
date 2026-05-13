# DOKUMEN PDHUPL
# Perencanaan, Deskripsi, dan Hasil Uji Perangkat Lunak
## Aplikasi Sensational Glasses

| Item | Keterangan |
|------|-----------|
| **Versi** | 1.0 |
| **Penyusun** | Mohammad Dhimas Afrizal |
| **Program Studi** | S1 Rekayasa Perangkat Lunak |
| **Tanggal** | 12 Mei 2026 |

---

# BAB I — PENDAHULUAN

## 1.1 Tujuan Pembuatan Dokumen

Dokumen PDHUPL ini disusun untuk mendokumentasikan perencanaan, deskripsi, dan hasil pengujian fungsional terhadap aplikasi **Sensational Glasses**. Pengujian dilakukan menggunakan metode **Black Box Testing** untuk memverifikasi bahwa setiap fitur berjalan sesuai spesifikasi kebutuhan fungsional yang telah dirancang.

Rumusan masalah yang mendasari dokumen ini:
> *"Bagaimana hasil pengujian fungsional aplikasi mobile yang didokumentasikan menggunakan standar PDHUPL menunjukkan kesesuaian fitur dengan rancangan sistem?"*

## 1.2 Lingkup Pengujian

Pengujian mencakup **5 area fungsional utama**:

| No | Area Pengujian | Kode | Jumlah Skenario |
|----|---------------|------|-----------------|
| 1 | Autentikasi | AUTH | 20 |
| 2 | Monitoring IoT | MON | 14 |
| 3 | Kontrol Alarm | ALR | 8 |
| 4 | Sistem Notifikasi | NTF | 11 |
| 5 | Navigasi Rute GPS | NAV | 8 |
| | **Total** | | **61** |

## 1.3 Definisi, Akronim, dan Singkatan

| Istilah | Definisi |
|---------|---------|
| **PDHUPL** | Perencanaan, Deskripsi, dan Hasil Uji Perangkat Lunak |
| **Black Box Testing** | Pengujian fungsional tanpa melihat kode internal, fokus pada input/output |
| **IoT** | Internet of Things |
| **ThingSpeak** | Platform cloud IoT dari MathWorks untuk mengirim/menerima data sensor |
| **Firebase** | Platform Backend-as-a-Service dari Google |
| **Firestore** | Database NoSQL real-time dari Firebase |
| **GPS** | Global Positioning System |
| **API Key** | Kunci autentikasi untuk mengakses layanan API |
| **Polling** | Mekanisme pengambilan data secara berkala (interval 15 detik) |
| **Polyline** | Garis rute yang digambar di peta |

## 1.4 Dokumen Referensi

1. Hasil Audit Komprehensif Aplikasi Sensational Glasses (12 Mei 2026)
2. IEEE 829 — Standard for Software Test Documentation
3. Source Code Aplikasi Sensational Glasses v1.0.0+4

## 1.5 Deskripsi Umum Dokumen

- **Bab I** — Pendahuluan: tujuan, lingkup, dan acuan dokumen
- **Bab II** — Lingkungan Pengujian: perangkat keras, lunak, dan prosedur
- **Bab III** — Identifikasi dan Rencana Pengujian: daftar butir uji
- **Bab IV** — Deskripsi dan Hasil Uji: tabel detail hasil pengujian per skenario

---

# BAB II — LINGKUNGAN PENGUJIAN

## 2.1 Perangkat Lunak Pengujian

| Komponen | Spesifikasi |
|----------|------------|
| Sistem Operasi | Android 12+ |
| Framework | Flutter SDK ^3.9.2 |
| Backend | Firebase (Auth, Firestore, Storage) |
| IoT Platform | ThingSpeak (MathWorks) |
| Maps | Google Maps SDK for Android |
| IDE | Android Studio / VS Code |

## 2.2 Perangkat Keras Pengujian

| Komponen | Spesifikasi |
|----------|------------|
| Smartphone | Android (min. API 21 / Android 5.0) |
| RAM | Minimum 3 GB |
| Koneksi | Internet aktif (Wi-Fi / Data Seluler) |
| GPS | Aktif dengan izin lokasi |
| Perangkat IoT | Kacamata Sensational Glasses (terhubung ThingSpeak) |

## 2.3 Sumber Daya Manusia

| Peran | Tanggung Jawab |
|-------|---------------|
| Tester / Penguji | Menjalankan skenario uji, mencatat hasil |
| Developer | Menyiapkan lingkungan, memperbaiki bug |

## 2.4 Prosedur Umum Pengujian

1. Pastikan aplikasi terinstal dan koneksi internet aktif
2. Pastikan perangkat IoT kacamata aktif dan mengirim data ke ThingSpeak
3. Jalankan skenario uji sesuai tabel pada Bab IV
4. Catat hasil aktual dan bandingkan dengan hasil yang diharapkan
5. Tandai status **Pass** jika sesuai, **Fail** jika tidak sesuai
6. Ambil screenshot sebagai bukti pengujian

---

# BAB III — IDENTIFIKASI DAN RENCANA PENGUJIAN

## 3.1 Identifikasi Butir Uji

---

### 3.1.1 Area Uji: Autentikasi (AUTH) — 20 Skenario

| ID Uji | Nama Pengujian | Deskripsi | Metode |
|--------|---------------|-----------|--------|
| AUTH-01 | Login Email Valid | Login dengan email dan password yang benar dan terverifikasi | Black Box |
| AUTH-02 | Login Email Invalid | Login dengan email/password salah | Black Box |
| AUTH-03 | Login Semua Field Kosong | Login tanpa mengisi email dan password | Black Box |
| AUTH-04 | Login Google | Login menggunakan akun Google | Black Box |
| AUTH-05 | Login Facebook | Login menggunakan akun Facebook | Black Box |
| AUTH-06 | Registrasi Valid | Daftar akun baru dengan semua data valid | Black Box |
| AUTH-07 | Registrasi Data Kosong | Daftar akun tanpa mengisi semua field | Black Box |
| AUTH-08 | Registrasi Password Lemah | Daftar dengan password tidak memenuhi syarat | Black Box |
| AUTH-09 | Verifikasi Email | Cek status verifikasi setelah klik link di email | Black Box |
| AUTH-10 | Kirim Ulang Verifikasi | Mengirim ulang link verifikasi email | Black Box |
| AUTH-11 | Lupa Password Valid | Mengirim email reset password dengan email terdaftar | Black Box |
| AUTH-12 | Logout | Keluar dari akun yang sedang aktif | Black Box |
| AUTH-13 | Login Email Belum Diverifikasi | Login dengan akun yang belum verifikasi email | Black Box |
| AUTH-14 | Login Field Email Kosong | Login hanya mengisi password, email dikosongkan | Black Box |
| AUTH-15 | Login Field Password Kosong | Login hanya mengisi email, password dikosongkan | Black Box |
| AUTH-16 | Registrasi Email Duplikat | Daftar dengan email yang sudah terdaftar | Black Box |
| AUTH-17 | Registrasi Format Email Invalid | Daftar dengan format email tidak valid | Black Box |
| AUTH-18 | Reset Password Field Kosong | Mengirim reset password tanpa mengisi email | Black Box |
| AUTH-19 | Reset Password Email Tidak Terdaftar | Mengirim reset password dengan email yang belum terdaftar | Black Box |
| AUTH-20 | Pemulihan Sesi Otomatis (Cold Start) | Membuka aplikasi setelah sebelumnya login tanpa logout | Black Box |

---

### 3.1.2 Area Uji: Monitoring IoT (MON) — 14 Skenario

| ID Uji | Nama Pengujian | Deskripsi | Metode |
|--------|---------------|-----------|--------|
| MON-01 | Input Data Tunanetra Valid | Mengisi semua field data tunanetra dan ThingSpeak dengan benar | Black Box |
| MON-02 | Input ThingSpeak Invalid | Mengisi Channel ID/Read API Key yang salah | Black Box |
| MON-03 | Input Data Kosong | Menyimpan form tanpa mengisi field wajib | Black Box |
| MON-04 | Tampilan Status Aktif | Verifikasi status "Aktif" saat perangkat IoT online | Black Box |
| MON-05 | Tampilan Status Lowbat | Verifikasi status "Lowbat" saat baterai ≤ 20% | Black Box |
| MON-06 | Tampilan Status Offline | Verifikasi status "Offline" saat data > 45 detik | Black Box |
| MON-07 | ID Card Tunanetra | Melihat kartu identitas digital tunanetra | Black Box |
| MON-08 | Hapus Data Tunanetra | Menghapus data tunanetra dan memutuskan koneksi IoT | Black Box |
| MON-09 | Edit Data Tunanetra | Mengedit data tunanetra yang sudah tersimpan | Black Box |
| MON-10 | Upload Foto Tunanetra | Mengunggah foto profil tunanetra ke Firebase Storage | Black Box |
| MON-11 | Deteksi Perubahan Channel ID | Sistem reset data saat credentials ThingSpeak berubah | Black Box |
| MON-12 | Animasi Radar Saat GPS Loading | Tampilan animasi radar saat GPS belum ditemukan | Black Box |
| MON-13 | Auto-Recenter Peta Mini | Kamera peta mini otomatis kembali ke posisi perangkat setelah 5 detik | Black Box |
| MON-14 | Polling Data 15 Detik Real-time | Verifikasi data sensor diperbarui setiap 15 detik | Black Box |

---

### 3.1.3 Area Uji: Kontrol Alarm (ALR) — 8 Skenario

| ID Uji | Nama Pengujian | Deskripsi | Metode |
|--------|---------------|-----------|--------|
| ALR-01 | Aktivasi Alarm Normal | Menyalakan alarm saat perangkat aktif dan GPS ditemukan | Black Box |
| ALR-02 | Alarm Tanpa Data | Menekan alarm saat data tunanetra belum diinput | Black Box |
| ALR-03 | Alarm GPS Belum Ditemukan | Menekan alarm saat lokasi GPS belum terdeteksi | Black Box |
| ALR-04 | Alarm Perangkat Offline | Menekan alarm saat perangkat mati/offline | Black Box |
| ALR-05 | Countdown Alarm | Verifikasi countdown 15 detik setelah aktivasi | Black Box |
| ALR-06 | Matikan Alarm | Mematikan alarm setelah berstatus aktif | Black Box |
| ALR-07 | Alarm Write Key Kosong | Menekan alarm tanpa Write API Key di data tunanetra | Black Box |
| ALR-08 | Alarm dari Maps Screen | Mengaktifkan alarm dari halaman Maps | Black Box |

---

### 3.1.4 Area Uji: Sistem Notifikasi (NTF) — 11 Skenario

| ID Uji | Nama Pengujian | Deskripsi | Metode |
|--------|---------------|-----------|--------|
| NTF-01 | Notifikasi Baterai 50% | Pop-up notifikasi saat baterai ≤ 50% (info) | Black Box |
| NTF-02 | Notifikasi Baterai 20% | Pop-up notifikasi saat baterai ≤ 20% (danger) | Black Box |
| NTF-03 | Notifikasi Jarak 5 km | Pop-up notifikasi saat jarak ≥ 5 km (info) | Black Box |
| NTF-04 | Notifikasi Jarak 10 km | Pop-up notifikasi saat jarak ≥ 10 km (danger) | Black Box |
| NTF-05 | Riwayat Notifikasi | Melihat daftar riwayat notifikasi tersimpan | Black Box |
| NTF-06 | Hapus Notifikasi (Swipe) | Menghapus notifikasi dengan geser ke kiri | Black Box |
| NTF-07 | Notifikasi Baterai 30% | Pop-up notifikasi saat baterai ≤ 30% (warning) | Black Box |
| NTF-08 | Notifikasi Jarak 8 km | Pop-up notifikasi saat jarak ≥ 8 km (warning) | Black Box |
| NTF-09 | Notifikasi Perangkat Offline | Pop-up notifikasi saat perangkat mati/kehilangan sinyal | Black Box |
| NTF-10 | Mekanisme Anti-Spam | Verifikasi notifikasi tidak dikirim berulang untuk threshold yang sama | Black Box |
| NTF-11 | Klik Notifikasi Buka Maps | Tap notifikasi push mengarahkan ke halaman Maps | Black Box |

---

### 3.1.5 Area Uji: Navigasi Rute GPS (NAV) — 8 Skenario

| ID Uji | Nama Pengujian | Deskripsi | Metode |
|--------|---------------|-----------|--------|
| NAV-01 | Tampilan Peta Real-time | Peta menampilkan marker posisi perangkat IoT | Black Box |
| NAV-02 | Tampilkan Rute Kendaraan | Polyline rute mode kendaraan | Black Box |
| NAV-03 | Tampilkan Rute Jalan Kaki | Polyline rute mode jalan kaki | Black Box |
| NAV-04 | Tutup Rute | Menutup rute yang sedang ditampilkan | Black Box |
| NAV-05 | Ganti Mode Perjalanan | Berganti mode saat rute aktif | Black Box |
| NAV-06 | Peta Tanpa Data | Tampilan peta saat data tunanetra belum ada | Black Box |
| NAV-07 | Peta GPS Belum Ditemukan | Tampilan peta saat GPS belum terdeteksi | Black Box |
| NAV-08 | Alamat Reverse Geocoding | Konversi koordinat menjadi nama alamat | Black Box |

---

## 3.2 Ringkasan Rencana Pengujian

| No | Area Pengujian | Kode | Jumlah Skenario |
|----|---------------|------|-----------------|
| 1 | Autentikasi | AUTH | 20 |
| 2 | Monitoring IoT | MON | 14 |
| 3 | Kontrol Alarm | ALR | 8 |
| 4 | Sistem Notifikasi | NTF | 11 |
| 5 | Navigasi Rute GPS | NAV | 8 |
| | **Total** | | **61** |

---

# BAB IV — DESKRIPSI DAN HASIL UJI

## 4.1 Area Uji: Autentikasi (AUTH)

### AUTH-01 — Login Email Valid

| Komponen | Detail |
|

### AUTH-02 — Login Email Invalid

| Komponen | Detail |
|

### AUTH-03 — Login Field Kosong

| Komponen | Detail |
|

### AUTH-04 — Login Google

| Komponen | Detail |
|

### AUTH-05 — Login Facebook

| Komponen | Detail |
|

### AUTH-06 — Registrasi Valid

| Komponen | Detail |
|

### AUTH-07 — Registrasi Data Kosong

| Komponen | Detail |
|

### AUTH-08 — Registrasi Password Lemah

| Komponen | Detail |
|

### AUTH-09 — Verifikasi Email

| Komponen | Detail |
|

### AUTH-10 — Kirim Ulang Verifikasi

| Komponen | Detail |
|

### AUTH-11 — Lupa Password

| Komponen | Detail |
|

### AUTH-12 — Logout

| Komponen | Detail |
|

### AUTH-13 — Login Email Belum Diverifikasi

| Komponen | Detail |
|

### AUTH-14 — Login Field Email Kosong

| Komponen | Detail |
|

### AUTH-15 — Login Field Password Kosong

| Komponen | Detail |
|

### AUTH-16 — Registrasi Email Duplikat

| Komponen | Detail |
|

### AUTH-17 — Registrasi Format Email Invalid

| Komponen | Detail |
|

### AUTH-18 — Reset Password Field Kosong

| Komponen | Detail |
|

### AUTH-19 — Reset Password Email Tidak Terdaftar

| Komponen | Detail |
|

### AUTH-20 — Pemulihan Sesi Otomatis (Cold Start)

| Komponen | Detail |
|

---

## 4.2 Area Uji: Monitoring IoT (MON)

### MON-01 — Input Data Tunanetra Valid

| Komponen | Detail |
|

### MON-02 — Input ThingSpeak Invalid

| Komponen | Detail |
|

### MON-03 — Input Data Kosong

| Komponen | Detail |
|

### MON-04 — Tampilan Status Aktif

| Komponen | Detail |
|

### MON-05 — Tampilan Status Lowbat

| Komponen | Detail |
|

### MON-06 — Tampilan Status Offline

| Komponen | Detail |
|

### MON-07 — ID Card Tunanetra

| Komponen | Detail |
|

### MON-08 — Hapus Data Tunanetra

| Komponen | Detail |
|

### MON-09 — Edit Data Tunanetra

| Komponen | Detail |
|

### MON-10 — Upload Foto Tunanetra

| Komponen | Detail |
|

### MON-11 — Deteksi Perubahan Channel ID

| Komponen | Detail |
|

### MON-12 — Animasi Radar Saat GPS Loading

| Komponen | Detail |
|

### MON-13 — Auto-Recenter Peta Mini

| Komponen | Detail |
|

### MON-14 — Polling Data 15 Detik Real-time

| Komponen | Detail |
|

---

## 4.3 Area Uji: Kontrol Alarm (ALR)

### ALR-01 — Aktivasi Alarm Normal

| Komponen | Detail |
|

### ALR-02 — Alarm Tanpa Data

| Komponen | Detail |
|

### ALR-03 — Alarm GPS Belum Ditemukan

| Komponen | Detail |
|

### ALR-04 — Alarm Perangkat Offline

| Komponen | Detail |
|

### ALR-05 — Countdown Alarm

| Komponen | Detail |
|

### ALR-06 — Matikan Alarm

| Komponen | Detail |
|

### ALR-07 — Alarm Write Key Kosong

| Komponen | Detail |
|

### ALR-08 — Alarm dari Maps Screen

| Komponen | Detail |
|

---

## 4.4 Area Uji: Sistem Notifikasi (NTF)

### NTF-01 — Notifikasi Baterai 50%

| Komponen | Detail |
|

### NTF-02 — Notifikasi Baterai 20% (Kritis)

| Komponen | Detail |
|

### NTF-03 — Notifikasi Jarak 5 km

| Komponen | Detail |
|

### NTF-04 — Notifikasi Jarak 10 km (Danger)

| Komponen | Detail |
|

### NTF-05 — Riwayat Notifikasi

| Komponen | Detail |
|

### NTF-06 — Hapus Notifikasi (Swipe)

| Komponen | Detail |
|

### NTF-07 — Notifikasi Baterai 30% (Warning)

| Komponen | Detail |
|

### NTF-08 — Notifikasi Jarak 8 km (Warning)

| Komponen | Detail |
|

### NTF-09 — Notifikasi Perangkat Offline

| Komponen | Detail |
|

### NTF-10 — Mekanisme Anti-Spam

| Komponen | Detail |
|

### NTF-11 — Klik Notifikasi Buka Maps

| Komponen | Detail |
|

---

## 4.5 Area Uji: Navigasi Rute GPS (NAV)

### NAV-01 — Tampilan Peta Real-time

| Komponen | Detail |
|

### NAV-02 — Tampilkan Rute Kendaraan

| Komponen | Detail |
|

### NAV-03 — Tampilkan Rute Jalan Kaki

| Komponen | Detail |
|

### NAV-04 — Tutup Rute

| Komponen | Detail |
|

### NAV-05 — Ganti Mode Perjalanan

| Komponen | Detail |
|

### NAV-06 — Peta Tanpa Data

| Komponen | Detail |
|

### NAV-07 — Peta GPS Belum Ditemukan

| Komponen | Detail |
|

### NAV-08 — Alamat Reverse Geocoding

| Komponen | Detail |
|

---

# BAB V — KESIMPULAN PENGUJIAN

## 5.1 Rangkuman Hasil

| Area Pengujian | Jumlah Skenario | Pass | Fail | Persentase |
|---------------|----------------|------|------|------------|
| Autentikasi (AUTH) | 20 | 20 | 0 | 100% |
| Monitoring IoT (MON) | 14 | 14 | 0 | 100% |
| Kontrol Alarm (ALR) | 8 | 8 | 0 | 100% |
| Sistem Notifikasi (NTF) | 11 | 11 | 0 | 100% |
| Navigasi GPS (NAV) | 8 | 8 | 0 | 100% |
| **TOTAL** | **61** | **61** | **0** | **100%** |

## 5.2 Kesimpulan

Berdasarkan pengujian fungsional menggunakan metode **Black Box Testing** yang telah dilakukan terhadap **61 skenario uji** pada 5 area fungsional utama, seluruh fitur aplikasi Sensational Glasses berjalan **sesuai dengan spesifikasi kebutuhan fungsional** yang telah dirancang.

Hasil ini menunjukkan bahwa:
1. **Sistem autentikasi** (20 skenario) berfungsi dengan baik mencakup login multi-metode (Email, Google, Facebook), registrasi dengan validasi lengkap (format email, password strength, email duplikat), verifikasi email, reset password, dan pemulihan sesi otomatis saat cold start.
2. **Fitur monitoring IoT** (14 skenario) berhasil membaca dan menampilkan data sensor dari ThingSpeak secara real-time setiap 15 detik, termasuk validasi credentials, edit data dengan pre-fill, upload foto ke Firebase Storage, deteksi perubahan Channel ID, animasi radar, dan auto-recenter peta.
3. **Kontrol alarm** (8 skenario) memiliki mekanisme guard yang lengkap untuk mencegah pengiriman perintah pada kondisi tidak valid (tanpa data, GPS belum ditemukan, perangkat offline, Write Key kosong).
4. **Sistem notifikasi** (11 skenario) mengirim peringatan otomatis berdasarkan 7 threshold (baterai 50%/30%/20%, jarak 5km/8km/10km, perangkat offline) dengan mekanisme anti-spam 7 boolean flags yang efektif, serta navigasi otomatis ke Maps saat notifikasi diklik.
5. **Navigasi GPS** (8 skenario) menampilkan peta, rute polyline (kendaraan/jalan kaki), reverse geocoding, dan penanganan state saat data belum tersedia.
