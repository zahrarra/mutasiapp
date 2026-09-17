# Product Requirements Document (PRD)
# MutasiKu — Aplikasi Pengelolaan Mutasi Aset

**Platform:** Mobile — Flutter  
**Versi:** 1.0 Draft MVP  
**Tanggal:** 16 September 2026

---

## 1. Ringkasan Produk

MutasiKu adalah aplikasi mobile internal untuk mengelola proses mutasi aset secara terstruktur, mulai dari pengajuan, verifikasi, persetujuan, pembaruan data aset, hingga konfirmasi pemohon.

Aplikasi ditujukan untuk membantu memastikan setiap perpindahan aset tercatat, dapat ditelusuri, dan memiliki informasi lokasi serta penanggung jawab yang mutakhir.

---

## 2. Latar Belakang Masalah

Aset seperti laptop, PC, printer, dan furniture dapat berpindah mengikuti perpindahan pegawai antar unit atau cabang. Jika proses mutasi masih dilakukan secara manual, pencatatan lokasi dan penanggung jawab aset berpotensi tidak selalu sesuai dengan kondisi aktual.

MutasiKu dirancang untuk menyediakan alur terstruktur:

Pengajuan → Verifikasi → Approval → Update Aset → Konfirmasi.

---

## 3. Tujuan

1. Mencatat setiap pengajuan mutasi aset melalui proses yang terstruktur.
2. Memastikan perpindahan aset melalui tahapan verifikasi dan persetujuan.
3. Menjaga informasi lokasi dan penanggung jawab aset tetap mutakhir.
4. Menyediakan riwayat mutasi yang dapat ditelusuri.
5. Menyediakan nomor tiket unik untuk setiap pengajuan.
6. Mendukung pengajuan saat offline dan sinkronisasi ketika koneksi tersedia.

---

## 4. Target Pengguna

Pengguna internal yang terlibat dalam proses pengajuan, verifikasi, persetujuan, dan pencatatan mutasi aset.

### Persona

**Pemohon**
- Pegawai yang mengalami perpindahan aset.
- Mengajukan mutasi aset yang sedang menjadi tanggung jawabnya.

**Staff Aset**
- Memperbarui lokasi dan penanggung jawab aset.
- Memastikan riwayat mutasi tercatat.

---

## 5. Role dan Hak Akses

### Admin
- Mengelola user.
- Mengelola role.
- Mengelola lokasi/unit.
- Mengelola kategori aset.
- Mengelola kriteria approval Kadiv.

### Pemohon
- Membuat pengajuan mutasi.
- Melihat status pengajuan.
- Mengedit pengajuan yang dikembalikan.
- Melakukan konfirmasi mutasi.

### Operator
- Memeriksa pengajuan.
- Memverifikasi data dan kelengkapan.
- Mengembalikan pengajuan jika tidak valid.

### Kabag Aset
- Mereview pengajuan.
- Menyetujui atau menolak pengajuan.
- Menentukan apakah pengajuan membutuhkan approval Kadiv berdasarkan kriteria yang berlaku.

### Kadiv
- Memberikan approval atau penolakan untuk pengajuan yang memenuhi kriteria approval Kadiv.

### Staff Aset
- Memperbarui lokasi aset.
- Memperbarui penanggung jawab aset.
- Menyimpan riwayat mutasi.

---

## 6. Fitur MVP

### 6.1 Login dan RBAC
- Login pengguna.
- Role-based access.
- Satu role aktif per user pada MVP.
- Navigasi berdasarkan role.

### 6.2 Pengajuan Mutasi
Pemohon dapat:
- Memilih aset.
- Mengisi data mutasi.
- Mengirim pengajuan.
- Melihat nomor tiket dan status.

Nomor tiket menggunakan format:

`KATEGORI-TAHUN-NOURUT`

Nomor tiket dibuat oleh server.

### 6.3 Verifikasi Operator
Operator:
- Memeriksa data.
- Memeriksa kelengkapan.
- Mengembalikan pengajuan jika tidak valid dengan alasan.
- Meneruskan pengajuan valid ke Kabag Aset.

### 6.4 Approval Kabag Aset
Kabag Aset dapat:
- Menyetujui.
- Menolak dengan alasan.
- Meneruskan ke Kadiv jika memenuhi kriteria.
- Meneruskan ke Staff Aset jika tidak membutuhkan approval Kadiv.

### 6.5 Approval Kadiv
Kadiv hanya terlibat apabila kriteria approval terpenuhi.

Kadiv dapat:
- Menyetujui.
- Menolak dengan alasan.

### 6.6 Update Data Aset
Staff Aset:
- Memperbarui lokasi aset.
- Memperbarui PIC/penanggung jawab.
- Menyimpan riwayat mutasi.
- Mengubah proses ke tahap konfirmasi pemohon.

### 6.7 Konfirmasi Pemohon
Pemohon melakukan konfirmasi setelah data aset diperbarui.

Batas konfirmasi:
- 1 × 24 jam kerja.
- Jika tidak ada respons, sistem dapat melakukan auto-close menjadi `Selesai (Auto)` sesuai aturan yang masih perlu ditetapkan.

### 6.8 Notifikasi
Sistem menyediakan notifikasi perubahan status dan tindakan yang diperlukan.

Kegagalan notifikasi tidak boleh menggagalkan perubahan status.

### 6.9 Riwayat Mutasi
Sistem menyimpan riwayat perubahan dan proses mutasi aset.

### 6.10 Offline dan Sinkronisasi
Pemohon dapat menyimpan pengajuan secara lokal ketika offline.

Status lokal:
`Menunggu Sinkronisasi`

Nomor tiket dibuat setelah berhasil sinkronisasi dengan server.

Konflik sinkronisasi harus ditangani dan tidak boleh melakukan overwrite secara diam-diam.

---

## 7. Status Mutasi

Status utama:

1. `Diajukan`
2. `Dikembalikan ke Pemohon`
3. `Menunggu Approval Kabag`
4. `Menunggu Approval Kadiv`
5. `Disetujui — Menunggu Update Aset`
6. `Ditolak`
7. `Menunggu Konfirmasi Pemohon`
8. `Selesai`
9. `Menunggu Sinkronisasi` — status sinkronisasi lokal, bukan pengganti status bisnis server.

---

## 8. Aturan Bisnis

1. Satu user hanya memiliki satu role aktif pada MVP.
2. Hanya pemegang aset saat ini yang dapat mengajukan mutasi.
3. Satu aset tidak boleh memiliki lebih dari satu mutasi aktif.
4. Setelah pengajuan dibuat, aset berada dalam kondisi `Dalam Proses Mutasi`/terkunci.
5. Pengajuan tidak valid harus dikembalikan dengan alasan.
6. Pengajuan valid diteruskan ke approval Kabag.
7. Penolakan harus memiliki alasan.
8. Approval Kadiv hanya dilakukan jika kriteria terpenuhi.
9. Staff Aset hanya memperbarui data aset setelah seluruh approval yang diperlukan selesai.
10. Perubahan lokasi dan PIC harus menghasilkan riwayat mutasi.
11. Nomor tiket dibuat oleh server.
12. Status, approval, ticket, SLA, asset lock, history, dan konflik merupakan sumber kebenaran dari backend.
13. Kriteria approval yang diubah Admin hanya berlaku untuk pengajuan baru.
14. Kegagalan penyimpanan update aset tidak boleh menghasilkan status sukses palsu.
15. Kegagalan notifikasi tidak boleh membatalkan perubahan status.
16. Konflik offline harus ditangani secara eksplisit; server menjadi sumber kebenaran.

---

## 9. Data Utama

Entitas utama:

- User
- Role
- Location / Unit
- AssetCategory
- Asset
- MutationRequest
- Approval
- MutationHistory
- Notification
- Document

---

## 10. Non-Goals MVP

Hal berikut tidak termasuk scope MVP:

- Mutasi aset karena kerusakan/kehilangan.
- Mutasi massal.
- Mutasi oleh pihak yang bukan pemegang aset saat ini.
- Partial bundle mutation.
- Integrasi ERP eksternal.

---

## 11. Edge Cases

- Pengajuan mutasi aktif ganda untuk aset yang sama harus ditolak.
- Aset tidak ditemukan.
- Data pengajuan tidak lengkap.
- Pengajuan dikembalikan dan dapat diedit/resubmit.
- Pengajuan ditolak secara final.
- Approval terlambat.
- User tidak memiliki permission.
- Lokasi tujuan tidak valid.
- PIC tujuan tidak aktif.
- Penyimpanan update aset gagal → rollback.
- Notifikasi gagal → status tetap dapat berubah.
- Pengajuan offline menunggu sinkronisasi.
- Konflik ketika aset telah dimutasi melalui proses lain.

---

## 12. Success Metrics

Metrik yang akan digunakan antara lain:

- Persentase mutasi yang diproses melalui sistem.
- Akurasi lokasi dan PIC aset.
- Waktu penyelesaian mutasi.
- Persentase pengajuan yang dikembalikan.
- Penggunaan riwayat mutasi.
- Keberhasilan penyelesaian pengajuan.

Target numerik belum ditentukan.

---

## 13. Open Questions

Hal berikut belum boleh diasumsikan oleh developer:

1. Kriteria pasti approval Kadiv.
2. Aturan auto-close.
3. Alur `Tidak Sesuai` pada konfirmasi.
4. Kalender hari kerja dan hari libur.
5. Backend dan database final.
6. Metode autentikasi final.
7. Ketentuan dokumen wajib/opsional.
8. SLA approval.
9. Scope offline untuk role selain Pemohon.
10. Target numerik success metrics.
11. Kategori aset awal.
12. Skenario tambahan yang akan dikecualikan dari MVP.

---

## 14. Prinsip Implementasi

- Jangan mengarang business rule yang belum ditentukan.
- Backend menjadi sumber kebenaran untuk data dan workflow.
- UI tidak boleh mengubah status secara langsung.
- Gunakan repository/use case untuk proses bisnis.
- Gunakan komponen UI yang konsisten.
- Jangan hardcode design token berulang.
- Perubahan kode dilakukan secara bertahap dan teruji.
