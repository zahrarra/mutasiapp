# Product Requirements Document (PRD)

# MutasiKu — Aplikasi Pengelolaan Mutasi Aset

**Platform:** Mobile — Flutter  
**Versi:** 1.1 Revision MVP  
**Tanggal:** 27 September 2026

---

## 1. Ringkasan Produk

MutasiKu adalah aplikasi mobile internal untuk mengelola proses perpindahan dan pengembalian aset secara terstruktur, mulai dari pengajuan, verifikasi, persetujuan, serah terima & pembaruan data aset, hingga konfirmasi akhir oleh pemohon.

Aplikasi memastikan setiap perubahan status, perpindahan fisik, serta pengalihan penanggung jawab aset tercatat secara transparan, tertelusuri, dan mutakhir.

---

## 2. Latar Belakang Masalah

Aset kerja (seperti laptop, PC, monitor, printer, dan furnitur) kerap berpindah mengikuti dinamika pegawai (rotasi unit, pindah cabang, atau pengembalian aset karena resign/peremajaan).

Pada proses manual atau pengajuan konvensional, terjadi kendala tata kelola:

- **Ketidaksesuaian Wewenang:** Pemohon sering dipaksa menentukan siapa penerima (PIC baru) dari aset yang mereka lepas, padahal alokasi aset adalah kewenangan pengelola inventaris (Kabag/Staff Aset).
- **Inkonsistensi Data:** Lokasi dan PIC aktual tidak sinkron dengan sistem.
- **Risiko Kehilangan:** Tidak adanya kepastian pencatatan serah terima saat aset dikembalikan ke gudang/pool.

MutasiKu dirancang dengan membedakan secara tegas antara mutasi **bawa sendiri** dan **pelepasan aset ke pool inventaris**.

---

## 3. Tujuan

1. Mencatat alur mutasi aset secara otomatis dan terstruktur sesuai wewenang.
2. Membebaskan Pemohon dari kewajiban menentukan PIC baru jika tidak membawa aset tersebut.
3. Memastikan pemindahan/pelepasan aset melalui tahapan verifikasi Operator dan persetujuan Kabag/Kadiv.
4. Menjaga data lokasi dan penanggung jawab aset di database tetap mutakhir (_single source of truth_).
5. Memberikan tanda bukti serah terima yang sah dengan nomor tiket unik.
6. Mendukung operasional draf pengajuan saat koneksi offline dan sinkronisasi otomatis saat terhubung kembali.

---

## 4. Target Pengguna & Persona

### Pemohon

- Pegawai yang memegang aset dan akan pindah tugas bersama asetnya, ATAU pegawai yang ingin mengembalikan aset ke pool perusahaan (misal: rotasi, peremajaan, pengembalian inventaris).
- **Batasan Kewenangan:** Pemohon **tidak berhak** menentukan/memilih PIC baru dari luar dirinya sendiri.

### Operator

- Staf administrasi logistik yang bertugas memvalidasi kelengkapan dokumen, kesesuaian fisik awal, dan kelayakan alasan mutasi.

### Kabag Aset

- Pejabat struktural yang menyetujui mutasi, memverifikasi kriteria Kadiv, serta berwenang mengelola kuota dan alokasi inventaris antar-unit.

### Kadiv

- Pimpinan unit tingkat divisi yang memberikan persetujuan khusus untuk aset bernilai tinggi, pemindahan antar-wilayah tertentu, atau kriteria strategis lainnya.

### Staff Aset

- Tim operasional lapangan yang menerima penyerahan aset fisik, memverifikasi nomor seri/kondisi, memperbarui master data aset, dan mengelola inventaris di gudang (_pool_).

---

## 5. Role dan Hak Akses

| Role           | Hak Akses Utama                                                                                                                                                     |
| :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Admin**      | Kelola akun pengguna, unit kerja/lokasi, kategori aset, dan kriteria persetujuan Kadiv.                                                                             |
| **Pemohon**    | Mengajukan mutasi (Bawa Sendiri / Lepas ke Pool), melihat status tiket, merevisi pengajuan yang dikembalikan, dan melakukan konfirmasi akhir penyerahan/penerimaan. |
| **Operator**   | Memverifikasi kelengkapan form pengajuan, mengembalikan pengajuan tidak valid dengan catatan, meneruskan ke Kabag.                                                  |
| **Kabag Aset** | Mereview pengajuan valid, menyetujui/menolak, menentukan eskalasi ke Kadiv berdasarkan kriteria.                                                                    |
| **Kadiv**      | Memberikan persetujuan akhir (_approval_) untuk pengajuan berdampak strategis/khusus.                                                                               |
| **Staff Aset** | Menerima serah terima fisik aset, memperbarui data sistem (Lokasi & PIC), menyimpan riwayat, dan memicu tahap konfirmasi pemohon.                                   |

---

## 6. Alur Bisnis & Fitur MVP

### 6.1 Jenis Pengajuan Mutasi (REQ-004)

Pemohon memilih aset miliknya, kemudian memilih salah satu dari **2 Jenis Mutasi**:

1. **Bawa Aset Sendiri (Pindah Unit/Cabang):**
   - **Tujuan:** Pegawai pindah tugas dan tetap bertanggung jawab atas aset tersebut di tempat baru.
   - **Lokasi Tujuan:** Dipilih oleh Pemohon (Unit/Cabang baru).
   - **PIC Baru:** Terkunci otomatis (_read-only_) ke **nama Pemohon sendiri**.
2. **Lepas / Kembalikan ke Pool (Pelepasan Tanggung Jawab):**
   - **Tujuan:** Pegawai tidak lagi menggunakan aset (dikembalikan ke gudang/unit aset).
   - **Lokasi Tujuan:** Default/Terkunci ke **Gudang Aset / Pool Unit Kerja**.
   - **PIC Baru:** Terkunci otomatis (_read-only_) menjadi **Pool Aset (Staff Aset)**. Pemohon dilarang memilih pegawai lain.

Setiap pengajuan yang berhasil dibuat akan memperoleh nomor tiket unik dengan format:  
`[KATEGORI]-[TAHUN]-[NOURUT]` (dibuat oleh server).

### 6.2 Verifikasi Operator

- Memeriksa validitas alasan dan dokumen/foto kondisi aset.
- Jika data tidak lengkap/sesuai, Operator **mengembalikan pengajuan** ke Pemohon dengan catatan perbaikan.
- Jika valid, Operator meneruskan tiket ke Kabag Aset.

### 6.3 Persetujuan Kabag Aset & Kadiv

- **Kabag Aset:** Menyetujui atau menolak tiket pengajuan. Sistem mengecek kriteria eskalasi:
  - Jika memerlukan persetujuan Kadiv $\rightarrow$ Tiket dialihkan ke antrean Kadiv.
  - Jika tidak memerlukan persetujuan Kadiv $\rightarrow$ Tiket dialihkan langsung ke Staff Aset.
- **Kadiv:** Menyetujui atau menolak pengajuan eskalasi.
- Setiap penolakan (_rejection_) wajib menyertakan alasan tertulis.

### 6.4 Eksekusi Fisik & Pembaruan Sistem (Staff Aset)

Setelah seluruh persetujuan terpenuhi:

1. Serah terima fisik terjadi (misal: barang diantar ke gudang atau dipindahkan).
2. Staff Aset memeriksa kondisi barang fisik.
3. Staff Aset membuka tiket di aplikasi (target lokasi dan target PIC bersifat _read-only_ sesuai persetujuan).
4. Staff Aset menekan **Konfirmasi Eksekusi**: sistem memperbarui master data aset (lokasi & PIC) serta mencatat riwayat mutasi (_Mutation History_).
5. Tiket berlanjut ke tahap **Menunggu Konfirmasi Pemohon**.

### 6.5 Konfirmasi Akhir Pemohon & Penanganan Ketidaksesuaian

Pemohon wajib memverifikasi hasil eksekusi:

- **Untuk Bawa Sendiri:** Mengonfirmasi bahwa aset telah sampai di lokasi baru dan tetap ia pegang.
- **Untuk Lepas ke Pool:** Mengonfirmasi bahwa aset fisik telah resmi diserahkan ke pihak logistik/Staff Aset dan ia bebas dari tanggung jawab aset tersebut.
- **Opsi "Sesuai":** Tiket berstatus `Selesai`.
- **Opsi "Tidak Sesuai":** Pemohon mengisi catatan ketidaksesuaian (misal: "Barang belum dijemput", "Aset rusak saat sampai"). Status berpindah ke `Dispute — Dikembalikan ke Staff Aset` agar tim logistik menyelesaikan kendala fisik tanpa Pemohon mengulang pengajuan dari awal.
- **SLA Konfirmasi:** Batas waktu konfirmasi $1 \times 24$ jam kerja. Jika tidak direspons, sistem otomatis mengubah status menjadi `Selesai (Auto-Closed)`.

### 6.6 Operasional Offline & Sinkronisasi (Pemohon)

- Pemohon dapat menyusun draf mutasi tanpa sambungan internet.
- Draf disimpan di SQLite lokal dengan status `Menunggu Sinkronisasi`.
- Saat koneksi online tersedia, aplikasi mengirim draf ke server. Server memverifikasi ketersediaan aset (memastikan aset tidak sedang dikunci oleh proses lain) dan menerbitkan nomor tiket resmi.

---

## 7. Status Siklus Mutasi (State Machine)

1. `Menunggu Sinkronisasi` _(Status lokal khusus offline)_
2. `Diajukan`
3. `Dikembalikan ke Pemohon`
4. `Menunggu Approval Kabag`
5. `Menunggu Approval Kadiv`
6. `Disetujui — Menunggu Tindakan Staff Aset`
7. `Ditolak` _(Status akhir penolakan)_
8. `Menunggu Konfirmasi Pemohon`
9. `Dispute — Dikembalikan ke Staff Aset` _(Jika pemohon memilih 'Tidak Sesuai')_
10. `Selesai`
11. `Selesai (Auto-Closed)`

---

## 8. Aturan Bisnis Inti (Business Rules)

1. **Aturan Hak PIC Baru:** Pemohon dilarang memilih pegawai lain sebagai PIC baru. PIC baru hanya bisa bernilai identitas Pemohon sendiri (_Bawa Sendiri_) atau Pool/Staff Aset (_Lepas Aset_).
2. **Kunci Aset (_Asset Lock_):** Segera setelah pengajuan berstatus `Diajukan`, aset terkunci (`is_locked = true`). Aset yang sedang terkunci tidak dapat diajukan untuk mutasi lain.
3. **Penolakan Final:** Penolakan oleh Kabag atau Kadiv bersifat final dan langsung melepaskan kunci aset (_unlock_).
4. **Prinsip Imutabilitas Rekam Jejak:** Setiap mutasi yang selesai wajib mencatat riwayat permanen (_audit trail_) berisi: Tanggal, Pemohon, PIC Lama, PIC Baru, Lokasi Lama, Lokasi Baru, Petugas Staff Aset, dan Riwayat Approver.
5. **Backend sebagai Single Source of Truth:** Seluruh perubahan status, validasi lock aset, kalkulasi SLA, dan penanganan konflik sinkronisasi diatur oleh backend.
6. **Toleransi Notifikasi:** Kegagalan pengiriman push notification atau email tidak boleh menggagalkan transaksi database status mutasi.

---

## 9. Model Entitas Data

- **User:** `id`, `name`, `email`, `role_id`, `unit_id`
- **Asset:** `id`, `asset_tag`, `name`, `category_id`, `current_pic_id`, `current_location_id`, `is_locked`
- **MutationRequest:** `id`, `ticket_number`, `asset_id`, `requester_id`, `mutation_type` _(BAWA_SENDIRI | LEPAS_POOL)_, `target_location_id`, `target_pic_id`, `reason`, `status`, `created_at`
- **Approval:** `id`, `mutation_request_id`, `approver_id`, `step` _(KABAG | KADIV)_, `action` _(APPROVED | REJECTED)_, `notes`, `action_at`
- **MutationHistory:** `id`, `asset_id`, `ticket_number`, `from_pic_id`, `to_pic_id`, `from_location_id`, `to_location_id`, `executed_by_staff_id`, `completed_at`

---

## 10. Batasan MVP (Non-Goals)

Fitur-fitur berikut secara eksplisit **tidak** disertakan dalam rilis MVP:

- Mutasi hibah/transfer langsung antar-pegawai tanpa melalui gudang/pool.
- Mutasi massal (_bulk transfer_ banyak aset sekaligus dalam satu tiket).
- Alur aset hilang/musnah/penghapusan buku aset.
- Integrasi otomatis dengan sistem ERP pihak ketiga (SAP/Oracle).

---

## 11. Success Metrics

1. **Zero Misallocated Assets:** 100% aset yang dilepas tercatat masuk ke Pool/Gudang tanpa salah penunjukan PIC.
2. **Waktu Siklus Mutasi:** Rata-rata penyelesaian mutasi dari pengajuan hingga selesai $\le 3$ hari kerja.
3. **Penyelesaian Dispute:** Tingkat sanggahan ("Tidak Sesuai") pemohon di bawah 3% dari total mutasi.
4. **Integritas Sinkronisasi Offline:** 0% kehilangan data (_data loss_) pada pengajuan yang dibuat secara offline.
