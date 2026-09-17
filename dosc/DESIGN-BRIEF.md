# DESIGN BRIEF — MUTASIKU

**Produk:** MutasiKu  
**Jenis:** Mobile Application — Flutter  
**Fungsi:** Pengelolaan dan pelacakan mutasi aset  
**Versi:** MVP 1.0  
**Tanggal:** 16 September 2026

---

# 1. DESIGN PRINCIPLES

## Principle 01 — "Status harus terlihat tanpa membaca panjang"

MutasiKu adalah aplikasi workflow. Pengguna terutama perlu mengetahui:

- pengajuan sedang berada di tahap apa;
- siapa yang harus bertindak;
- apa tindakan berikutnya;
- apakah ada masalah;
- apakah proses sudah selesai.

Karena itu, **status menjadi elemen visual utama**, bukan informasi sekunder.

### Aturan UI

Setiap halaman yang berkaitan dengan pengajuan wajib menampilkan:

```text
No. Tiket
Status
Tahap proses
Next action
```

Contoh:

```text
ELEKTRONIK-2026-00124

● Menunggu Approval Kabag

Pengajuan sudah diverifikasi Operator.

Berikutnya
Kabag Aset melakukan approval.
```

Bukan:

> "Pengajuan Anda sedang diproses."

Status harus spesifik dan mengikuti status yang sudah ditentukan PRD:

- Diajukan
- Menunggu Approval Kabag
- Dikembalikan ke Pemohon
- Menunggu Approval Kadiv
- Disetujui — Menunggu Update Aset
- Menunggu Konfirmasi Pemohon
- Selesai
- Selesai (Auto)
- Ditolak
- Menunggu Sinkronisasi

---

## Principle 02 — "Satu layar, satu keputusan utama"

Setiap screen harus memiliki **satu primary action**.

Contoh:

Pemohon:

```text
Detail Mutasi
        ↓
[ Konfirmasi Mutasi ]
```

Operator:

```text
Detail Pengajuan
        ↓
[ Verifikasi Pengajuan ]
```

Kabag:

```text
Detail Pengajuan
        ↓
[ Setujui ]
[ Tolak ]
```

Staff Aset:

```text
Detail Mutasi
        ↓
[ Update Data Aset ]
```

Secondary action tidak boleh memiliki visual weight yang sama dengan primary action.

Tujuannya mengurangi kesalahan ketika pengguna memproses pengajuan aset.

---

## Principle 03 — "Data operasional > dekorasi"

MutasiKu bukan aplikasi lifestyle atau social media.

Visual harus mengutamakan:

1. No. tiket
2. aset
3. lokasi
4. PIC
5. status
6. timeline
7. approval
8. tindakan

Hindari:

- ilustrasi besar yang tidak membantu tugas;
- animasi berlebihan;
- gradient dekoratif;
- card bertumpuk tanpa hierarki;
- ikon sebagai pengganti label penting.

**Desain harus terasa seperti sistem operasional internal yang modern, bukan dashboard startup yang dekoratif.**

---

# 2. VISUAL DIRECTION

## Mood

MutasiKu menggunakan karakter:

**Professional + Reliable + Clear + Operational**

Visual harus memberikan kesan:

> "Saya bisa mempercayai data ini dan tahu apa yang harus saya lakukan."

Bukan:

> "Aplikasi ini terlihat keren."

---

## Referensi visual

Arah visual mengambil karakter dari:

- enterprise workflow application;
- asset management system;
- modern banking internal application;
- ticketing/helpdesk;
- approval workflow.

Namun MutasiKu **tidak meniru identitas visual bank tertentu**.

---

## Warna utama

### Primary — Deep Navy

```text
#0F3D56
```

Digunakan untuk:

- primary button;
- app bar;
- heading tertentu;
- active navigation;
- elemen penting.

Alasan:

Deep navy memberikan kesan stabil, profesional, dan cocok untuk aplikasi pengelolaan aset tanpa menggunakan warna korporat bank tertentu.

---

### Secondary — Teal

```text
#0F766E
```

Digunakan untuk:

- informasi positif;
- secondary emphasis;
- active state tertentu;
- status operasional.

Teal dipilih sebagai aksen agar aplikasi tidak terasa terlalu "gelap" seperti sistem enterprise lama.

---

### Background

```text
#F6F8FA
```

Background utama bukan pure white agar card dan section lebih mudah dibedakan.

---

### Surface

```text
#FFFFFF
```

Untuk:

- card;
- modal;
- form;
- bottom sheet;
- detail panel.

---

## Semantic colors

### Success

```text
#15803D
```

Untuk:

- Selesai;
- approved;
- successful sync.

### Warning

```text
#B45309
```

Untuk:

- Menunggu;
- perhatian;
- SLA mendekati batas;
- offline/sync pending.

### Error

```text
#B42318
```

Untuk:

- Ditolak;
- validation error;
- failed sync;
- destructive action.

### Info

```text
#175CD3
```

Untuk:

- informasi;
- system message;
- help.

---

## Warna teks

```text
Primary text:    #172B4D
Secondary text:  #52606D
Disabled text:   #98A2B3
Border:          #D0D5DD
```

---

## Yang harus dihindari

Jangan menggunakan:

- neon;
- gradient sebagai elemen utama;
- glassmorphism;
- terlalu banyak warna;
- status berdasarkan warna saja;
- icon-only button untuk tindakan penting;
- animasi loading yang lama;
- card dengan shadow sangat tebal.

---

# 3. DESIGN TOKENS

## 3.1 Typography

### Font: Inter

**Keputusan: Inter.**

Alasannya:

- sangat jelas untuk angka dan kode tiket;
- cocok untuk aplikasi enterprise;
- angka mudah dibedakan;
- tersedia luas;
- nyaman untuk form dan tabel;
- cocok untuk bahasa Indonesia;
- memiliki hierarchy yang jelas dari caption sampai heading.

No. tiket seperti:

```text
ELEKTRONIK-2026-00124
```

harus tetap mudah dibaca dalam ukuran kecil.

---

## Typography scale

| Token | Size | Weight | Penggunaan |
|---|---:|---:|---|
| Display | 32px | 700 | angka/statistik penting |
| H1 | 24px | 700 | judul halaman |
| H2 | 20px | 700 | section heading |
| H3 | 18px | 600 | card heading |
| Body Large | 16px | 400/500 | informasi utama |
| Body | 14px | 400 | body text |
| Body Medium | 14px | 500 | label/important text |
| Caption | 12px | 400 | metadata |
| Button | 14px | 600 | CTA |
| Ticket | 14px | 600 | No. tiket |

Line height:

```text
Heading: 120%
Body:    150%
Caption: 140%
```

---

# 3.2 Spacing

Menggunakan base spacing **4px**.

```text
4   — xs
8   — sm
12  — md-sm
16  — md
20  — lg-sm
24  — lg
32  — xl
40  — 2xl
48  — 3xl
64  — 4xl
```

Default screen padding:

```text
16px mobile
24px tablet
32px desktop
```

Card internal padding:

```text
16px
```

Gap antar section:

```text
24px
```

---

# 3.3 Radius

```text
Radius XS:  4px
Radius SM:  8px
Radius MD:  12px
Radius LG:  16px
Radius XL:  24px
Pill:       999px
```

Default card:

```text
12px
```

Button:

```text
8px
```

Status badge:

```text
999px
```

Alasannya: MutasiKu harus terasa modern tetapi tetap enterprise. Radius 12px cukup modern tanpa menjadi terlalu playful.

---

# 3.4 Shadow

Gunakan shadow minimal.

### Elevation 1

Untuk card:

```text
0 1px 3px rgba(16,24,40,0.08)
```

### Elevation 2

Untuk dialog/bottom sheet:

```text
0 8px 24px rgba(16,24,40,0.12)
```

Tidak menggunakan shadow berat pada dashboard.

---

# 4. SCREEN INVENTORY

## A. Shared

| Screen | Tujuan |
|---|---|
| Splash | Memuat aplikasi dan session |
| Login | Autentikasi user |
| Notification | Melihat perubahan status |
| Profile | Melihat informasi akun |
| Error/Offline | Menangani kondisi sistem |

---

## B. Pemohon

| Screen | Tujuan |
|---|---|
| Dashboard Pemohon | Melihat ringkasan pengajuan |
| Daftar Mutasi Saya | Melihat semua pengajuan |
| Ajukan Mutasi | Memulai pengajuan |
| Pilih Aset | Memilih aset yang dimiliki |
| Form Mutasi | Mengisi data mutasi |
| Submit Success | Menampilkan tiket setelah submit |
| Detail Mutasi | Melihat detail + timeline |
| Edit Pengajuan | Memperbaiki pengajuan yang dikembalikan |
| Konfirmasi Mutasi | Mengonfirmasi hasil mutasi |
| Notification | Melihat perubahan status |

---

## C. Operator

| Screen | Tujuan |
|---|---|
| Dashboard Operator | Melihat pekerjaan yang masuk |
| Pengajuan Masuk | Daftar status Diajukan |
| Detail Pengajuan | Memeriksa informasi |
| Verifikasi | Approve/return |
| Riwayat Verifikasi | Melihat keputusan sebelumnya |

---

## D. Kabag Aset

| Screen | Tujuan |
|---|---|
| Dashboard Kabag | Ringkasan approval |
| Menunggu Approval | Daftar pengajuan |
| Detail Pengajuan | Review data |
| Approval | Setujui/tolak |
| Riwayat Approval | Riwayat keputusan |

---

## E. Kepala Divisi

| Screen | Tujuan |
|---|---|
| Dashboard Kadiv | Ringkasan approval |
| Menunggu Approval | Pengajuan yang membutuhkan Kadiv |
| Detail Pengajuan | Review pengajuan |
| Approval | Setujui/tolak |
| Riwayat Approval | Riwayat keputusan |

---

## F. Staff Aset

| Screen | Tujuan |
|---|---|
| Dashboard Staff Aset | Melihat pekerjaan |
| Menunggu Update | Pengajuan yang siap diproses |
| Detail Mutasi | Review data |
| Update Data Aset | Mengubah lokasi/PIC |
| Riwayat Aset | Melihat histori aset |

---

## G. Admin

| Screen | Tujuan |
|---|---|
| Dashboard Admin | Ringkasan master data |
| User Management | CRUD user |
| Role Management | Mengelola role |
| Location/Unit | CRUD lokasi/unit |
| Asset Category | CRUD kategori |
| Approval Criteria | Mengatur kriteria Kadiv |

---

# 5. USER FLOW

# Journey 01 — Pemohon mengajukan mutasi

```text
Login
 ↓
Dashboard
 ↓
Ajukan Mutasi
 ↓
Pilih Aset
 ↓
Form Mutasi
 ↓
Review
 ↓
Submit
 ↓
Validasi
 ↓
Generate No. Tiket
 ↓
Status: Diajukan
 ↓
Operator
```

Jika offline:

```text
Form Mutasi
 ↓
Submit
 ↓
Tidak ada internet
 ↓
Simpan lokal
 ↓
Menunggu Sinkronisasi
 ↓
Internet tersedia
 ↓
Sync
 ↓
Generate No. Tiket
 ↓
Diajukan
```

PRD menetapkan nomor tiket baru dibuat setelah sinkronisasi server, bukan ketika offline.

---

# Journey 02 — Operator melakukan verifikasi

```text
Login
 ↓
Dashboard
 ↓
Pengajuan Masuk
 ↓
Detail Pengajuan
 ↓
Verifikasi
 ↓
Data lengkap?
 ├── Tidak
 │    ↓
 │  Isi alasan
 │    ↓
 │  Kembalikan
 │    ↓
 │  Pemohon
 │
 └── Ya
      ↓
Menunggu Approval Kabag
```

Operator tidak mengubah lokasi/PIC aset.

---

# Journey 03 — Kabag melakukan approval

```text
Login
 ↓
Dashboard
 ↓
Menunggu Approval
 ↓
Detail
 ↓
Review
 ↓
Approve / Tolak
```

Jika approve:

```text
Memenuhi kriteria Kadiv?
 ├── Ya → Menunggu Approval Kadiv
 └── Tidak → Menunggu Update Aset
```

Kriteria tersebut berasal dari konfigurasi Admin dan masih perlu keputusan bisnis konkret. 
---

# Journey 04 — Kepala Divisi

```text
Login
 ↓
Menunggu Approval
 ↓
Detail
 ↓
Review
 ↓
Approve / Tolak
 ↓
Jika approve
 ↓
Menunggu Update Aset
```

Screen Kadiv hanya muncul untuk pengajuan yang memang memenuhi kriteria.

---

# Journey 05 — Staff Aset

```text
Login
 ↓
Menunggu Update
 ↓
Detail Mutasi
 ↓
Review lokasi + PIC
 ↓
Update Data Aset
 ↓
Save
 ↓
Riwayat Mutasi dibuat
 ↓
Menunggu Konfirmasi Pemohon
 ↓
Notification
```

Data aset baru berubah setelah seluruh approval yang diperlukan selesai.

---

# Journey 06 — Pemohon melakukan konfirmasi

```text
Notification
 ↓
Detail Mutasi
 ↓
Menunggu Konfirmasi
 ↓
Konfirmasi
 ├── Sesuai
 │    ↓
 │  Selesai
 │
 └── Tidak Sesuai
      ↓
      [FLOW BELUM DITENTUKAN]
```

Flow "Tidak Sesuai" tidak boleh didesain seolah-olah sudah final karena PRD masih menandainya sebagai Open Question.

---

# 6. LAYOUT PER SCREEN

# 6.1 Login

### Hierarchy

```text
Logo MutasiKu

Selamat datang
Masuk untuk mengelola mutasi aset

Username
[________________]

Password
[________________]

[ Masuk ]

Lupa password?
```

Primary action:

```text
Masuk
```

Jangan menampilkan role selector.

Role ditentukan oleh sistem setelah autentikasi karena MVP menetapkan satu role aktif per user.

---

# 6.2 Dashboard Pemohon

```text
Header
Halo, Rina
        [Notification]

Ringkasan
┌──────────┐ ┌──────────┐
│ Diproses │ │ Selesai  │
│    2     │ │    8     │
└──────────┘ └──────────┘

Pengajuan Terbaru

[ ELEKTRONIK-2026-00124 ]
Laptop Dell Latitude
Menunggu Approval Kabag
→

[ Ajukan Mutasi ]
```

Primary action:

**Ajukan Mutasi**

---

# 6.3 Daftar Mutasi

Top:

```text
Pengajuan Saya

[ Semua ] [ Diproses ] [ Selesai ]

Search No. Tiket / aset
```

List item:

```text
ELEKTRONIK-2026-00124
Laptop Dell Latitude

Kantor Pusat → Cabang Surabaya

Menunggu Approval Kabag
16 Sep 2026
```

Tap → Detail Mutasi.

---

# 6.4 Form Mutasi

Urutan:

```text
Ajukan Mutasi

1. Aset
   Laptop Dell Latitude
   Asset Code: AST-00124

2. Lokasi Tujuan
   [ Pilih lokasi ]

3. Penanggung Jawab Baru
   [ Pilih PIC ]

4. Alasan Mutasi
   [........................]

5. Dokumen Pendukung
   [ Upload ]
   
   (status mandatory mengikuti keputusan
   Open Question)

[ Review Pengajuan ]
```

Primary action:

**Review Pengajuan**

Bukan langsung "Submit", agar user memiliki kesempatan memeriksa data sebelum membuat pengajuan.

---

# 6.5 Review Pengajuan

Gunakan summary card.

```text
Review Pengajuan

ASET
Laptop Dell Latitude
AST-00124

MUTASI
Kantor Pusat
↓
Cabang Surabaya

PIC
Rina
↓
Rina

ALASAN
Perpindahan unit kerja

[ Kembali Edit ]

[ Ajukan Mutasi ]
```

Primary action:

**Ajukan Mutasi**

---

# 6.6 Detail Mutasi

Ini adalah **screen paling penting dalam produk**.

Struktur:

```text
← Detail Mutasi

ELEKTRONIK-2026-00124
Menunggu Approval Kabag

Timeline
● Diajukan
│ 16 Sep 09:20
│
● Verifikasi
│ Operator — Valid
│
● Menunggu Approval Kabag
│ Saat ini
│
○ Update Aset
○ Konfirmasi Pemohon

Detail Aset
Laptop Dell Latitude
AST-00124

Lokasi
Kantor Pusat → Cabang Surabaya

PIC
Rina → Rina

Alasan
Perpindahan unit kerja
```

Jika user memiliki tindakan:

```text
[ ACTION PRIMARY ]
```

ditempatkan sebagai sticky bottom action.

---

# 6.7 Operator — Detail Verifikasi

Header:

```text
ELEKTRONIK-2026-00124
Diajukan
```

Section:

```text
Informasi Pemohon
Informasi Aset
Lokasi Asal
Lokasi Tujuan
PIC Baru
Alasan
Dokumen
```

Bottom:

```text
[ Kembalikan ]
[ Verifikasi Valid ]
```

Jika memilih Kembalikan:

```text
Alasan Pengembalian

[........................]

[ Batalkan ]
[ Kembalikan Pengajuan ]
```

Alasan wajib karena PRD menetapkan pengajuan tidak valid harus memiliki catatan.

---

# 6.8 Approval Kabag/Kadiv

Layout sama untuk konsistensi.

```text
Detail Pengajuan

Status

Informasi Aset
Informasi Mutasi
Pemohon
Timeline
Dokumen

Approval sebelumnya

----------------

[ Tolak ]
[ Setujui ]
```

Tombol **Tolak** menggunakan destructive styling dan membutuhkan alasan.

Tombol **Setujui** adalah primary action.

---

# 6.9 Staff Aset — Update Aset

Gunakan before/after comparison.

```text
Update Data Aset

LOKASI

Sebelum
Kantor Pusat

Sesudah
Cabang Surabaya

PIC

Sebelum
Rina

Sesudah
Rina

[ Simpan Perubahan ]
```

Sebelum save, tampilkan confirmation:

```text
Data aset akan diperbarui.

Lokasi:
Kantor Pusat → Cabang Surabaya

PIC:
Rina → Rina

[ Batal ]
[ Konfirmasi Update ]
```

---

# 6.10 Riwayat Aset

Gunakan timeline.

```text
Riwayat Mutasi

AST-00124
Laptop Dell Latitude

2026
│
├── 16 Sep
│   Kantor Pusat
│   → Cabang Surabaya
│   PIC: Rina
│
2025
│
├── 03 Feb
│   Cabang Palu
│   → Kantor Pusat
│   PIC: Rina
```

Fokusnya adalah **perjalanan aset**, bukan sekadar daftar pengajuan.

---

# 6.11 Admin

Admin membutuhkan UI yang lebih information-dense.

Dashboard:

```text
Master Data

Users       128
Locations    14
Categories    6

[ Kelola User ]
[ Kelola Role ]
[ Kelola Lokasi ]
[ Kelola Kategori ]
[ Approval Criteria ]
```

Admin tidak mendapatkan tombol approval mutasi karena Admin dan Operator merupakan role berbeda dan tugas Admin pada MVP adalah pengelolaan master data.

---

# 7. COMPONENT LIBRARY

## 7.1 AppBar

### Variant

- Standard
- Detail
- Search
- Transparent

### State

- Default
- Scrolling
- Loading

---

## 7.2 Primary Button

```text
[ Simpan ]
[ Ajukan Mutasi ]
[ Setujui ]
```

Variants:

- Primary
- Secondary
- Destructive
- Ghost

States:

- Default
- Pressed
- Disabled
- Loading
- Focused

Minimum touch target:

**44 × 44px**

---

## 7.3 Status Badge

Variants:

```text
Diajukan
Menunggu
Dikembalikan
Ditolak
Disetujui
Selesai
Offline
```

Jangan menggunakan warna sebagai satu-satunya pembeda.

Contoh:

```text
● Menunggu Approval Kabag
```

bukan hanya badge kuning tanpa teks.

---

## 7.4 Mutation Card

Isi:

```text
No. Tiket
Nama Aset
Lokasi Asal → Tujuan
Status
Tanggal
```

Variants:

- Compact
- Standard
- Expanded

---

## 7.5 Timeline

Variants:

- Active
- Completed
- Pending
- Rejected
- Returned

Komponen ini menjadi komponen reusable lintas semua role.

---

## 7.6 Asset Card

```text
Laptop Dell Latitude
AST-00124

Lokasi
Kantor Pusat

PIC
Rina
```

---

## 7.7 Form Field

Variants:

- Text
- Password
- Dropdown
- Search
- Textarea
- Date
- File upload

States:

- Default
- Focus
- Filled
- Error
- Disabled
- Read-only

---

## 7.8 Confirmation Dialog

Dipakai sebelum:

- reject;
- approve;
- update asset;
- destructive action.

Format:

```text
Apakah Anda yakin?

Perubahan ini akan memperbarui
data lokasi dan PIC aset.

[ Batal ]
[ Konfirmasi ]
```

---

## 7.9 Empty State

Bukan sekadar:

> "Tidak ada data."

Harus menjelaskan kondisi.

Contoh:

```text
Belum ada pengajuan

Pengajuan mutasi yang Anda buat
akan muncul di sini.

[ Ajukan Mutasi ]
```

---

## 7.10 Offline Banner

```text
⚠ Tidak ada koneksi

Pengajuan akan disimpan di perangkat
dan disinkronkan saat online.
```

Untuk pengajuan offline gunakan status:

```text
Menunggu Sinkronisasi
```

sesuai PRD.

---

# 8. STATE DESIGN

Semua screen yang mengambil data dari server harus memiliki state eksplisit.

## Dashboard

### Loading

Skeleton:

```text
Header skeleton
Card skeleton
List skeleton
```

### Empty

```text
Belum ada pengajuan.
```

### Error

```text
Data belum dapat dimuat.

[ Coba Lagi ]
```

### Offline

```text
Anda sedang offline.
Data terakhir tersedia pada 16 Sep 2026, 10:30.
```

---

## Daftar Pengajuan

### Loading

Skeleton list.

### Empty

```text
Belum ada pengajuan.
```

### Search empty

```text
Pengajuan tidak ditemukan.

Coba kata kunci lain.
```

### Error

```text
Daftar pengajuan gagal dimuat.

[ Coba Lagi ]
```

---

## Detail Mutasi

### Loading

Gunakan skeleton yang mempertahankan layout final.

### Success

Detail + timeline.

### Error

```text
Detail pengajuan tidak dapat dimuat.

[ Coba Lagi ]
```

### Offline

Jika data sebelumnya tersimpan:

```text
Offline
Menampilkan data terakhir yang tersedia.
```

Jangan menampilkan data seolah-olah real-time.

---

## Form Mutasi

### Default

Semua field kosong kecuali informasi aset.

### Validation error

Error ditempatkan **langsung di bawah field**.

Contoh:

```text
Lokasi Tujuan
[........................]

Lokasi tujuan wajib dipilih.
```

### Submit loading

```text
[ Mengirim... ]
```

Button disabled untuk mencegah double submit.

### Success

```text
Pengajuan berhasil dibuat

ELEKTRONIK-2026-00124

Status
Diajukan

[ Lihat Pengajuan ]
```

### Offline

```text
Pengajuan disimpan di perangkat.

Status:
Menunggu Sinkronisasi
```

---

## Verification

### Empty

```text
Tidak ada pengajuan yang menunggu verifikasi.
```

### Loading

Skeleton detail.

### Success

Data lengkap.

### Action error

```text
Verifikasi gagal disimpan.

Data tidak berubah.

[ Coba Lagi ]
```

---

## Approval

### Already processed

Jika pengajuan sudah diproses user lain:

```text
Pengajuan ini sudah diproses.

Tindakan Anda tidak dapat dilanjutkan.
```

Jangan memperbolehkan approval kedua.

---

## Update Aset

### Saving

```text
Menyimpan perubahan...
```

### Success

```text
Data aset berhasil diperbarui.
```

### Error

```text
Perubahan belum tersimpan.

Data aset tetap seperti sebelumnya.

[ Coba Lagi ]
```

Ini mengikuti requirement bahwa kegagalan update harus rollback sehingga data aset tidak berubah.

---

# 9. RESPONSIVE BEHAVIOUR

Walaupun produk utama adalah **mobile Flutter**, design system harus memiliki aturan adaptasi.

## Mobile — 360–599px

Primary target.

Gunakan:

```text
Screen padding: 16px
1 column
Bottom sticky CTA
Bottom navigation
Full-width form
Card stacked
```

Form panjang menggunakan vertical scroll.

Detail approval menggunakan sticky action bar.

---

## Tablet — 600–1023px

Gunakan:

```text
Screen padding: 24px
2-column layout bila memungkinkan
Master data menggunakan wider table/list
Detail + summary dapat berdampingan
```

Contoh:

```text
┌─────────────────────────────┐
│ Detail Mutasi               │
├─────────────────┬───────────┤
│ Informasi       │ Status    │
│ Aset            │ Timeline  │
│ Mutasi          │           │
└─────────────────┴───────────┘
```

---

## Desktop — ≥1024px

**Desktop bukan target utama MVP mobile**, tetapi layout dapat mengakomodasi Admin/operasional bila Flutter Web/Desktop digunakan kemudian.

Gunakan:

```text
Sidebar
Content max-width: 1200px
Table untuk master data
Detail panel
Sticky action
```

Jangan sekadar memperbesar desain mobile.

---

# 10. ACCESSIBILITY

## 10.1 Contrast

Target:

**WCAG 2.2 AA**

Minimum:

```text
Normal text: 4.5:1
Large text:  3:1
UI component: 3:1
```

Primary navy:

```text
#0F3D56
```

dipakai dengan teks putih untuk CTA utama.

Status juga harus memiliki teks/icon sehingga:

```text
Hijau ≠ satu-satunya indikator "Selesai"
```

Contoh:

```text
✓ Selesai
```

bukan hanya:

```text
[ HIJAU ]
```

---

# 10.2 Touch Target

Semua interactive element:

```text
minimum 44 × 44px
```

Untuk primary mobile action lebih baik:

```text
48px height
```

---

# 10.3 Focus Order

Urutan keyboard/focus harus mengikuti urutan visual.

Form:

```text
Username
 ↓
Password
 ↓
Masuk
 ↓
Lupa Password
```

Form mutasi:

```text
Aset
 ↓
Lokasi Tujuan
 ↓
PIC Baru
 ↓
Alasan
 ↓
Dokumen
 ↓
Review
```

Tidak boleh terjadi focus jumping.

---

# 10.4 Keyboard Navigation

Untuk tablet/desktop:

- Tab → elemen berikutnya;
- Shift + Tab → elemen sebelumnya;
- Enter/Space → activate;
- Escape → close dialog/bottom sheet;
- focus indicator selalu terlihat.

---

# 10.5 Screen Reader / Semantics

Karena Flutter bukan HTML, kebutuhan "ARIA" diterjemahkan menjadi **Flutter Semantics**.

Setiap:

- button;
- icon button;
- status;
- form field;
- notification;
- timeline item

harus mempunyai semantic label yang jelas.

Contoh:

Icon:

```text
🔔
```

semantic:

```text
"Notifikasi, 3 belum dibaca"
```

Bukan:

```text
"Button"
```

Status:

```text
"Status pengajuan: Menunggu Approval Kabag"
```

---

# 10.6 Error Accessibility

Jangan mengandalkan warna merah saja.

Gunakan:

```text
⚠ Lokasi tujuan wajib dipilih.
```

Screen reader harus dapat membaca:

```text
"Error. Lokasi tujuan wajib dipilih."
```

---

# 10.7 Status Accessibility

Status harus mempunyai:

```text
Icon + label + color
```

Contoh:

```text
⏳ Menunggu Approval Kabag
```

```text
✓ Selesai
```

```text
! Dikembalikan ke Pemohon
```

---

# 11. NAVIGATION MODEL

## Pemohon

```text
Home
Mutasi Saya
Notifikasi
Profil
```

Floating/primary CTA:

```text
+ Ajukan Mutasi
```

---

## Operator

```text
Home
Pengajuan
Notifikasi
Profil
```

---

## Kabag

```text
Home
Approval
Notifikasi
Profil
```

---

## Kepala Divisi

```text
Home
Approval
Notifikasi
Profil
```

---

## Staff Aset

```text
Home
Update Aset
Riwayat
Notifikasi
Profil
```

---

## Admin

```text
Home
Master Data
Notifikasi
Profil
```

Navigation tidak boleh menampilkan menu yang tidak dimiliki role.

PRD menetapkan akses menu berbeda berdasarkan permission role.

---

# 12. CORE VISUAL HIERARCHY

Prioritas visual MutasiKu:

```text
1. ACTION
2. STATUS
3. NO. TIKET
4. ASSET
5. LOCATION
6. PIC
7. TIMELINE
8. METADATA
```

Untuk detail pengajuan:

```text
┌─────────────────────────────┐
│ Status                      │ ← highest
│ Menunggu Approval Kabag     │
├─────────────────────────────┤
│ ELEKTRONIK-2026-00124       │
├─────────────────────────────┤
│ Laptop Dell Latitude        │
│ AST-00124                   │
├─────────────────────────────┤
│ Kantor Pusat                │
│        ↓                    │
│ Cabang Surabaya             │
├─────────────────────────────┤
│ PIC                         │
│ Rina → Rina                 │
├─────────────────────────────┤
│ Timeline                    │
└─────────────────────────────┘

[ ACTION ]
```

---

# 13. DESIGN DECISIONS YANG DIKUNCI

Keputusan yang dapat langsung masuk Figma:

### Typography
**Inter**

### Primary color
**#0F3D56**

### Secondary
**#0F766E**

### Background
**#F6F8FA**

### Card
**#FFFFFF**

### Border
**#D0D5DD**

### Text
**#172B4D**

### Default radius
**12px**

### Button radius
**8px**

### Base spacing
**4px**

### Mobile padding
**16px**

### Default button height
**48px**

### Status

Selalu:

```text
icon + text + color
```

### Main detail pattern

```text
Status
 ↓
Ticket
 ↓
Asset
 ↓
Mutation
 ↓
PIC
 ↓
Timeline
 ↓
Action
```

### Navigation

Role-based.

### Primary UX pattern

**Status-driven workflow.**

---

# 14. HAL YANG TIDAK BOLEH DIKUNCI SEBELUM BUSINESS DECISION

Design tidak boleh mengarang keputusan untuk:

1. Kriteria approval Kepala Divisi.
2. Apakah auto-close benar-benar berlaku setelah 1×24 jam kerja.
3. Apa yang terjadi ketika Pemohon memilih "Tidak Sesuai".
4. Perhitungan hari libur nasional.
5. Metode autentikasi final.
6. Dokumen pendukung wajib atau opsional.
7. SLA approval Operator/Kabag/Kadiv.
8. Offline untuk role selain Pemohon.
9. Target angka success metrics.
10. Kategori aset awal.

Semua poin tersebut memang tercatat sebagai Open Questions di PRD.

Untuk desain, gunakan **placeholder state**, bukan membuat aturan bisnis palsu.

---

# 15. DEFINITION OF DESIGN READY

MutasiKu dianggap **Design Ready** apabila:

- semua screen MVP sudah memiliki layout;
- semua role sudah memiliki navigation;
- setiap screen memiliki primary action;
- semua status workflow sudah memiliki visual;
- loading/empty/error/success/offline sudah didefinisikan;
- component library sudah dibuat;
- design tokens sudah ditetapkan;
- accessibility rules sudah diterapkan;
- mobile layout sudah final;
- tablet behavior sudah ditentukan;
- seluruh Open Question bisnis diberi placeholder;
- tidak ada screen MVP yang hanya memiliki "TODO".

Setelah titik ini, desain dapat diterjemahkan menjadi widget/component Flutter tanpa perlu membuat keputusan UX besar lagi.