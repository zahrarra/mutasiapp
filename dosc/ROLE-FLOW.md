# ROLE FLOW
# MutasiKu — Alur Pengguna Berdasarkan Role

**Versi:** 1.0 Draft MVP  
**Tanggal:** 16 September 2026

---

## 1. Alur Utama

```text
Login
   ↓
Pemohon membuat pengajuan mutasi
   ↓
Sistem generate No. Tiket
Status: Diajukan
   ↓
Operator verifikasi data & kelengkapan
   ↓
Data Valid?
   ├── Tidak → Kembalikan ke Pemohon
   │              ↓
   │           Edit / Resubmit
   │              ↓
   │           Operator Verifikasi
   │
   └── Ya
       ↓
Kabag Aset Review & Approval
       ↓
Disetujui?
   ├── Tidak → Notifikasi Penolakan
   │              ↓
   │           Selesai
   │
   └── Ya
       ↓
   Perlu Approval Kadiv?
       ├── Ya → Kadiv Approval
       │          ↓
       │       Disetujui?
       │          ├── Tidak → Ditolak → Selesai
       │          └── Ya
       │
       └── Tidak
              ↓
   Disetujui — Menunggu Update Aset
              ↓
       Staff Aset Update
       Lokasi + PIC
              ↓
       Simpan Riwayat Mutasi
              ↓
       Menunggu Konfirmasi Pemohon
              ↓
       Pemohon Konfirmasi
              ↓
       Selesai
```

---

# 2. Admin Flow

```text
Login
  ↓
Admin Dashboard
  ↓
Pilih Master Data
  ├── User
  ├── Role
  ├── Lokasi / Unit
  ├── Kategori Aset
  └── Kriteria Approval
```

### Admin dapat

- Mengelola user.
- Mengelola role.
- Mengelola lokasi/unit.
- Mengelola kategori aset.
- Mengatur kriteria approval Kadiv.

### Admin tidak melakukan

- Verifikasi pengajuan mutasi.
- Approval Kabag.
- Approval Kadiv.
- Update mutasi aset sebagai Staff Aset.

---

# 3. Pemohon Flow

```text
Login
  ↓
Dashboard Pemohon
  ↓
Ajukan Mutasi
  ↓
Pilih Aset
  ↓
Isi Form Mutasi
  ↓
Submit
  ↓
Sistem memproses pengajuan
  ↓
No. Tiket dibuat oleh server
  ↓
Status: Diajukan
  ↓
Menunggu Verifikasi Operator
```

### Jika dikembalikan

```text
Notifikasi
  ↓
Detail Pengajuan
  ↓
Lihat alasan pengembalian
  ↓
Edit Pengajuan
  ↓
Resubmit
  ↓
Verifikasi Operator
```

### Jika menunggu konfirmasi

```text
Notifikasi
  ↓
Detail Mutasi
  ↓
Lihat hasil update aset
  ↓
Konfirmasi
  ↓
Selesai
```

### Jika offline

```text
Isi Pengajuan
  ↓
Tidak ada koneksi
  ↓
Simpan Lokal
  ↓
Menunggu Sinkronisasi
  ↓
Koneksi tersedia
  ↓
Sync ke Server
  ↓
Server membuat No. Tiket
```

Konflik sinkronisasi harus ditangani secara eksplisit dan server menjadi sumber kebenaran.

---

# 4. Operator Flow

```text
Login
  ↓
Dashboard Operator
  ↓
Pengajuan Masuk
  ↓
Pilih Pengajuan
  ↓
Detail Pengajuan
  ↓
Verifikasi Data & Kelengkapan
```

### Jika tidak valid

```text
Data Tidak Valid
  ↓
Masukkan Alasan
  ↓
Kembalikan ke Pemohon
  ↓
Notifikasi Pemohon
```

### Jika valid

```text
Data Valid
  ↓
Verifikasi
  ↓
Status: Menunggu Approval Kabag
  ↓
Notifikasi Kabag Aset
```

---

# 5. Kabag Aset Flow

```text
Login
  ↓
Dashboard Kabag Aset
  ↓
Menunggu Approval
  ↓
Detail Pengajuan
  ↓
Review
```

### Jika ditolak

```text
Reject
  ↓
Masukkan Alasan
  ↓
Status: Ditolak
  ↓
Notifikasi Pemohon
  ↓
Selesai
```

### Jika disetujui

```text
Approve
  ↓
Evaluasi Kriteria Approval Kadiv
```

Jika memenuhi kriteria:

```text
Status: Menunggu Approval Kadiv
  ↓
Notifikasi Kadiv
```

Jika tidak memenuhi kriteria:

```text
Status: Disetujui — Menunggu Update Aset
  ↓
Notifikasi Staff Aset
```

---

# 6. Kadiv Flow

Kadiv hanya menerima pengajuan yang memenuhi kriteria approval Kadiv.

```text
Login
  ↓
Dashboard Kadiv
  ↓
Menunggu Approval
  ↓
Detail Pengajuan
  ↓
Review
```

### Jika ditolak

```text
Reject
  ↓
Masukkan Alasan
  ↓
Status: Ditolak
  ↓
Notifikasi Pemohon
```

### Jika disetujui

```text
Approve
  ↓
Status: Disetujui — Menunggu Update Aset
  ↓
Notifikasi Staff Aset
```

---

# 7. Staff Aset Flow

```text
Login
  ↓
Dashboard Staff Aset
  ↓
Menunggu Update
  ↓
Pilih Pengajuan
  ↓
Detail Mutasi
  ↓
Update Data Aset
```

Staff Aset memperbarui:

- Lokasi aset.
- PIC / penanggung jawab.

Kemudian:

```text
Simpan
  ↓
Simpan Mutation History
  ↓
Status: Menunggu Konfirmasi Pemohon
  ↓
Notifikasi Pemohon
```

Jika penyimpanan gagal:

```text
Save gagal
  ↓
Rollback
  ↓
Tampilkan Error
```

Sistem tidak boleh menampilkan status sukses palsu.

---

# 8. System Flow

Sistem bertanggung jawab terhadap:

### Ticket

```text
Pengajuan berhasil diterima server
        ↓
Generate nomor tiket
        ↓
KATEGORI-TAHUN-NOURUT
```

### Status

Sistem menjaga transisi status berdasarkan workflow.

UI tidak boleh mengubah status bisnis secara langsung.

### Notification

```text
Status berubah
  ↓
Buat Notifikasi
  ↓
Kirim ke role/user terkait
```

Jika notifikasi gagal, perubahan status tetap dipertahankan.

### SLA Konfirmasi

```text
Staff Aset selesai update
  ↓
Menunggu Konfirmasi Pemohon
  ↓
Batas 1 × 24 jam kerja
  ↓
Pemohon konfirmasi
```

Aturan auto-close masih merupakan open question dan belum boleh dikunci tanpa keputusan bisnis.

---

# 9. Ringkasan Hak Akses

| Role | Submit | Verifikasi | Approval Kabag | Approval Kadiv | Update Aset | Konfirmasi | Master Data |
|---|---:|---:|---:|---:|---:|---:|---:|
| Admin | - | - | - | - | - | - | ✓ |
| Pemohon | ✓ | - | - | - | - | ✓ | - |
| Operator | - | ✓ | - | - | - | - | - |
| Kabag Aset | - | - | ✓ | - | - | - | - |
| Kadiv | - | - | - | ✓ | - | - | - |
| Staff Aset | - | - | - | - | ✓ | - | - |

---

# 10. Route / Screen Direction

## Pemohon

```text
/login
/pemohon/dashboard
/pemohon/mutasi
/pemohon/mutasi/create
/pemohon/mutasi/:id
/pemohon/mutasi/:id/edit
/pemohon/mutasi/:id/confirm
/pemohon/notifications
```

## Operator

```text
/operator/dashboard
/operator/mutations
/operator/mutations/:id
/operator/mutations/:id/verify
/operator/verification-history
```

## Kabag Aset

```text
/kabag/dashboard
/kabag/approvals
/kabag/approvals/:id
/kabag/approvals/:id/review
/kabag/approval-history
```

## Kadiv

```text
/kadiv/dashboard
/kadiv/approvals
/kadiv/approvals/:id
/kadiv/approvals/:id/review
/kadiv/approval-history
```

## Staff Aset

```text
/staff-aset/dashboard
/staff-aset/mutations
/staff-aset/mutations/:id
/staff-aset/mutations/:id/update
/staff-aset/assets/:id/history
```

## Admin

```text
/admin/dashboard
/admin/users
/admin/roles
/admin/locations
/admin/asset-categories
/admin/approval-criteria
```

---

# 11. Prinsip Role Flow

1. Role menentukan akses terhadap fitur.
2. Permission UI bukan pengganti security backend.
3. User hanya dapat melihat tindakan yang sesuai dengan role/permission.
4. Status tidak boleh dimanipulasi langsung dari UI.
5. Setiap perpindahan status mengikuti workflow.
6. Approval yang tidak diperlukan tidak boleh ditampilkan sebagai langkah wajib.
7. Kriteria approval Kadiv berasal dari konfigurasi bisnis, bukan hardcode UI.
8. Server menjadi sumber kebenaran untuk status, ticket, approval, asset lock, history, SLA, dan conflict.
