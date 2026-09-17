# WIREFRAME SPECIFICATION — MUTASIKU

**Product:** MutasiKu  
**Platform:** Mobile — Flutter  
**Version:** MVP 1.0  
**Status:** Low-Fidelity Wireframe  
**Tanggal:** 16 September 2026

---

# 1. TUJUAN

Wireframe ini menjadi blueprint struktur visual MutasiKu sebelum masuk ke tahap UI Design.

Fokus:

- hierarchy informasi;
- posisi komponen;
- navigasi;
- CTA;
- form;
- status;
- workflow;
- responsive behavior.

Wireframe **tidak menentukan**:

- warna final;
- typography final;
- icon final;
- illustration;
- animation;
- shadow/detail visual.

Detail visual mengikuti `DESIGN-BRIEF.md`.

---

# 2. MOBILE FRAME

Target utama:

```text
┌────────────────────────────┐
│       360–599 px           │
│                            │
│        CONTENT             │
│                            │
│        PADDING 16          │
│                            │
└────────────────────────────┘
```

Default:

```text
Screen width : 360–599 px
Padding      : 16 px
Spacing      : 8 / 12 / 16 / 24
Button       : minimum 48 px
Card         : 12 px radius
```

---

# 3. GLOBAL NAVIGATION

Navigation disesuaikan dengan role.

## Pemohon

```text
┌────────────────────────────┐
│                            │
│         CONTENT            │
│                            │
├────────────────────────────┤
│  Home   Mutasi   🔔   Profil│
└────────────────────────────┘
```

## Operator

```text
┌────────────────────────────┐
│         CONTENT            │
│                            │
├────────────────────────────┤
│ Home  Pengajuan  🔔  Profil│
└────────────────────────────┘
```

## Kabag / Kadiv

```text
┌────────────────────────────┐
│         CONTENT            │
│                            │
├────────────────────────────┤
│ Home  Approval  🔔  Profil │
└────────────────────────────┘
```

## Staff Aset

```text
┌────────────────────────────┐
│         CONTENT            │
│                            │
├────────────────────────────┤
│ Home  Update  History Profil│
└────────────────────────────┘
```

## Admin

```text
┌────────────────────────────┐
│         CONTENT            │
│                            │
├────────────────────────────┤
│ Home   Master   🔔  Profil │
└────────────────────────────┘
```

---

# 4. SHARED WIREFRAMES

# WF-001 — Splash

```text
┌────────────────────────────┐
│                            │
│                            │
│          LOGO              │
│                            │
│        MUTASIKU            │
│                            │
│   Pengelolaan Mutasi Aset  │
│                            │
│                            │
│          (...)             │
│                            │
└────────────────────────────┘
```

Flow:

```text
Splash
  │
  ├── Session valid ──→ Dashboard
  │
  └── Session invalid ─→ Login
```

---

# WF-002 — Login

```text
┌────────────────────────────┐
│                            │
│           LOGO             │
│                            │
│       Selamat Datang       │
│   Masuk ke akun MutasiKu   │
│                            │
│ Username                   │
│ ┌────────────────────────┐ │
│ │                        │ │
│ └────────────────────────┘ │
│                            │
│ Password                   │
│ ┌────────────────────── 👁┐ │
│ │                        │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │         MASUK          │ │
│ └────────────────────────┘ │
│                            │
└────────────────────────────┘
```

Interaction:

```text
Masuk
 ↓
Loading
 ↓
Success → Dashboard sesuai role
 ↓
Error → Error message
```

---

# 5. PEMOHON WIREFRAMES

# WF-REQ-001 — Dashboard Pemohon

Prioritas informasi:

1. Greeting;
2. Notification;
3. jumlah pengajuan;
4. pengajuan terbaru;
5. CTA.

```text
┌────────────────────────────┐
│ Halo, Rina             🔔  │
│                            │
│ Pengajuan Saya             │
│                            │
│ ┌──────────┐ ┌──────────┐ │
│ │ Diproses │ │ Selesai  │ │
│ │    2     │ │    8     │ │
│ └──────────┘ └──────────┘ │
│                            │
│ Pengajuan Terbaru          │
│                            │
│ ┌────────────────────────┐ │
│ │ ELEKTRONIK-2026-00124  │ │
│ │ Laptop Dell Latitude   │ │
│ │                        │ │
│ │ Menunggu Approval      │ │
│ │ 16 Sep 2026            │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │    + AJUKAN MUTASI     │ │
│ └────────────────────────┘ │
│                            │
├────────────────────────────┤
│ Home   Mutasi   🔔  Profil │
└────────────────────────────┘
```

---

# WF-REQ-002 — Daftar Mutasi

```text
┌────────────────────────────┐
│ Pengajuan Saya             │
│                            │
│ ┌────────────────────────┐ │
│ │ 🔍 Cari pengajuan      │ │
│ └────────────────────────┘ │
│                            │
│ [Semua] [Proses] [Selesai]│
│                            │
│ ┌────────────────────────┐ │
│ │ ELEKTRONIK-2026-00124  │ │
│ │ Laptop Dell Latitude   │ │
│ │                        │ │
│ │ Kantor Pusat           │ │
│ │       ↓                │ │
│ │ Cabang Surabaya        │ │
│ │                        │ │
│ │ Menunggu Approval      │ │
│ │ 16 Sep 2026            │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ FURNITURE-2026-00082   │ │
│ │ Meja Kerja             │ │
│ │                        │ │
│ │ Selesai                │ │
│ └────────────────────────┘ │
│                            │
└────────────────────────────┘
```

---

# WF-REQ-003 — Pilih Aset

```text
┌────────────────────────────┐
│ ← Pilih Aset               │
│                            │
│ ┌────────────────────────┐ │
│ │ 🔍 Cari aset           │ │
│ └────────────────────────┘ │
│                            │
│ Aset Saya                  │
│                            │
│ ┌────────────────────────┐ │
│ │ ○ Laptop Dell Latitude │ │
│ │   AST-00124            │ │
│ │   Kantor Pusat         │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ ○ Printer Epson        │ │
│ │   AST-00451            │ │
│ │   Kantor Pusat         │ │
│ └────────────────────────┘ │
│                            │
│                            │
│ ┌────────────────────────┐ │
│ │       LANJUTKAN        │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

Rule:

- hanya satu aset;
- aset aktif mutation tidak selectable.

---

# WF-REQ-004 — Form Mutasi

```text
┌────────────────────────────┐
│ ← Ajukan Mutasi            │
│                            │
│ ASET                       │
│ ┌────────────────────────┐ │
│ │ Laptop Dell Latitude   │ │
│ │ AST-00124              │ │
│ └────────────────────────┘ │
│                            │
│ Lokasi Tujuan *            │
│ ┌────────────────────────┐ │
│ │ Pilih lokasi        ▼  │ │
│ └────────────────────────┘ │
│                            │
│ PIC Baru *                 │
│ ┌────────────────────────┐ │
│ │ Pilih PIC           ▼  │ │
│ └────────────────────────┘ │
│                            │
│ Alasan Mutasi *            │
│ ┌────────────────────────┐ │
│ │                        │ │
│ │                        │ │
│ └────────────────────────┘ │
│                            │
│ Dokumen                    │
│ ┌────────────────────────┐ │
│ │     + Upload Dokumen   │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │    REVIEW PENGAJUAN    │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-REQ-005 — Review Pengajuan

```text
┌────────────────────────────┐
│ ← Review Pengajuan         │
│                            │
│ Periksa kembali data       │
│ sebelum dikirim.            │
│                            │
│ ASET                       │
│ Laptop Dell Latitude       │
│ AST-00124                  │
│                            │
│ LOKASI                     │
│ Kantor Pusat               │
│       ↓                    │
│ Cabang Surabaya            │
│                            │
│ PIC                        │
│ Rina                       │
│       ↓                    │
│ Rina                       │
│                            │
│ ALASAN                     │
│ Perpindahan unit kerja     │
│                            │
│ DOKUMEN                    │
│ SK_Mutasi.pdf              │
│                            │
│ ┌────────────────────────┐ │
│ │          EDIT          │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │    AJUKAN MUTASI       │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-REQ-006 — Success

```text
┌────────────────────────────┐
│                            │
│             ✓              │
│                            │
│    Pengajuan Berhasil      │
│                            │
│ No. Tiket                  │
│                            │
│ ELEKTRONIK-2026-00124      │
│                            │
│ Status                     │
│ [ Diajukan ]               │
│                            │
│ Pengajuan telah diteruskan │
│ ke Operator.               │
│                            │
│ ┌────────────────────────┐ │
│ │      LIHAT DETAIL      │ │
│ └────────────────────────┘ │
│                            │
│ Kembali ke Beranda         │
│                            │
└────────────────────────────┘
```

---

# WF-REQ-007 — Detail Mutasi

Ini adalah **screen terpenting untuk tracking**.

Hierarchy:

```text
Status
 ↓
Ticket
 ↓
Timeline
 ↓
Asset
 ↓
Mutation
 ↓
PIC
 ↓
Action
```

Wireframe:

```text
┌────────────────────────────┐
│ ← Detail Mutasi        ⋮   │
│                            │
│ ELEKTRONIK-2026-00124      │
│                            │
│ [ Menunggu Approval Kabag ]│
│                            │
│ STATUS PERJALANAN          │
│                            │
│ ● Diajukan                 │
│ │ 16 Sep 09:20             │
│ │                          │
│ ● Verifikasi Operator      │
│ │ Valid — 10:05            │
│ │                          │
│ ● Menunggu Approval Kabag  │
│ │ Saat ini                 │
│ │                          │
│ ○ Update Data Aset         │
│ │                          │
│ ○ Konfirmasi Pemohon       │
│                            │
│ ────────────────────────── │
│                            │
│ ASET                       │
│ Laptop Dell Latitude       │
│ AST-00124                  │
│                            │
│ MUTASI                     │
│ Kantor Pusat               │
│       ↓                    │
│ Cabang Surabaya            │
│                            │
│ PIC                        │
│ Rina                       │
│       ↓                    │
│ Rina                       │
│                            │
│ ALASAN                     │
│ Perpindahan unit kerja     │
│                            │
└────────────────────────────┘
```

Jika membutuhkan action:

```text
┌────────────────────────────┐
│                            │
│      CONTENT               │
│                            │
├────────────────────────────┤
│ [     KONFIRMASI MUTASI    ]│
└────────────────────────────┘
```

CTA hanya muncul ketika status memang membutuhkan tindakan Pemohon.

---

# WF-REQ-008 — Dikembalikan

```text
┌────────────────────────────┐
│ ← Detail Mutasi            │
│                            │
│ ELEKTRONIK-2026-00124      │
│                            │
│ [ Dikembalikan ]           │
│                            │
│ ⚠ Catatan Operator         │
│                            │
│ Dokumen pendukung belum    │
│ lengkap.                   │
│                            │
│ ────────────────────────── │
│                            │
│ DATA PENGAJUAN             │
│ ...                        │
│                            │
│ ┌────────────────────────┐ │
│ │    EDIT PENGAJUAN      │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-REQ-009 — Konfirmasi Mutasi

```text
┌────────────────────────────┐
│ ← Konfirmasi Mutasi        │
│                            │
│ Data aset telah diperbarui.│
│                            │
│ ASET                       │
│ Laptop Dell Latitude       │
│ AST-00124                  │
│                            │
│ LOKASI                     │
│ Kantor Pusat               │
│       ↓                    │
│ Cabang Surabaya            │
│                            │
│ PIC                        │
│ Rina                       │
│       ↓                    │
│ Rina                       │
│                            │
│ ────────────────────────── │
│                            │
│ Apakah data tersebut       │
│ sudah sesuai?              │
│                            │
│ ┌────────────────────────┐ │
│ │       ✓ SESUAI         │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │    TIDAK SESUAI        │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# 6. OPERATOR WIREFRAMES

# WF-OPR-001 — Dashboard

```text
┌────────────────────────────┐
│ Dashboard              🔔  │
│                            │
│ Halo, Operator             │
│                            │
│ Menunggu Verifikasi        │
│ ┌────────────────────────┐ │
│ │          12            │ │
│ └────────────────────────┘ │
│                            │
│ Dikembalikan               │
│ ┌────────────────────────┐ │
│ │           4            │ │
│ └────────────────────────┘ │
│                            │
│ Pengajuan Terbaru          │
│ ┌────────────────────────┐ │
│ │ ELEKTRONIK-2026-00124  │ │
│ │ Diajukan               │ │
│ └────────────────────────┘ │
│                            │
│ [ LIHAT PENGAJUAN ]        │
│                            │
├────────────────────────────┤
│ Home Pengajuan 🔔 Profil   │
└────────────────────────────┘
```

---

# WF-OPR-002 — Pengajuan Masuk

```text
┌────────────────────────────┐
│ ← Pengajuan Masuk          │
│                            │
│ ┌────────────────────────┐ │
│ │ 🔍 Cari                │ │
│ └────────────────────────┘ │
│                            │
│ [Terbaru] [Terlama]        │
│                            │
│ ┌────────────────────────┐ │
│ │ ELEKTRONIK-2026-00124  │ │
│ │ Laptop Dell Latitude   │ │
│ │                        │ │
│ │ Rina                   │ │
│ │ 16 Sep 09:20           │ │
│ │                        │ │
│ │ [ Diajukan ]           │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-OPR-003 — Detail Verifikasi

```text
┌────────────────────────────┐
│ ← Detail Verifikasi        │
│                            │
│ ELEKTRONIK-2026-00124      │
│ [ Diajukan ]               │
│                            │
│ PEMOHON                    │
│ Rina                       │
│                            │
│ ASET                       │
│ Laptop Dell Latitude       │
│ AST-00124                  │
│                            │
│ LOKASI                     │
│ Kantor Pusat               │
│       ↓                    │
│ Cabang Surabaya            │
│                            │
│ PIC BARU                   │
│ Rina                       │
│                            │
│ ALASAN                     │
│ Perpindahan unit kerja     │
│                            │
│ DOKUMEN                    │
│ SK_Mutasi.pdf              │
│                            │
├────────────────────────────┤
│ [ KEMBALIKAN ]             │
│ [ VERIFIKASI VALID ]       │
└────────────────────────────┘
```

---

# WF-OPR-004 — Pengembalian

```text
┌────────────────────────────┐
│ ← Kembalikan Pengajuan     │
│                            │
│ Alasan Pengembalian *      │
│                            │
│ ┌────────────────────────┐ │
│ │                        │ │
│ │                        │ │
│ │                        │ │
│ └────────────────────────┘ │
│                            │
│ Contoh:                    │
│ Dokumen pendukung belum    │
│ lengkap.                   │
│                            │
│ ┌────────────────────────┐ │
│ │ KEMBALIKAN PENGAJUAN   │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# 7. KABAG WIREFRAMES

# WF-KBG-001 — Dashboard

```text
┌────────────────────────────┐
│ Dashboard              🔔  │
│                            │
│ Menunggu Approval          │
│ ┌────────────────────────┐ │
│ │           8            │ │
│ └────────────────────────┘ │
│                            │
│ Disetujui Hari Ini         │
│ ┌────────────────────────┐ │
│ │           5            │ │
│ └────────────────────────┘ │
│                            │
│ Pengajuan Terbaru          │
│ ┌────────────────────────┐ │
│ │ ELEKTRONIK-2026-00124  │ │
│ │ Menunggu Approval       │ │
│ └────────────────────────┘ │
│                            │
│ [ LIHAT APPROVAL ]         │
└────────────────────────────┘
```

---

# WF-KBG-002 — Menunggu Approval

```text
┌────────────────────────────┐
│ ← Menunggu Approval        │
│                            │
│ [Semua] [Terbaru]          │
│                            │
│ ┌────────────────────────┐ │
│ │ ELEKTRONIK-2026-00124  │ │
│ │ Laptop Dell Latitude   │ │
│ │                        │ │
│ │ Rina                   │ │
│ │ Kantor Pusat           │ │
│ │ ↓                      │ │
│ │ Cabang Surabaya        │ │
│ │                        │ │
│ │ Menunggu Approval      │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-KBG-003 — Detail Approval

```text
┌────────────────────────────┐
│ ← Detail Approval          │
│                            │
│ ELEKTRONIK-2026-00124      │
│ [ Menunggu Approval ]      │
│                            │
│ ASET                       │
│ Laptop Dell Latitude       │
│ AST-00124                  │
│                            │
│ PEMOHON                    │
│ Rina                       │
│                            │
│ LOKASI                     │
│ Kantor Pusat               │
│       ↓                    │
│ Cabang Surabaya            │
│                            │
│ PIC                        │
│ Rina → Rina                │
│                            │
│ ALASAN                     │
│ Perpindahan unit kerja     │
│                            │
│ TIMELINE                   │
│ ✓ Diajukan                 │
│ ✓ Verifikasi               │
│ ● Approval Kabag           │
│                            │
├────────────────────────────┤
│ [ TOLAK ] [ SETUJUI ]      │
└────────────────────────────┘
```

---

# WF-KBG-004 — Tolak

```text
┌────────────────────────────┐
│ ← Tolak Pengajuan          │
│                            │
│ Alasan Penolakan *         │
│                            │
│ ┌────────────────────────┐ │
│ │                        │ │
│ │                        │ │
│ │                        │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │     TOLAK PENGAJUAN    │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# 8. KADIV WIREFRAMES

Kadiv menggunakan struktur visual yang sama dengan Kabag, tetapi hanya menerima pengajuan yang memenuhi **Approval Criteria**.

# WF-KDV-001 — Dashboard

```text
┌────────────────────────────┐
│ Dashboard              🔔  │
│                            │
│ Menunggu Approval          │
│ ┌────────────────────────┐ │
│ │           3            │ │
│ └────────────────────────┘ │
│                            │
│ Pengajuan Terbaru          │
│ ┌────────────────────────┐ │
│ │ ELEKTRONIK-2026-00124  │ │
│ │ Menunggu Approval      │ │
│ └────────────────────────┘ │
│                            │
│ [ LIHAT APPROVAL ]         │
└────────────────────────────┘
```

# WF-KDV-002 — Menunggu Approval

Struktur sama dengan KBG-002.

# WF-KDV-003 — Detail Approval

Struktur sama dengan KBG-003.

Tambahkan informasi:

```text
Kriteria Approval Kadiv

Kategori:
Elektronik

Kriteria:
Memenuhi konfigurasi approval
yang berlaku untuk pengajuan ini.
```

Nilai threshold ditampilkan jika memang tersedia sebagai data konfigurasi.

# WF-KDV-004 — Tolak

Struktur sama dengan KBG-004.

---

# 9. STAFF ASET WIREFRAMES

# WF-AST-001 — Dashboard

```text
┌────────────────────────────┐
│ Dashboard              🔔  │
│                            │
│ Menunggu Update            │
│ ┌────────────────────────┐ │
│ │           7            │ │
│ └────────────────────────┘ │
│                            │
│ Mutasi Selesai             │
│ ┌────────────────────────┐ │
│ │          24            │ │
│ └────────────────────────┘ │
│                            │
│ Pengajuan Terbaru          │
│ ┌────────────────────────┐ │
│ │ ELEKTRONIK-2026-00124  │ │
│ │ Siap Update             │ │
│ └────────────────────────┘ │
│                            │
│ [ LIHAT UPDATE ]           │
└────────────────────────────┘
```

---

# WF-AST-002 — Menunggu Update

```text
┌────────────────────────────┐
│ ← Menunggu Update          │
│                            │
│ ┌────────────────────────┐ │
│ │ ELEKTRONIK-2026-00124  │ │
│ │ Laptop Dell Latitude   │ │
│ │                        │ │
│ │ Kantor Pusat           │ │
│ │       ↓                │ │
│ │ Cabang Surabaya        │ │
│ │                        │ │
│ │ Disetujui —             │ │
│ │ Menunggu Update Aset   │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-AST-003 — Detail Mutasi

```text
┌────────────────────────────┐
│ ← Detail Mutasi            │
│                            │
│ ELEKTRONIK-2026-00124      │
│                            │
│ ✓ Approval Kabag           │
│ ✓ Approval Kadiv           │
│                            │
│ DATA MUTASI                │
│                            │
│ Lokasi                     │
│ Kantor Pusat               │
│       ↓                    │
│ Cabang Surabaya            │
│                            │
│ PIC                        │
│ Rina → Rina                │
│                            │
│ DATA SAAT INI              │
│                            │
│ Lokasi                     │
│ Kantor Pusat               │
│                            │
│ PIC                        │
│ Rina                       │
│                            │
├────────────────────────────┤
│ [ UPDATE DATA ASET ]       │
└────────────────────────────┘
```

---

# WF-AST-004 — Update Data Aset

```text
┌────────────────────────────┐
│ ← Update Data Aset         │
│                            │
│ LOKASI                     │
│                            │
│ Sebelum                    │
│ Kantor Pusat               │
│                            │
│ Sesudah                    │
│ ┌────────────────────────┐ │
│ │ Cabang Surabaya     ▼  │ │
│ └────────────────────────┘ │
│                            │
│ PIC                        │
│                            │
│ Sebelum                    │
│ Rina                       │
│                            │
│ Sesudah                    │
│ ┌────────────────────────┐ │
│ │ Rina                ▼  │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │    SIMPAN PERUBAHAN    │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-AST-005 — Konfirmasi Update

```text
┌────────────────────────────┐
│ Konfirmasi Perubahan       │
│                            │
│ Data aset akan diperbarui: │
│                            │
│ Lokasi                     │
│ Kantor Pusat               │
│       ↓                    │
│ Cabang Surabaya            │
│                            │
│ PIC                        │
│ Rina                       │
│       ↓                    │
│ Rina                       │
│                            │
│ Perubahan akan dicatat     │
│ dalam riwayat aset.        │
│                            │
│ [ BATAL ]                  │
│ [ KONFIRMASI UPDATE ]      │
└────────────────────────────┘
```

---

# WF-AST-006 — Riwayat Aset

```text
┌────────────────────────────┐
│ ← Riwayat Aset             │
│                            │
│ Laptop Dell Latitude       │
│ AST-00124                  │
│                            │
│ ● 16 Sep 2026              │
│ │                          │
│ │ Kantor Pusat             │
│ │       ↓                  │
│ │ Cabang Surabaya          │
│ │                          │
│ │ PIC Rina → Rina          │
│ │ ELEKTRONIK-2026-00124    │
│ │                          │
│ ● 03 Feb 2025              │
│ │                          │
│ │ Cabang Palu              │
│ │       ↓                  │
│ │ Kantor Pusat             │
│ │                          │
│ │ PIC Rina → Rina          │
│                            │
└────────────────────────────┘
```

---

# 10. ADMIN WIREFRAMES

# WF-ADM-001 — Dashboard

```text
┌────────────────────────────┐
│ Dashboard Admin        🔔  │
│                            │
│ Master Data                │
│                            │
│ ┌──────────┐ ┌──────────┐ │
│ │ Users    │ │ Lokasi   │ │
│ │   128    │ │    14    │ │
│ └──────────┘ └──────────┘ │
│                            │
│ ┌──────────┐ ┌──────────┐ │
│ │ Kategori │ │ Criteria │ │
│ │     6    │ │     4    │ │
│ └──────────┘ └──────────┘ │
│                            │
│ [ Kelola User ]            │
│ [ Kelola Role ]            │
│ [ Lokasi / Unit ]          │
│ [ Kategori Aset ]          │
│ [ Approval Criteria ]      │
└────────────────────────────┘
```

---

# WF-ADM-002 — User Management

```text
┌────────────────────────────┐
│ ← Users                    │
│                            │
│ ┌────────────────────────┐ │
│ │ 🔍 Cari user            │ │
│ └────────────────────────┘ │
│                            │
│ [ + TAMBAH USER ]          │
│                            │
│ ┌────────────────────────┐ │
│ │ Rina                   │ │
│ │ Pemohon                │ │
│ │ Kantor Pusat           │ │
│ │ Aktif                  │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ Budi                   │ │
│ │ Staff Aset             │ │
│ │ Kantor Pusat           │ │
│ │ Aktif                  │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-ADM-003 — User Form

```text id="7jsu4m"
┌────────────────────────────┐
│ ← Tambah User              │
│                            │
│ Nama *                     │
│ [________________________] │
│                            │
│ Username *                 │
│ [________________________] │
│                            │
│ Role *                     │
│ [ Pilih Role           ▼ ] │
│                            │
│ Unit / Lokasi *            │
│ [ Pilih Unit           ▼ ] │
│                            │
│ Status                     │
│ [ Aktif                ▼ ] │
│                            │
│ Password *                 │
│ [________________________] │
│                            │
│ [       SIMPAN USER       ]│
└────────────────────────────┘
```

---

# WF-ADM-004 — Role Management

```text
┌────────────────────────────┐
│ ← Role                     │
│                            │
│ ┌────────────────────────┐ │
│ │ Pemohon                │ │
│ │ Submit & tracking      │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ Operator               │ │
│ │ Verifikasi             │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ Kabag Aset             │ │
│ │ Approval               │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ Kepala Divisi          │ │
│ │ Conditional Approval   │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ Staff Aset             │ │
│ │ Update Asset           │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ Admin                  │ │
│ │ Master Data            │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-ADM-005 — Location/Unit

```text
┌────────────────────────────┐
│ ← Lokasi / Unit            │
│                            │
│ [ + TAMBAH LOKASI ]        │
│                            │
│ ┌────────────────────────┐ │
│ │ Kantor Pusat           │ │
│ │ Kantor Pusat           │ │
│ │ Aktif                  │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ Cabang Surabaya        │ │
│ │ Cabang                 │ │
│ │ Aktif                  │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-ADM-006 — Location Form

```text
┌────────────────────────────┐
│ ← Tambah Lokasi            │
│                            │
│ Nama Lokasi *              │
│ [________________________] │
│                            │
│ Tipe *                     │
│ [ Pilih Tipe           ▼ ] │
│                            │
│ Alamat                     │
│ [________________________] │
│ [________________________] │
│                            │
│ Status                     │
│ [ Aktif                ▼ ] │
│                            │
│ [     SIMPAN LOKASI      ] │
└────────────────────────────┘
```

---

# WF-ADM-007 — Asset Category

```text
┌────────────────────────────┐
│ ← Kategori Aset            │
│                            │
│ [ + TAMBAH KATEGORI ]      │
│                            │
│ ┌────────────────────────┐ │
│ │ Elektronik             │ │
│ │ Kode: ELEKTRONIK       │ │
│ │ Aktif                  │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ Furniture              │ │
│ │ Kode: FURNITURE        │ │
│ │ Aktif                  │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

---

# WF-ADM-008 — Asset Category Form

```text
┌────────────────────────────┐
│ ← Tambah Kategori          │
│                            │
│ Nama Kategori *            │
│ [________________________] │
│                            │
│ Kode Kategori *            │
│ [________________________] │
│                            │
│ Status                     │
│ [ Aktif                ▼ ] │
│                            │
│ [    SIMPAN KATEGORI     ] │
└────────────────────────────┘
```

---

# WF-ADM-009 — Approval Criteria

```text
┌────────────────────────────┐
│ ← Approval Criteria        │
│                            │
│ Approval Kepala Divisi     │
│                            │
│ Kategori Aset *            │
│ [ Elektronik           ▼ ] │
│                            │
│ Nilai Minimum              │
│ [ Rp __________________ ]  │
│                            │
│ Status                     │
│ [ Aktif                ▼ ] │
│                            │
│ ────────────────────────── │
│                            │
│ Pengajuan yang memenuhi    │
│ kriteria akan membutuhkan  │
│ approval Kepala Divisi.    │
│                            │
│ [    SIMPAN KRITERIA     ] │
└────────────────────────────┘
```

---

# 11. EMPTY STATES

Setiap list screen menggunakan pola:

```text
┌────────────────────────────┐
│                            │
│          [ ICON ]          │
│                            │
│      Belum ada data        │
│                            │
│ Penjelasan singkat         │
│                            │
│      [ ACTION ]            │
│                            │
└────────────────────────────┘
```

Contoh Pemohon:

```text
Belum ada pengajuan.

Mulai dengan membuat
pengajuan mutasi aset.

[ AJUKAN MUTASI ]
```

Untuk screen yang tidak memiliki CTA:

```text
Belum ada pengajuan
yang perlu diproses.
```

---

# 12. LOADING STATES

Jangan menggunakan hanya:

```text
Loading...
```

Gunakan skeleton:

```text
┌────────────────────────────┐
│ ████████████████████       │
│                            │
│ ████████████               │
│ █████████████████          │
│                            │
│ ████████████████████       │
└────────────────────────────┘
```

Struktur skeleton mengikuti struktur konten asli.

---

# 13. ERROR STATES

```text
┌────────────────────────────┐
│                            │
│            !               │
│                            │
│    Data belum tersedia     │
│                            │
│ Coba beberapa saat lagi.   │
│                            │
│       [ COBA LAGI ]        │
│                            │
└────────────────────────────┘
```

---

# 14. OFFLINE STATE

Banner global:

```text
┌────────────────────────────┐
│ ⚠ Offline                  │
│ Tidak ada koneksi internet │
└────────────────────────────┘
```

Pada Pemohon:

```text
┌────────────────────────────┐
│ Menunggu Sinkronisasi      │
│                            │
│ Pengajuan tersimpan lokal. │
│                            │
│ No. tiket akan dibuat      │
│ setelah sinkronisasi.      │
│                            │
│ [ Coba Sinkronisasi ]      │
└────────────────────────────┘
```

---

# 15. CONFIRMATION DIALOG

Untuk action penting:

```text
┌────────────────────────────┐
│ Konfirmasi                 │
│                            │
│ Apakah Anda yakin ingin    │
│ menyetujui pengajuan ini?  │
│                            │
│ [ BATAL ]                  │
│ [ SETUJUI ]                │
└────────────────────────────┘
```

Untuk update:

```text
Konfirmasi Perubahan

Perubahan lokasi dan PIC
akan disimpan ke data aset
dan dicatat dalam riwayat.

[ Batal ] [ Konfirmasi ]
```

---

# 16. INFORMATION HIERARCHY

Untuk Detail Mutasi, hierarchy wajib:

```text
1. STATUS
2. NO. TIKET
3. TIMELINE
4. ASET
5. LOKASI ASAL → TUJUAN
6. PIC ASAL → BARU
7. ALASAN
8. DOKUMEN
9. ACTION
```

Jangan menempatkan detail administratif lebih dominan daripada status dan workflow.

---

# 17. PRIMARY ACTION RULE

Setiap screen hanya memiliki satu primary action.

Contoh:

| Screen | Primary Action |
|---|---|
| Login | Masuk |
| Pilih Aset | Lanjutkan |
| Form Mutasi | Review Pengajuan |
| Review | Ajukan Mutasi |
| Detail Dikembalikan | Edit Pengajuan |
| Verifikasi | Verifikasi Valid |
| Approval | Setujui |
| Update Aset | Simpan Perubahan |
| Konfirmasi | Sesuai |
| User Form | Simpan User |
| Location Form | Simpan Lokasi |
| Category Form | Simpan Kategori |
| Criteria | Simpan Kriteria |

Action seperti **Tolak**, **Kembalikan**, dan **Tidak Sesuai** tidak boleh memiliki visual hierarchy yang lebih kuat daripada action utama tanpa alasan workflow yang jelas.

---

# 18. WORKFLOW WIREFRAME

Full workflow:

```text
LOGIN
  │
  ▼
DASHBOARD PEMOHON
  │
  ▼
PILIH ASET
  │
  ▼
FORM MUTASI
  │
  ▼
REVIEW
  │
  ▼
SUBMIT
  │
  ▼
DIAJUKAN
  │
  ▼
OPERATOR
  │
  ├── Tidak Valid
  │      ↓
  │  DIKEMBALIKAN
  │      ↓
  │  EDIT
  │      ↓
  │  SUBMIT ULANG
  │
  └── Valid
         ↓
   APPROVAL KABAG
         │
         ├── Tolak → DITOLAK
         │
         └── Setujui
                │
                ▼
       Apakah perlu Kadiv?
          │           │
         Ya          Tidak
          │           │
          ▼           │
       KADIV          │
          │           │
     ┌────┴────┐      │
   Tolak      Setuju  │
     │           │     │
     ▼           └─────┘
  DITOLAK
                │
                ▼
       STAFF ASET
                │
                ▼
        UPDATE ASET
                │
                ▼
       RIWAYAT MUTASI
                │
                ▼
     MENUNGGU KONFIRMASI
                │
                ▼
          PEMOHON
                │
        ┌───────┴────────┐
      Sesuai          Tidak Sesuai
        │                 │
        ▼                 ▼
     SELESAI          BUSINESS RULE
                      TBD
```

---

# 19. WIREFRAME DESIGN PRINCIPLES

## Principle 1 — Status First

User harus mengetahui:

> "Pengajuan saya sekarang berada di mana?"

tanpa harus membaca seluruh halaman.

---

## Principle 2 — Action First

Jika user memiliki pekerjaan yang harus dilakukan, action ditempatkan pada area yang mudah ditemukan.

---

## Principle 3 — Detail Bertahap

Informasi tidak ditampilkan sekaligus secara padat.

Gunakan:

```text
Summary
 ↓
Essential Detail
 ↓
Timeline
 ↓
Additional Information
```

---

## Principle 4 — Consistency

Detail mutation untuk:

- Pemohon;
- Operator;
- Kabag;
- Kadiv;
- Staff Aset

menggunakan struktur dasar yang konsisten.

Perbedaan hanya pada:

- data yang boleh dilihat;
- action;
- permission.

---

# 20. WIREFRAME ACCEPTANCE CRITERIA

Wireframe dianggap siap masuk UI Design apabila:

- seluruh screen MVP telah memiliki struktur;
- semua role memiliki navigation;
- workflow submit → verify → approval → update → confirmation dapat ditelusuri;
- setiap screen memiliki primary action;
- status dapat dikenali;
- error/empty/loading/offline telah didefinisikan;
- tidak ada workflow yang terputus;
- permission antar-role jelas;
- Open Questions tidak dipaksakan menjadi keputusan UI.

**Status: READY FOR UI DESIGN**