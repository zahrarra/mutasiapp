# Product Requirements Document (PRD)

# MutasiKu — Aplikasi Pengelolaan Mutasi Aset

**Platform:** Mobile — Flutter
**Versi:** 1.1 Final MVP
**Tanggal:** 28 September 2026
**Menggantikan:** Versi 1.0 (16 September 2026)

---

## 1. Ringkasan Produk

MutasiKu adalah aplikasi mobile internal untuk mengelola proses mutasi aset secara terstruktur, mulai dari pengajuan, pemeriksaan kelengkapan, verifikasi data aset, persetujuan, hingga konfirmasi pemohon dan pembaruan data aset.

Aplikasi ditujukan untuk memastikan setiap perpindahan aset tercatat, dapat ditelusuri, dan memiliki informasi lokasi serta penanggung jawab yang mutakhir.

---

## 2. Latar Belakang Masalah

Aset seperti laptop, PC, printer, dan furniture dapat berpindah mengikuti perpindahan pegawai antar unit atau cabang. Jika proses mutasi dilakukan manual, pencatatan lokasi dan penanggung jawab aset berpotensi tidak sesuai dengan kondisi aktual.

MutasiKu menyediakan alur terstruktur:

**Pengajuan → Pemeriksaan Kelengkapan → Verifikasi Data Aset → Approval Final → Konfirmasi → Pembaruan Data Aset**

---

## 3. Tujuan

1. Mencatat setiap pengajuan mutasi aset melalui proses yang terstruktur.
2. Memastikan setiap pengajuan diperiksa kelengkapannya sebelum diverifikasi oleh Bagian Aset.
3. Memastikan perpindahan aset melalui verifikasi dan persetujuan pimpinan.
4. Menjaga informasi lokasi dan penanggung jawab aset tetap mutakhir.
5. Menyediakan riwayat mutasi yang dapat ditelusuri.
6. Menyediakan nomor tiket unik untuk setiap pengajuan.
7. Mendukung pengajuan saat offline dan sinkronisasi ketika koneksi tersedia.

---

## 4. Target Pengguna

Pengguna internal yang terlibat dalam pengajuan, pemeriksaan kelengkapan, verifikasi, persetujuan, dan pencatatan mutasi aset.

### Persona

**Pemohon**

* Pegawai yang mengalami perpindahan aset.
* Mengajukan mutasi aset yang sedang menjadi tanggung jawabnya.
* Mengonfirmasi hasil mutasi di akhir proses.

**Operator**

* Memeriksa kelengkapan pengajuan dan dokumen.
* Meneruskan pengajuan yang lengkap ke Bagian Aset.
* Mengembalikan pengajuan yang belum lengkap kepada Pemohon.

**Bagian Aset**

* Memverifikasi keabsahan data aset.
* Memverifikasi lokasi tujuan dan dokumen setelah pengajuan dinyatakan lengkap.
* Menentukan PIC baru apabila Pemohon tidak membawa aset itu sendiri.

---

## 5. Role dan Hak Akses

### Admin

* Mengelola user.
* Mengelola role.
* Mengelola lokasi/unit.
* Mengelola kategori aset (Aset TI dan Aset Umum).

### Pemohon

* Mengajukan mutasi aset miliknya.
* Melihat status dan riwayat pengajuan.
* Mengedit dan mengirim ulang pengajuan yang dikembalikan.
* Mengonfirmasi hasil mutasi (Sesuai / Tidak Sesuai).

### Operator

* Menerima tiket baru berstatus `Diajukan`.
* Memeriksa kelengkapan data pengajuan dan dokumen.
* Mengembalikan pengajuan yang tidak lengkap kepada Pemohon dengan alasan.
* Meneruskan pengajuan yang lengkap ke Bagian Aset.
* Tidak melakukan verifikasi keabsahan atau perubahan data aset.

### Bagian Aset

* Menerima pengajuan yang telah dinyatakan lengkap oleh Operator.
* Memverifikasi keabsahan data aset.
* Memverifikasi lokasi tujuan dan SK SDM.
* Mengembalikan pengajuan yang tidak valid dengan alasan.
* Memilih PIC baru bila belum ditentukan Pemohon.
* Meneruskan pengajuan valid ke Pemimpin Divisi.
* Menangani laporan `Tidak Sesuai` dari Pemohon.

### Pemimpin Divisi Umum dan Aset

* Melakukan approval final untuk semua pengajuan yang lolos verifikasi Bagian Aset.
* Menyetujui atau menolak pengajuan dengan alasan.

---

## 6. Fitur MVP

### 6.1 Login dan RBAC

* Login pengguna.
* Role-based access.
* Satu role aktif per user pada MVP.
* Navigasi berdasarkan role.

### 6.2 Pengajuan Mutasi

Pemohon dapat:

* Memilih aset terdaftar yang menjadi tanggung jawabnya.
* Memilih lokasi tujuan dari dropdown.
* Menjawab **"Aset ikut saya pindah?"** (Ya / Tidak).
* Mengisi alasan mutasi.
* Melampirkan **SK SDM (wajib)**.
* Mengirim pengajuan dan melihat nomor tiket serta status.

#### Aturan PIC Baru

* Jawaban **Ya** → PIC baru otomatis Pemohon sendiri.
* Jawaban **Tidak** → PIC baru dikosongkan dan ditentukan Bagian Aset.

Nomor tiket menggunakan format:

`KATEGORI-TAHUN-NOURUT`

Nomor tiket dibuat oleh server. Kode kategori mengikuti master kategori aset.

---

### 6.3 Pemeriksaan Kelengkapan dan Teruskan Tiket — Operator

Operator:

* Melihat tiket berstatus `Diajukan`.
* Memeriksa kelengkapan data pengajuan.
* Memeriksa kelengkapan dokumen wajib, termasuk SK SDM.
* Jika pengajuan tidak lengkap, mengembalikan pengajuan kepada Pemohon dengan alasan.
* Jika pengajuan lengkap, meneruskan pengajuan ke Bagian Aset.
* Tidak melakukan verifikasi keabsahan data aset.

---

### 6.4 Verifikasi Bagian Aset

Setelah pengajuan dinyatakan lengkap oleh Operator, Bagian Aset:

* Memeriksa keabsahan data aset.
* Memeriksa lokasi tujuan.
* Memeriksa kesesuaian dokumen pengajuan.
* Memastikan SK SDM tersedia dan sesuai.
* Memilih PIC baru dari daftar user aktif bila masih kosong.
* Mengembalikan pengajuan yang tidak valid kepada Pemohon dengan alasan.
* Meneruskan pengajuan yang valid ke Pemimpin Divisi.

---

### 6.5 Approval Pemimpin Divisi

Pemimpin Divisi:

* Menerima semua pengajuan yang lolos verifikasi Bagian Aset.
* Tidak menggunakan syarat nilai aset untuk menentukan kebutuhan approval.
* Menyetujui pengajuan, atau
* Menolak pengajuan dengan alasan.
* Melihat ringkasan lengkap:

  * aset,
  * lokasi asal,
  * lokasi tujuan,
  * PIC baru,
  * alasan mutasi,
  * SK SDM.

---

### 6.6 Konfirmasi Pemohon dan Pembaruan Data Aset

Setelah pengajuan disetujui, Pemohon memeriksa kondisi fisik dan hasil mutasi.

#### Sesuai

Jika Pemohon memilih **Sesuai**:

* Server memperbarui lokasi aset.
* Server memperbarui PIC aset.
* Sistem menulis riwayat mutasi.
* Status berubah menjadi `Selesai`.

#### Tidak Sesuai

Jika Pemohon memilih **Tidak Sesuai**:

* Pemohon wajib mengisi alasan.
* Pengajuan kembali ke Bagian Aset untuk ditindaklanjuti.
* Pengajuan kembali mengikuti proses verifikasi dan approval sesuai ketentuan yang berlaku.

Target respons: 1 × 24 jam kerja, disertai pengingat.

Auto-close belum diputuskan dan tetap mengikuti Open Questions.

---

### 6.7 Notifikasi

Sistem menyediakan notifikasi untuk:

* Perubahan status.
* Pengajuan yang perlu ditindaklanjuti.
* Pengajuan yang dikembalikan.
* Approval.
* Konfirmasi Pemohon.

Kegagalan notifikasi tidak boleh menggagalkan perubahan status.

---

### 6.8 Riwayat Mutasi

Sistem menyimpan:

* Riwayat perubahan status.
* Riwayat proses mutasi.
* Riwayat perubahan lokasi aset.
* Riwayat perubahan PIC aset.

---

### 6.9 Offline dan Sinkronisasi

Pemohon dapat menyimpan pengajuan secara lokal ketika offline.

Status lokal:

`Menunggu Sinkronisasi`

Nomor tiket dibuat setelah berhasil melakukan sinkronisasi dengan server.

Konflik sinkronisasi harus ditangani secara eksplisit dan tidak boleh melakukan overwrite secara diam-diam.

---

## 7. Status Mutasi

### Status bisnis

1. `Diajukan`
   * Pengajuan baru dan menunggu pemeriksaan kelengkapan oleh Operator.

2. `Menunggu Verifikasi Bagian Aset`ss
   * Pengajuan telah dinyatakan lengkap oleh Operator dan sedang diverifikasi oleh Bagian Aset.

3. `Dikembalikan ke Pemohon`

   * Pengajuan dikembalikan karena tidak lengkap atau tidak valid dan harus diperbaiki oleh Pemohon.

4. `Menunggu Approval Pemimpin Divisi`

   * Pengajuan telah lolos verifikasi Bagian Aset dan menunggu keputusan Pemimpin Divisi.

5. `Ditolak`

   * Pengajuan ditolak oleh Pemimpin Divisi.

6. `Menunggu Konfirmasi Pemohon`

   * Pengajuan telah disetujui dan menunggu konfirmasi Pemohon.

7. `Selesai`

   * Pemohon telah memilih `Sesuai` dan pembaruan data aset berhasil dilakukan.

### Status lokal

8. `Menunggu Sinkronisasi`

   * Status sinkronisasi lokal.
   * Bukan pengganti status bisnis dari server.

---

## 8. Aturan Bisnis

1. Satu user hanya memiliki satu role aktif pada MVP.

2. Hanya pemegang aset saat ini yang dapat mengajukan mutasi.

3. Aset yang dimutasi harus merupakan aset terdaftar. Input aset bebas/manual tidak didukung.

4. Satu aset tidak boleh memiliki lebih dari satu mutasi aktif.

5. Sejak pengajuan dibuat sampai `Selesai` atau `Ditolak`, aset berstatus `Dalam Proses Mutasi`/terkunci.

6. Lokasi tujuan dan PIC dipilih dari dropdown yang terikat data master, bukan teks bebas.

7. SK SDM wajib dilampirkan pada setiap pengajuan. Pengajuan tanpa SK SDM tidak dapat dikirim.

8. Pemohon hanya mengisi PIC baru dengan dirinya sendiri jika membawa aset. Jika tidak membawa aset, PIC baru ditentukan oleh Bagian Aset.

9. Setiap pengajuan baru wajib melalui pemeriksaan kelengkapan oleh Operator.

10. Pengajuan yang tidak lengkap pada pemeriksaan Operator harus dikembalikan kepada Pemohon dengan alasan.

11. Pengajuan yang telah lengkap diteruskan oleh Operator ke Bagian Aset untuk verifikasi.

12. Bagian Aset melakukan verifikasi keabsahan data aset, lokasi tujuan, dan dokumen pengajuan.

13. Pengajuan yang tidak valid pada verifikasi Bagian Aset harus dikembalikan kepada Pemohon dengan alasan.

14. Pengajuan yang dikembalikan, setelah diperbaiki dan dikirim ulang, kembali masuk ke proses yang ditentukan pada Open Questions.

15. Semua pengajuan yang lolos verifikasi Bagian Aset wajib melewati Pemimpin Divisi, tanpa syarat nilai aset.

16. Penolakan oleh Pemimpin Divisi harus memiliki alasan.

17. Data master aset berupa lokasi dan PIC hanya berubah setelah Pemohon memilih `Sesuai`.

18. Perubahan lokasi dan PIC harus menghasilkan riwayat mutasi.

19. Nomor tiket dibuat oleh server.

20. Status, approval, ticket, SLA, asset lock, history, dan konflik merupakan sumber kebenaran dari backend.

21. Kegagalan penyimpanan pembaruan aset tidak boleh menghasilkan status sukses palsu. Seluruh perubahan terkait harus dibatalkan/rollback.

22. Kegagalan notifikasi tidak boleh membatalkan perubahan status.

23. Konflik offline harus ditangani secara eksplisit. Server menjadi sumber kebenaran.

### Aturan Data Aset

24. Kategori aset hanya `Aset TI` dan `Aset Umum`.

25. Kondisi aset hanya `Baik`, `Rusak`, atau `Butuh Maintenance`.

26. Serial Number unik; satu barang fisik satu baris inventaris.

27. Tahun pembelian dan tahun penggunaan adalah dua field terpisah.

28. Aset tidak dihapus permanen; gunakan soft delete dengan status aktif/nonaktif.

29. Penghapusan (disposal) aset membutuhkan persetujuan Pemimpin Divisi. Alur disposal di luar scope MVP dan dicatat untuk fase berikutnya.

---

## 9. Data Utama

Entitas utama:

* User
* Role
* Location / Unit
* AssetCategory
* Asset
* MutationRequest
* Approval
* MutationHistory
* Notification
* Document (termasuk SK SDM)

---

## 10. Non-Goals MVP

Hal berikut tidak termasuk scope MVP:

* Mutasi aset karena kerusakan/kehilangan.
* Mutasi massal.
* Mutasi oleh pihak yang bukan pemegang aset saat ini.
* Partial bundle mutation.
* Integrasi ERP eksternal.
* Alur disposal aset.
* Konfirmasi penerimaan oleh PIC baru selain Pemohon.
* Pengajuan mutasi oleh role Operator.

---

## 11. Edge Cases

* Pengajuan mutasi aktif ganda untuk aset yang sama harus ditolak.
* Aset tidak ditemukan atau tidak terdaftar.
* SK SDM tidak dilampirkan.
* Data atau dokumen pengajuan tidak lengkap → dikembalikan oleh Operator kepada Pemohon.
* Data aset atau tujuan tidak valid → dikembalikan oleh Bagian Aset kepada Pemohon.
* Pengajuan dikembalikan dan dapat diedit/resubmit.
* Pengajuan ditolak secara final.
* Approval terlambat.
* User tidak memiliki permission.
* Lokasi tujuan tidak valid.
* PIC tujuan tidak aktif.
* Bagian Aset meneruskan pengajuan tanpa mengisi PIC baru ketika PIC memang diperlukan → ditolak sistem.
* Penyimpanan pembaruan aset gagal → rollback.
* Notifikasi gagal → status tetap dapat berubah.
* Pengajuan offline menunggu sinkronisasi.
* Konflik ketika aset telah dimutasi melalui proses lain.
* Pemohon tidak merespons konfirmasi.

---

## 12. Success Metrics

* Persentase mutasi yang diproses melalui sistem.
* Akurasi lokasi dan PIC aset.
* Waktu penyelesaian mutasi.
* Persentase pengajuan yang dikembalikan.
* Persentase konfirmasi `Tidak Sesuai`.
* Penggunaan riwayat mutasi.

Target numerik belum ditentukan.

---

## 13. Open Questions

Hal berikut belum boleh diasumsikan oleh developer:

1. Perilaku setelah `Tidak Sesuai`. Sementara: kembali ke `Menunggu Verifikasi Bagian Aset` dengan catatan, lalu melewati Pemimpin Divisi lagi. Perlu dikonfirmasi.

2. Aturan auto-close konfirmasi Pemohon. Sementara: hanya pengingat.

3. Setelah pengajuan `Dikembalikan ke Pemohon` diperbaiki dan dikirim ulang, apakah pengajuan:

   * kembali ke Operator untuk pemeriksaan kelengkapan, atau
   * langsung ke Bagian Aset.

   **Sementara: belum ditetapkan.**

4. Apakah Operator dan Bagian Aset dijabat orang berbeda secara organisasi. Sementara: ya, role terpisah.

5. Kalender hari kerja dan hari libur.

6. Backend dan database final.

7. Metode autentikasi final.

8. SLA pemeriksaan Operator, verifikasi Bagian Aset, dan approval Pemimpin Divisi.

9. Scope offline untuk role selain Pemohon.

10. Target numerik success metrics.

11. Singkatan kode kategori pada nomor tiket (`Aset TI` / `Aset Umum`).

12. Skenario tambahan yang akan dikecualikan dari MVP.

---

## 14. Prinsip Implementasi

* Jangan mengarang business rule yang belum ditentukan.
* Backend menjadi sumber kebenaran untuk data dan workflow.
* UI tidak boleh mengubah status secara langsung.
* Gunakan repository/use case untuk proses bisnis.
* Gunakan komponen UI yang konsisten.
* Jangan hardcode design token berulang.
* Perubahan kode dilakukan secara bertahap dan teruji.
* Tanggung jawab Operator dan Bagian Aset harus tetap dipisahkan.
* Operator bertanggung jawab terhadap **kelengkapan pengajuan**.
* Bagian Aset bertanggung jawab terhadap **verifikasi data aset dan validitas mutasi**.
* Jangan menggabungkan pemeriksaan kelengkapan Operator dengan verifikasi Bagian Aset.
