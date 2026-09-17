# SCREEN SPECIFICATION — MUTASIKU

**Product:** MutasiKu  
**Platform:** Mobile — Flutter  
**Version:** MVP 1.0  
**Status:** Design Specification  
**Source:** PRD MutasiKu + Design Brief MutasiKu  
**Tanggal:** 16 September 2026

---

# 1. PURPOSE

Dokumen ini mendefinisikan spesifikasi setiap screen yang dibutuhkan MutasiKu MVP sebelum masuk ke tahap wireframe dan UI implementation.

Dokumen ini menjadi penghubung antara:

```text
PRD
 ↓
Design Brief
 ↓
SCREEN-SPEC
 ↓
Wireframe
 ↓
UI Design
 ↓
Technical Design
 ↓
Flutter Implementation
```

Screen specification tidak menentukan implementasi kode.

Fokus dokumen:

- screen;
- tujuan;
- actor/role;
- entry point;
- layout;
- hierarchy;
- component;
- primary action;
- secondary action;
- navigation;
- validation;
- state;
- permission.

---

# 2. GLOBAL SCREEN RULES

## 2.1 Screen Structure

Screen mobile menggunakan struktur:

```text
┌──────────────────────────────┐
│ AppBar                       │
├──────────────────────────────┤
│                              │
│ Page Content                 │
│                              │
│                              │
├──────────────────────────────┤
│ Sticky Action / Navigation   │
└──────────────────────────────┘
```

Tidak semua screen membutuhkan sticky action.

---

# 2.2 Screen Padding

Mobile:

```text
16px
```

Tablet:

```text
24px
```

---

# 2.3 Primary Action

Setiap screen yang memungkinkan tindakan user harus memiliki satu primary action.

Contoh:

```text
Ajukan Mutasi
Verifikasi
Setujui
Update Data Aset
Konfirmasi
```

---

# 2.4 Destructive Action

Action:

- Tolak;
- Kembalikan;
- Delete;

harus membutuhkan confirmation atau alasan sesuai business rule.

---

# 2.5 Status

Status pengajuan selalu menggunakan:

```text
Icon + Label + Semantic Color
```

Tidak boleh hanya menggunakan warna.

---

# 2.6 Loading

Gunakan skeleton/loading state yang mempertahankan struktur layout.

Hindari blank screen.

---

# 2.7 Error

Error harus:

1. menjelaskan masalah;
2. tidak menyalahkan user;
3. memberikan tindakan jika memungkinkan.

Contoh:

```text
Data belum dapat dimuat.

[ Coba Lagi ]
```

---

# 3. SCREEN MAP

## Shared

```text
SPL-001 Splash
AUT-001 Login
NOT-001 Notification
PRF-001 Profile
ERR-001 Error State
OFF-001 Offline State
```

## Pemohon

```text
REQ-001 Dashboard Pemohon
REQ-002 Daftar Mutasi Saya
REQ-003 Pilih Aset
REQ-004 Form Mutasi
REQ-005 Review Pengajuan
REQ-006 Submit Success
REQ-007 Detail Mutasi
REQ-008 Edit Pengajuan
REQ-009 Konfirmasi Mutasi
```

## Operator

```text
OPR-001 Dashboard Operator
OPR-002 Pengajuan Masuk
OPR-003 Detail Verifikasi
OPR-004 Form Pengembalian
```

## Kabag Aset

```text
KBG-001 Dashboard Kabag
KBG-002 Menunggu Approval
KBG-003 Detail Approval
KBG-004 Reject Approval
```

## Kepala Divisi

```text
KDV-001 Dashboard Kadiv
KDV-002 Menunggu Approval
KDV-003 Detail Approval
KDV-004 Reject Approval
```

## Staff Aset

```text
AST-001 Dashboard Staff
AST-002 Menunggu Update
AST-003 Detail Mutasi
AST-004 Update Data Aset
AST-005 Konfirmasi Update
AST-006 Riwayat Aset
```

## Admin

```text
ADM-001 Dashboard Admin
ADM-002 User Management
ADM-003 User Form
ADM-004 Role Management
ADM-005 Location/Unit
ADM-006 Location/Unit Form
ADM-007 Asset Category
ADM-008 Asset Category Form
ADM-009 Approval Criteria
```

---

# 4. SHARED SCREENS

# SPL-001 — Splash Screen

## Purpose

Menentukan apakah user sudah memiliki session aktif dan mengarahkan user ke halaman yang sesuai.

## Actor

Semua role.

## Layout

```text
┌──────────────────────────┐
│                          │
│                          │
│       MUTASIKU           │
│                          │
│  Pengelolaan Mutasi Aset │
│                          │
│        Loading...        │
│                          │
└──────────────────────────┘
```

## Components

- Logo
- App name
- Loading indicator

## Navigation

```text
Session valid
→ Dashboard sesuai role

Session tidak valid
→ Login
```

---

# AUT-001 — Login

## Purpose

Mengautentikasi user.

## Actor

Semua role.

## Layout

```text
App Logo

Selamat Datang
Masuk untuk mengelola mutasi aset.

Username
[________________]

Password
[________________]

[ Masuk ]

Lupa password?
```

## Components

- TextField
- PasswordField
- PrimaryButton
- ErrorMessage

## Primary Action

**Masuk**

## Validation

Username:

```text
Required
```

Password:

```text
Required
```

## Success

Redirect berdasarkan role.

## Error

```text
Username atau password tidak sesuai.
```

Jangan mengungkap apakah username terdaftar atau tidak.

## States

- Default
- Field focused
- Validation error
- Loading
- Authentication error
- Offline

---

# NOT-001 — Notification

## Purpose

Menampilkan perubahan status atau tindakan yang membutuhkan perhatian user.

## Actor

Semua role.

## Layout

```text
Notifikasi

Hari ini

● Pengajuan ELEKTRONIK-2026-00124
  Menunggu approval Kabag
  10 menit lalu

● Mutasi AST-00120 selesai
  1 jam lalu

Sebelumnya

● ...
```

## Components

- NotificationItem
- StatusBadge
- UnreadIndicator

## Interaction

Tap notification:

```text
Notification
→ Detail Mutasi
```

## States

### Empty

```text
Belum ada notifikasi.
```

### Unread

Bold title + indicator.

### Read

Normal text.

### Error

```text
Notifikasi belum dapat dimuat.
[ Coba Lagi ]
```

---

# PRF-001 — Profile

## Purpose

Menampilkan identitas user dan role aktif.

## Layout

```text
Profil

[Avatar]

Nama
Rina

Username
rina01

Role
Pemohon

Unit
Kantor Pusat

Status
Aktif

[ Keluar ]
```

## Components

- ProfileHeader
- InformationRow
- RoleBadge
- LogoutButton

## Primary Action

Tidak ada.

Logout adalah destructive/secondary action.

---

# 5. PEMOHON SCREENS

# REQ-001 — Dashboard Pemohon

## Purpose

Memberikan overview cepat mengenai pengajuan user.

## Entry

Login → Dashboard.

## Layout

```text
┌──────────────────────────┐
│ Halo, Rina          🔔   │
├──────────────────────────┤
│                          │
│ Pengajuan Saya           │
│                          │
│ ┌─────────┐ ┌─────────┐ │
│ │ Diproses│ │ Selesai │ │
│ │    2    │ │    8    │ │
│ └─────────┘ └─────────┘ │
│                          │
│ Pengajuan Terbaru        │
│                          │
│ ┌──────────────────────┐ │
│ │ ELEKTRONIK-2026-124  │ │
│ │ Laptop Dell Latitude │ │
│ │ Menunggu Approval    │ │
│ └──────────────────────┘ │
│                          │
│ [ + Ajukan Mutasi ]      │
└──────────────────────────┘
```

## Sections

1. Greeting
2. Notification
3. Summary
4. Recent mutation
5. Primary CTA

## Primary Action

**Ajukan Mutasi**

## Secondary

Tap mutation card → Detail.

## States

Loading:

Skeleton.

Empty:

```text
Belum ada pengajuan.

[ Ajukan Mutasi ]
```

Error:

```text
Ringkasan belum dapat dimuat.
[ Coba Lagi ]
```

Offline:

Menampilkan data terakhir jika tersedia.

---

# REQ-002 — Daftar Mutasi Saya

## Purpose

Melihat seluruh pengajuan milik Pemohon.

## Layout

```text
Pengajuan Saya

[ Search........................ ]

[ Semua ] [ Diproses ] [ Selesai ]

────────────────────────

ELEKTRONIK-2026-00124
Laptop Dell Latitude

Kantor Pusat
↓
Cabang Surabaya

Menunggu Approval Kabag

16 Sep 2026
```

## Components

- SearchField
- FilterChip
- MutationCard
- StatusBadge

## Interaction

Tap item:

```text
→ REQ-007 Detail Mutasi
```

## States

Empty:

```text
Belum ada pengajuan mutasi.
```

Search empty:

```text
Pengajuan tidak ditemukan.
```

---

# REQ-003 — Pilih Aset

## Purpose

Memilih aset yang menjadi tanggung jawab Pemohon.

## Rule

Hanya aset yang dimiliki/menjadi tanggung jawab user yang dapat dipilih.

## Layout

```text
Pilih Aset

Cari aset

[ Search........................ ]

Aset Saya

○ Laptop Dell Latitude
  AST-00124
  Kantor Pusat

○ Printer Epson
  AST-00451
  Kantor Pusat

[ Lanjutkan ]
```

## Components

- SearchField
- AssetCard
- Radio/Selection
- PrimaryButton

## Primary Action

**Lanjutkan**

Disabled sampai aset dipilih.

## Error

Jika aset sedang dalam mutasi:

```text
Aset ini sedang dalam proses mutasi
dan tidak dapat diajukan kembali.
```

---

# REQ-004 — Form Mutasi

## Purpose

Mengumpulkan data mutasi.

## Layout

```text
Ajukan Mutasi

Aset
Laptop Dell Latitude
AST-00124

Lokasi Tujuan
[ Pilih lokasi ▼ ]

Penanggung Jawab Baru
[ Pilih PIC ▼ ]

Alasan Mutasi
[............................]
[............................]

Dokumen Pendukung
[ + Upload Dokumen ]

[ Review Pengajuan ]
```

## Fields

### Asset

Read-only.

### Destination

Required.

### New PIC

Required.

### Reason

Required.

### Supporting document

Status mandatory/optional masih mengikuti keputusan bisnis.

## Primary Action

**Review Pengajuan**

## Validation

Destination:

```text
Wajib dipilih.
```

PIC:

```text
Wajib dipilih.
```

Reason:

```text
Wajib diisi.
```

## Edge Case

Asset already active mutation:

```text
Aset sedang dalam proses mutasi lain.
Pengajuan tidak dapat dilanjutkan.
```

---

# REQ-005 — Review Pengajuan

## Purpose

Memberikan kesempatan terakhir kepada Pemohon untuk memeriksa data sebelum submit.

## Layout

```text
Review Pengajuan

Aset
Laptop Dell Latitude
AST-00124

Lokasi
Kantor Pusat
↓
Cabang Surabaya

PIC
Rina
↓
Rina

Alasan
Perpindahan unit kerja

Dokumen
SK_Mutasi.pdf

[ Edit ]
[ Ajukan Mutasi ]
```

## Primary Action

**Ajukan Mutasi**

## Secondary

**Edit**

Back → Form.

---

# REQ-006 — Submit Success

## Purpose

Mengonfirmasi pengajuan berhasil dikirim.

## Layout

```text
✓

Pengajuan Berhasil

No. Tiket

ELEKTRONIK-2026-00124

Status

Diajukan

Pengajuan telah diteruskan
ke Operator untuk diverifikasi.

[ Lihat Detail ]
[ Kembali ke Beranda ]
```

## Primary Action

**Lihat Detail**

---

# REQ-007 — Detail Mutasi

## Purpose

Screen utama untuk tracking satu pengajuan.

## Layout

```text
← Detail Mutasi

ELEKTRONIK-2026-00124

[ Menunggu Approval Kabag ]

────────────────────────

TIMELINE

✓ Diajukan
  16 Sep 09:20

✓ Verifikasi Operator
  Valid — 16 Sep 10:05

● Menunggu Approval Kabag
  Saat ini

○ Update Data Aset

○ Konfirmasi Pemohon

────────────────────────

DETAIL ASET

Laptop Dell Latitude
AST-00124

────────────────────────

MUTASI

Kantor Pusat
↓
Cabang Surabaya

────────────────────────

PENANGGUNG JAWAB

Rina
↓
Rina

────────────────────────

ALASAN

Perpindahan unit kerja
```

## Primary Action

Bergantung status.

Contoh:

```text
Menunggu Konfirmasi
→ [ Konfirmasi Mutasi ]
```

Jika tidak ada action:

Tidak ada sticky CTA.

## Components

- StatusBadge
- TicketHeader
- Timeline
- AssetInfo
- LocationTransfer
- PICTransfer
- DetailSection
- StickyAction

## States

- Loading
- Success
- Error
- Offline/read-only cached

---

# REQ-008 — Edit Pengajuan

## Purpose

Memperbaiki pengajuan yang dikembalikan Operator.

## Entry

```text
Detail
→ Dikembalikan
→ Edit
```

## Layout

Sama seperti REQ-004, tetapi tampilkan:

```text
⚠ Pengajuan Dikembalikan

Catatan Operator:

"Lokasi tujuan belum sesuai
dengan unit kerja tujuan."
```

Kemudian form.

## Rule

No. tiket tetap sama ketika resubmit.

PRD menetapkan pengajuan yang dikembalikan dapat diedit dan diajukan kembali dengan No. Tiket yang sama. 

## Primary Action

**Ajukan Ulang**

---

# REQ-009 — Konfirmasi Mutasi

## Purpose

Memastikan Pemohon mengonfirmasi hasil mutasi.

## Layout

```text
Konfirmasi Mutasi

Data aset telah diperbarui.

Laptop Dell Latitude
AST-00124

Lokasi
Kantor Pusat
↓
Cabang Surabaya

PIC
Rina
↓
Rina

Apakah data tersebut sudah sesuai
dengan kondisi fisik?

[ ✓ Sesuai ]

[ Tidak Sesuai ]
```

## Primary Action

**Sesuai**

## Secondary/Destructive

**Tidak Sesuai**

Flow setelah "Tidak Sesuai" belum dikunci karena merupakan Open Question pada PRD.

Jangan membuat screen lanjutan final sampai business rule ditentukan.

---

# 6. OPERATOR SCREENS

# OPR-001 — Dashboard Operator

## Purpose

Menampilkan pekerjaan verifikasi yang perlu dilakukan.

## Layout

```text
Dashboard

Halo, Operator

Menunggu Verifikasi
12

Pengajuan Dikembalikan
4

Pengajuan Terbaru

[ MutationCard ]

[ Lihat Pengajuan ]
```

## Primary Action

**Lihat Pengajuan**

---

# OPR-002 — Pengajuan Masuk

## Purpose

Menampilkan pengajuan berstatus Diajukan.

## Layout

```text
Pengajuan Masuk

[ Search................ ]

[ Terbaru ] [ Terlama ]

────────────────────

ELEKTRONIK-2026-00124
Laptop Dell Latitude

Pemohon
Rina

Diajukan
16 Sep 2026 09:20

[ Diajukan ]
```

## Interaction

Tap → OPR-003.

---

# OPR-003 — Detail Verifikasi

## Purpose

Memeriksa kelengkapan dan validitas pengajuan.

## Layout

```text
Detail Verifikasi

ELEKTRONIK-2026-00124
Diajukan

Pemohon
Rina

Aset
Laptop Dell Latitude
AST-00124

Lokasi Asal
Kantor Pusat

Lokasi Tujuan
Cabang Surabaya

PIC Baru
Rina

Alasan
Perpindahan unit kerja

Dokumen
SK_Mutasi.pdf

────────────────────

[ Kembalikan ]
[ Verifikasi Valid ]
```

## Primary Action

**Verifikasi Valid**

## Secondary

**Kembalikan**

## Rule

Jika mengembalikan, alasan wajib.

---

# OPR-004 — Form Pengembalian

## Purpose

Memberikan alasan pengembalian.

## Layout

```text
Kembalikan Pengajuan

Alasan Pengembalian
[.............................]
[.............................]

Contoh:
"Dokumen pendukung belum lengkap."

[ Batal ]
[ Kembalikan Pengajuan ]
```

## Validation

Reason required.

## Primary Action

**Kembalikan Pengajuan**

---

# 7. KABAG ASET SCREENS

# KBG-001 — Dashboard Kabag

## Purpose

Memberikan overview pekerjaan approval.

## Layout

```text
Dashboard Kabag

Menunggu Approval
8

Disetujui Hari Ini
5

Ditolak
1

Pengajuan Terbaru

[ MutationCard ]
```

---

# KBG-002 — Menunggu Approval

## Purpose

Daftar pengajuan yang sudah lolos verifikasi Operator.

## Filter

```text
[ Semua ]
[ Prioritas ]
[ Terbaru ]
```

Catatan: filter "Prioritas" hanya digunakan jika aturan prioritas bisnis memang ditetapkan. Jangan menciptakan prioritas baru dari UI.

---

# KBG-003 — Detail Approval

## Layout

```text
Detail Approval

ELEKTRONIK-2026-00124
Menunggu Approval Kabag

Aset
Laptop Dell Latitude

Pemohon
Rina

Lokasi
Kantor Pusat
↓
Cabang Surabaya

PIC
Rina
↓
Rina

Alasan
Perpindahan unit

Timeline
✓ Diajukan
✓ Verifikasi
● Approval Kabag

────────────────────

[ Tolak ]
[ Setujui ]
```

## Primary Action

**Setujui**

## Secondary

**Tolak**

---

# KBG-004 — Reject Approval

## Layout

```text
Tolak Pengajuan

Alasan Penolakan
[.............................]

Alasan wajib diisi.

[ Batal ]
[ Tolak Pengajuan ]
```

## Primary Action

**Tolak Pengajuan**

---

# 8. KEPALA DIVISI SCREENS

Struktur screen Kadiv dibuat konsisten dengan Kabag karena fungsi utama keduanya adalah review dan approval.

# KDV-001 — Dashboard Kadiv

Menampilkan:

- jumlah menunggu approval;
- pengajuan terbaru;
- notifikasi.

---

# KDV-002 — Menunggu Approval

Hanya menampilkan pengajuan yang memenuhi kriteria approval Kadiv.

Tidak menampilkan pengajuan yang tidak membutuhkan approval Kadiv.

---

# KDV-003 — Detail Approval

Struktur:

```text
Detail Approval

No. Tiket
Status

Aset
Pemohon
Lokasi
PIC
Alasan
Dokumen
Timeline

[ Tolak ]
[ Setujui ]
```

---

# KDV-004 — Reject Approval

Sama dengan KBG-004.

Reason wajib.

---

# 9. STAFF ASET SCREENS

# AST-001 — Dashboard Staff Aset

## Layout

```text
Dashboard Staff Aset

Menunggu Update
7

Mutasi Selesai
24

Update Terbaru

[ MutationCard ]

[ Lihat Pengajuan ]
```

---

# AST-002 — Menunggu Update

## Purpose

Menampilkan pengajuan yang seluruh approval-nya telah selesai.

## Status source

```text
Disetujui — Menunggu Update Aset
```

---

# AST-003 — Detail Mutasi

## Layout

```text
Detail Mutasi

ELEKTRONIK-2026-00124

✓ Approval Kabag
✓ Approval Kadiv

Data Mutasi

Lokasi:
Kantor Pusat
↓
Cabang Surabaya

PIC:
Rina
↓
Rina

────────────────────

Data Saat Ini

Lokasi:
Kantor Pusat

PIC:
Rina

[ Update Data Aset ]
```

---

# AST-004 — Update Data Aset

## Purpose

Mengubah lokasi dan PIC aset.

## Layout

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

────────────────────

[ Simpan Perubahan ]
```

## Primary Action

**Simpan Perubahan**

---

# AST-005 — Konfirmasi Update

## Purpose

Mencegah accidental update.

## Layout

```text
Konfirmasi Perubahan

Data aset akan diperbarui:

Lokasi
Kantor Pusat
↓
Cabang Surabaya

PIC
Rina
↓
Rina

Perubahan akan tercatat
dalam riwayat aset.

[ Batal ]
[ Konfirmasi Update ]
```

## Primary Action

**Konfirmasi Update**

---

# AST-006 — Riwayat Aset

## Purpose

Melihat perjalanan aset dari waktu ke waktu.

## Layout

```text
Riwayat Aset

AST-00124
Laptop Dell Latitude

────────────────────

16 Sep 2026

Kantor Pusat
↓
Cabang Surabaya

PIC
Rina → Rina

ELEKTRONIK-2026-00124

────────────────────

03 Feb 2025

Cabang Palu
↓
Kantor Pusat

PIC
Rina → Rina

ELEKTRONIK-2025-00021
```

## Components

- AssetHeader
- MutationTimeline
- HistoryItem

---

# 10. ADMIN SCREENS

Admin adalah role pengelola master data, bukan role approval mutasi.

---

# ADM-001 — Dashboard Admin

## Layout

```text
Dashboard Admin

Master Data

Users
128

Lokasi/Unit
14

Kategori Aset
6

────────────────

[ Kelola User ]

[ Kelola Role ]

[ Kelola Lokasi/Unit ]

[ Kelola Kategori Aset ]

[ Approval Criteria ]
```

---

# ADM-002 — User Management

## Purpose

CRUD user.

## Layout

```text
Users

[ Search user................ ]

[ + Tambah User ]

────────────────

Rina
Pemohon
Kantor Pusat
Aktif

Budi
Staff Aset
Kantor Pusat
Aktif
```

## Components

- Search
- UserCard
- StatusBadge
- AddButton

---

# ADM-003 — User Form

## Fields

```text
Nama
Username / Email
Role
Lokasi / Unit
Status
Password
```

## Primary

**Simpan User**

---

# ADM-004 — Role Management

## Purpose

Melihat role dan permission.

## Layout

```text
Role

Pemohon
Pengajuan & tracking

Operator
Verifikasi pengajuan

Kabag Aset
Approval

Kepala Divisi
Approval kondisional

Staff Aset
Update aset + history

Admin
Master data
```

Role definition bersumber dari PRD.

---

# ADM-005 — Location/Unit

## Purpose

CRUD lokasi/unit.

## Layout

```text
Lokasi / Unit

[ + Tambah Lokasi ]

Kantor Pusat
Kantor Pusat
Aktif

Cabang Surabaya
Cabang
Aktif
```

---

# ADM-006 — Location/Unit Form

## Fields

```text
Nama Lokasi
Tipe
Alamat
Status
```

Tipe:

```text
Kantor Pusat
Cabang
Unit
```

---

# ADM-007 — Asset Category

## Purpose

CRUD kategori aset.

## Layout

```text
Kategori Aset

[ + Tambah Kategori ]

Elektronik
Kode: ELEKTRONIK
Aktif

Furniture
Kode: FURNITURE
Aktif
```

Kode kategori digunakan dalam No. Tiket.

---

# ADM-008 — Asset Category Form

## Fields

```text
Nama Kategori
Kode Kategori
Status
```

---

# ADM-009 — Approval Criteria

## Purpose

Mengatur kondisi yang menyebabkan pengajuan membutuhkan approval Kepala Divisi.

## Layout

```text
Approval Kepala Divisi

Kategori Aset

[ Elektronik ▼ ]

Nilai Minimum
[ Rp ................ ]

Status
[ Aktif ]

────────────────────

Keterangan:
Pengajuan yang memenuhi
kriteria ini membutuhkan
approval Kepala Divisi.

[ Simpan Kriteria ]
```

## Important

UI tidak boleh menentukan sendiri nilai threshold.

Nilai berasal dari konfigurasi Admin/business decision.

Perubahan kriteria hanya berlaku untuk pengajuan baru, bukan pengajuan yang sedang berjalan.

---

# 11. COMMON ERROR SCREENS

# ERR-001 — Generic Error

```text
Terjadi kesalahan

Kami tidak dapat menyelesaikan
permintaan saat ini.

[ Coba Lagi ]
```

---

# ERR-002 — Permission Denied

```text
Akses Ditolak

Anda tidak memiliki izin untuk
melakukan tindakan ini.

[ Kembali ]
```

PRD menetapkan tidak boleh ada perubahan data jika permission ditolak.

---

# ERR-003 — Asset Conflict

```text
Aset Sedang Diproses

Aset ini sedang memiliki
pengajuan mutasi aktif.

Pengajuan baru tidak dapat dibuat.

[ Kembali ]
```

---

# ERR-004 — Save Failure

```text
Perubahan Belum Tersimpan

Data aset tidak berubah.
Silakan coba lagi.

[ Coba Lagi ]
```

Digunakan terutama pada update aset.

---

# 12. OFFLINE SCREENS / STATES

Offline bukan berarti semua role dapat bekerja offline.

MVP secara eksplisit memprioritaskan offline untuk Pemohon.

---

# OFF-001 — Offline Banner

Persistent banner:

```text
⚠ Offline

Tidak ada koneksi internet.
Data akan disinkronkan saat online.
```

---

# OFF-002 — Pending Sync

```text
Menunggu Sinkronisasi

Pengajuan Anda telah disimpan
di perangkat.

No. Tiket akan dibuat setelah
sinkronisasi berhasil.

Status:
Menunggu Sinkronisasi
```

---

# OFF-003 — Sync Success

```text
✓ Sinkronisasi Berhasil

No. Tiket:

ELEKTRONIK-2026-00124

Status:
Diajukan
```

---

# OFF-004 — Sync Conflict

```text
Sinkronisasi Tidak Dapat Dilanjutkan

Aset ini telah berubah sejak
pengajuan dibuat secara offline.

Pengajuan belum dikirim.

Silakan periksa kembali data aset.

[ Periksa Pengajuan ]
```

PRD menetapkan konflik tidak boleh otomatis dikirim ke server.

---

# 13. STATUS → SCREEN ACTION MATRIX

| Status | Pemohon | Operator | Kabag | Kadiv | Staff Aset |
|---|---|---|---|---|---|
| Menunggu Sinkronisasi | Lihat | — | — | — | — |
| Diajukan | Lihat | Verifikasi | — | — | — |
| Dikembalikan | Edit | — | — | — | — |
| Menunggu Approval Kabag | Lihat | — | Review | — | — |
| Menunggu Approval Kadiv | Lihat | — | — | Review | — |
| Disetujui — Menunggu Update | Lihat | — | — | — | Update |
| Menunggu Konfirmasi Pemohon | Konfirmasi | — | — | — | — |
| Selesai | Lihat | — | — | — | Lihat |
| Selesai (Auto) | Lihat | — | — | — | Lihat |
| Ditolak | Lihat | — | — | — | Lihat |

`—` berarti tidak ada action workflow pada status tersebut.

---

# 14. SCREEN-LEVEL COMPONENT MATRIX

| Component | Pemohon | Operator | Kabag | Kadiv | Staff | Admin |
|---|---:|---:|---:|---:|---:|---:|
| StatusBadge | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| MutationCard | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| Timeline | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| AssetCard | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| ApprovalAction | — | — | ✓ | ✓ | — | — |
| VerificationAction | — | ✓ | — | — | — | — |
| UpdateAssetAction | — | — | — | — | ✓ | — |
| MasterDataTable | — | — | — | — | — | ✓ |
| Search | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Notification | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

---

# 15. NAVIGATION RULES

## Pemohon

```text
Home
├── Ajukan Mutasi
│   ├── Pilih Aset
│   ├── Form
│   ├── Review
│   └── Success
│
├── Mutasi Saya
│   └── Detail Mutasi
│
├── Notifikasi
│   └── Detail Mutasi
│
└── Profil
```

---

## Operator

```text
Home
├── Pengajuan Masuk
│   └── Detail Verifikasi
│       └── Pengembalian
│
├── Notifikasi
│
└── Profil
```

---

## Kabag

```text
Home
├── Menunggu Approval
│   └── Detail Approval
│       └── Reject
│
├── Notifikasi
└── Profil
```

---

## Kadiv

```text
Home
├── Menunggu Approval
│   └── Detail Approval
│       └── Reject
│
├── Notifikasi
└── Profil
```

---

## Staff Aset

```text
Home
├── Menunggu Update
│   └── Detail
│       └── Update Data
│           └── Konfirmasi Update
│
├── Riwayat Aset
├── Notifikasi
└── Profil
```

---

## Admin

```text
Home
├── User
│   └── User Form
├── Role
├── Lokasi/Unit
│   └── Location Form
├── Kategori Aset
│   └── Category Form
├── Approval Criteria
├── Notifikasi
└── Profil
```

---

# 16. SCREEN STATE STANDARD

Setiap screen data-driven harus mendukung:

```text
DEFAULT
 ↓
LOADING
 ↓
SUCCESS
```

dan kemungkinan:

```text
ERROR
EMPTY
OFFLINE
```

Untuk action:

```text
IDLE
 ↓
SUBMITTING
 ↓
SUCCESS / ERROR
```

Tidak boleh ada button yang bisa ditekan berkali-kali ketika request sedang berlangsung.

---

# 17. DESIGN HANDOFF RULE

Sebelum masuk UI high-fidelity, setiap screen harus memiliki:

- Screen ID;
- Screen name;
- Role;
- Purpose;
- Entry point;
- Exit point;
- Layout;
- Components;
- Primary action;
- Secondary action;
- Validation;
- Success state;
- Error state;
- Empty state;
- Loading state;
- Offline behavior;
- Permission.

Jika salah satu belum ada, screen belum dianggap design-ready.

---

# 18. MVP BOUNDARY

Screen berikut **tidak dibuat dalam MVP**:

```text
Mutasi Rusak/Hilang
Mutasi Massal
Mutasi oleh pihak lain
Dashboard Analitik
Export PDF
Export Excel
Push Notification
Partial Bundle Mutation
ERP Integration
QR/Barcode Scan
Dynamic Workflow Builder
```

Fitur-fitur tersebut berada pada V2/Nanti menurut PRD dan tidak boleh masuk scope UI MVP.

---

# 19. DESIGN BLOCKERS

Screen specification dapat dilanjutkan ke wireframe, tetapi beberapa interaksi sengaja diberi placeholder karena keputusan bisnis belum tersedia:

1. Kriteria konkret approval Kepala Divisi.
2. Perilaku setelah Pemohon memilih "Tidak Sesuai".
3. Apakah auto-close benar-benar diterapkan.
4. Perhitungan hari libur untuk SLA.
5. Dokumen wajib/opsional.
6. SLA approval.
7. Offline untuk role selain Pemohon.
8. Metode autentikasi final.

Tidak boleh membuat UI yang mengunci keputusan tersebut sebagai fakta sebelum business decision ditetapkan.

---

# 20. DEFINITION OF SCREEN READY

MutasiKu siap masuk tahap wireframe apabila:

- semua screen MVP memiliki ID;
- setiap role memiliki navigation;
- setiap workflow memiliki screen;
- setiap screen memiliki primary action;
- status memiliki representasi visual;
- loading/empty/error/success/offline telah ditentukan;
- validation sudah ditentukan;
- permission sudah ditentukan;
- edge case utama sudah memiliki screen/state;
- tidak ada screen MVP yang masih `TODO`;
- Open Questions tidak disamarkan menjadi business rule.

**Status dokumen: READY FOR WIREFRAME**