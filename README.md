# MutasiKu

Aplikasi mobile untuk mengelola dan melacak **mutasi (perpindahan) aset internal** perusahaan: dari pengajuan oleh pegawai, pemeriksaan kelengkapan, verifikasi data aset, persetujuan pimpinan, sampai konfirmasi akhir dan pembaruan data aset.

Setiap mutasi punya nomor tiket unik, riwayat yang bisa ditelusuri, dan notifikasi di setiap tahap.

---

## Daftar Isi

1. [Alur Mutasi](#alur-mutasi)
2. [Role dan Hak Akses](#role-dan-hak-akses)
3. [Status Mutasi](#status-mutasi)
4. [Aturan Bisnis Penting](#aturan-bisnis-penting)
5. [Tumpukan Teknis](#tumpukan-teknis)
6. [Struktur Repository](#struktur-repository)
7. [Menjalankan Project](#menjalankan-project)
8. [Akun Demo](#akun-demo)
9. [Menjalankan Test](#menjalankan-test)
10. [Ringkasan API](#ringkasan-api)
11. [Dokumentasi](#dokumentasi)
12. [Batasan dan Rencana](#batasan-dan-rencana)

---

## Alur Mutasi

```text
Pemohon mengajukan mutasi
  • memilih aset terdaftar miliknya
  • memilih lokasi tujuan
  • menjawab "Aset ikut saya pindah?"
  • melampirkan SK SDM (wajib, PDF)
        ↓  status: Diajukan
Operator memeriksa kelengkapan
  • memeriksa kelengkapan berkas fisik & SK SDM
  • bila lengkap → diteruskan ke Bagian Aset (status: Menunggu Verifikasi Bagian Aset)
  • Operator tidak berwenang mengembalikan atau menolak pengajuan
Bagian Aset memverifikasi keabsahan data aset
  • bila PIC baru masih kosong, Bagian Aset yang memilihnya
  ├── tidak valid → Dikembalikan ke Pemohon (alasan wajib, status final)
  └── valid
        ↓  status: Menunggu Approval Pemimpin Divisi
Pemimpin Divisi (approval final, selalu dilibatkan)
  ├── tolak (alasan wajib) → Ditolak (final)
  └── setuju
        ↓  status: Menunggu Konfirmasi Pemohon
Pemohon memeriksa kondisi fisik
  ├── Sesuai → data aset (lokasi + PIC) diperbarui → Selesai
  └── Tidak Sesuai (alasan wajib) → kembali ke Bagian Aset
```

Pengajuan yang **Dikembalikan ke Pemohon** berstatus final (pengajuan berakhir). Tiket lama tidak dapat diedit atau diajukan ulang; Pemohon dapat membuat pengajuan mutasi baru untuk aset tersebut.

---

## Role dan Hak Akses

| Role | Tugas |
|---|---|
| **Admin** | Mengelola user, role, lokasi/unit, kategori aset, dan data aset |
| **Pemohon** | Mengajukan mutasi aset miliknya, membuat tiket baru jika pengajuan sebelumnya berakhir, mengonfirmasi hasil |
| **Operator** | Memeriksa **kelengkapan** berkas fisik & SK SDM, meneruskan ke Bagian Aset (tidak berwenang mengembalikan/menolak) |
| **Bagian Aset** | Memverifikasi **keabsahan** data aset, menentukan PIC baru bila kosong, meneruskan ke pimpinan atau mengembalikan ke Pemohon |
| **Pemimpin Divisi** | Approval final untuk semua pengajuan yang lolos verifikasi |

Satu user memiliki satu role aktif. Pembatasan akses dicek di server, bukan hanya di tampilan aplikasi.

---

## Status Mutasi

| Status | Arti |
|---|---|
| `Diajukan` | Menunggu pemeriksaan kelengkapan Operator |
| `Menunggu Verifikasi Bagian Aset` | Sudah lengkap, menunggu verifikasi Bagian Aset |
| `Dikembalikan ke Pemohon` | Dikembalikan oleh Bagian Aset (status final/berakhir); aset terbuka untuk pengajuan baru |
| `Menunggu Approval Pemimpin Divisi` | Lolos verifikasi, menunggu keputusan pimpinan |
| `Ditolak` | Ditolak Pemimpin Divisi (final) |
| `Menunggu Konfirmasi Pemohon` | Disetujui, menunggu konfirmasi Pemohon |
| `Selesai` | Pemohon memilih Sesuai dan data aset sudah diperbarui |

---

## Aturan Bisnis Penting

- **Aset harus terdaftar.** Input aset bebas (ketik manual) tidak didukung.
- **Satu aset hanya boleh punya satu mutasi aktif.** Aset terkunci selama memiliki pengajuan aktif. Setelah pengajuan sebelumnya berstatus final (`Selesai`, `Ditolak`, atau `Dikembalikan ke Pemohon`), aset otomatis terbuka dan dapat diajukan kembali melalui tiket baru.
- **SK SDM wajib** (file PDF) pada setiap pengajuan.
- **Pemohon tidak menentukan PIC baru**, kecuali ia membawa asetnya sendiri:
  - Jawaban *Ya* → PIC baru otomatis Pemohon.
  - Jawaban *Tidak* → PIC baru dikosongkan dan dipilih Bagian Aset saat verifikasi. Nilai PIC dari client diabaikan server.
- **Pemimpin Divisi selalu terlibat**, tanpa syarat nilai aset.
- **Data aset (lokasi dan PIC) hanya berubah saat Pemohon memilih Sesuai.** Sebelum itu data lama tetap berlaku, termasuk saat pimpinan menyetujui.
- Semua perubahan lokasi dan PIC menghasilkan **riwayat**.
- Transisi status dibungkus transaksi database. Jika salah satu langkah gagal, semua perubahan dibatalkan.
- Transisi status yang tidak sah ditolak server (`409`), role yang salah ditolak (`403`).

---

## Tumpukan Teknis

**Aplikasi mobile**
- Flutter (Dart SDK `^3.13`)
- State management: Riverpod
- Routing: go_router
- HTTP client, `flutter_secure_storage`, `shared_preferences`, `file_picker`, `google_fonts`
- Arsitektur: *feature-first* + Clean Architecture ringan (`presentation` → `domain` → `data`)

**Backend API**
- Laravel `^13` dengan PHP `^8.3`
- Autentikasi token: Laravel Sanctum
- Database: SQLite (default `.env.example`), bisa diganti MySQL atau PostgreSQL
- Notifikasi: Laravel Notification (kanal database)

---

## Struktur Repository

```text
.
├── lib/                      # Kode Flutter
│   ├── app/                  # Tema, router, route guard
│   ├── core/                 # Widget bersama, network, storage, error handling
│   └── features/             # auth, mutation, pemohon, operator,
│                             # bagian_aset, kadiv, asset, admin, notification, ...
├── test/                     # Test Flutter
├── mutasiku-backend/         # Backend Laravel (API)
│   ├── app/                  # Model, controller API v1, form request
│   ├── database/             # Migration dan seeder
│   ├── routes/api.php        # Daftar endpoint
│   └── tests/                # Test backend
├── dosc/                     # Dokumen produk dan desain (PRD, role flow, dll.)
├── android/ ios/ web/ ...    # Platform Flutter
└── README.md
```

> Folder bernama `dosc` (bukan `docs`). Nama ini sengaja dipertahankan karena dirujuk dokumen lain.

---

## Menjalankan Project

### Prasyarat

- Flutter SDK (Dart `^3.13`) dan emulator atau perangkat
- PHP `^8.3` dan Composer
- Git

### 1. Backend (Laravel)

```bash
cd mutasiku-backend

composer install

# salin konfigurasi
cp .env.example .env          # Windows: copy .env.example .env
php artisan key:generate

# migrasi dan data awal (role, kategori, lokasi, user demo, aset)
php artisan migrate --seed

# jalankan server
php artisan serve
```

Server berjalan di `http://127.0.0.1:8000`. Jika Laravel menanyakan apakah file database SQLite boleh dibuat, jawab **yes**.

Untuk mengulang dari awal (menghapus semua data):

```bash
php artisan migrate:fresh --seed
```

### 2. Aplikasi Flutter

```bash
# dari root repository
flutter pub get
flutter run
```

**Alamat server (`API_BASE_URL`):**

| Perangkat | Alamat | Cara |
|---|---|---|
| Emulator Android | `http://10.0.2.2:8000` | Otomatis, tidak perlu diatur |
| Web / Desktop | `http://127.0.0.1:8000` | Otomatis |
| HP fisik | `http://<IP-LAN-komputer>:8000` | Lihat di bawah |

Untuk HP fisik, jalankan backend agar bisa diakses dari jaringan, lalu beri alamatnya ke Flutter:

```bash
# backend
php artisan serve --host=0.0.0.0 --port=8000

# flutter
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

Ganti `192.168.1.10` dengan IP komputer kamu. HP dan komputer harus berada di jaringan yang sama.

---

## Akun Demo

Semua akun dibuat oleh seeder. Password awal: **`password`**. Sistem akan meminta ganti password saat login pertama.

| Role | Email |
|---|---|
| Admin | `admin@mutasiku.test` |
| Pemohon | `pemohon@mutasiku.test` |
| Operator | `operator@mutasiku.test` |
| Bagian Aset | `aset@mutasiku.test` |
| Pemimpin Divisi | `pemimpin@mutasiku.test` |

Pemohon tambahan untuk uji banyak pengguna: `budi.santoso@mutasiku.test`, `ahmad.fauzi@mutasiku.test`, `siti.nurhaliza@mutasiku.test`, `dewi.lestari@mutasiku.test`, `rizky.pratama@mutasiku.test`.

> Akun dan password ini **hanya untuk pengembangan**. Jangan dipakai di server sungguhan.

### Skenario uji cepat (satu siklus penuh)

1. Login **Pemohon** → ajukan mutasi (pilih aset, lokasi tujuan, jawab "Aset ikut saya pindah?", lampirkan PDF).
2. Login **Operator** → buka pengajuan → teruskan.
3. Login **Bagian Aset** → verifikasi, pilih PIC baru bila diminta → teruskan.
4. Login **Pemimpin Divisi** → setujui.
5. Login **Pemohon** → konfirmasi **Sesuai** → status `Selesai`, lokasi dan PIC aset berubah.

Coba juga skenario lain: pengajuan dikembalikan oleh Bagian Aset (tiket berakhir lalu buat pengajuan mutasi baru), ditolak pimpinan, dan **Tidak Sesuai** (kembali ke antrean Bagian Aset).

---

## Menjalankan Test

```bash
# Backend
cd mutasiku-backend
php artisan test

# Flutter (dari root repository)
flutter test
```

Test backend mencakup autentikasi, pembatasan akses per role, seluruh transisi status, aturan PIC, validasi SK SDM, riwayat, notifikasi, dan CRUD Admin. Test Flutter mencakup route guard, RBAC, form pengajuan, dan alur tiap role.

---

## Ringkasan API

Prefix: `/api/v1`. Semua endpoint, kecuali login, memakai header `Authorization: Bearer <token>`.

| Kelompok | Endpoint & Perilaku |
|---|---|
| Auth | `POST /auth/login`, `GET /auth/me`, `POST /auth/logout`, `POST /auth/change-password` |
| Master data | `GET /locations`, `GET /asset-categories`, `GET /assets`, `GET /assets/{id}`, `GET /assets/{id}/history` |
| Mutasi | `GET /mutations`, `POST /mutations` (pengajuan baru), `GET /mutations/{id}`, `GET /mutations/{id}/document` |
| Operator | `POST /mutations/{id}/forward` (teruskan ke Bagian Aset jika data & SK lengkap), `POST /mutations/{id}/return-by-operator` (HTTP 403: Operator tidak berwenang mengembalikan tiket) |
| Bagian Aset | `POST /mutations/{id}/verify-asset` (teruskan ke Pemimpin Divisi), `POST /mutations/{id}/return-by-asset` (kembalikan ke Pemohon, status final) |
| Pemimpin Divisi | `POST /mutations/{id}/approve` (setujui mutasi), `POST /mutations/{id}/reject` (tolak mutasi, status final) |
| Pemohon | `POST /mutations/{id}/confirm` (konfirmasi fisik Sesuai/Tidak Sesuai), `POST /mutations/{id}/report-discrepancy` |
| Notifikasi | `GET /notifications`, `POST /notifications/{id}/read`, `POST /notifications/read-all` |
| Admin | `/admin/users`, `/admin/roles`, `/admin/locations`, `/admin/asset-categories`, `/admin/assets` (CRUD) |

Daftar lengkap ada di `mutasiku-backend/routes/api.php`.

---

## Dokumentasi

Dokumen produk dan desain ada di folder `dosc/`:

| Dokumen | Isi |
|---|---|
| `PRD V1.1.md` | Kebutuhan produk, role, status, aturan bisnis (acuan utama) |
| `ROLE-FLOW.md` | Alur kerja per role |
| `SCREEN-SPEC.md` | Spesifikasi tiap layar |
| `DESIGN.md`, `WIREFRAME.md` | Design system dan wireframe |
| `TECHNICAL-DESIGN.md`, `PROJECT-SETUP.md` | Arsitektur dan setup teknis |

Jika ada perbedaan antar dokumen, **PRD V1.1** yang dipakai sebagai acuan.

---

## Batasan dan Rencana

Belum termasuk dalam versi ini:

- **Mode offline dan sinkronisasi** (database lokal) belum diimplementasikan.
- **Auto-close** konfirmasi Pemohon belum ada. Sistem hanya menyediakan data untuk pengingat.
- **Alur disposal aset**, mutasi massal, dan integrasi ERP di luar cakupan MVP.
- Perilaku setelah Pemohon memilih **Tidak Sesuai** adalah keputusan sementara (kembali ke Bagian Aset) dan masih perlu dikonfirmasi.
- Beberapa pertanyaan terbuka (SLA tiap tahap, kalender hari kerja, metode autentikasi final) tercatat di bagian *Open Questions* pada PRD.
