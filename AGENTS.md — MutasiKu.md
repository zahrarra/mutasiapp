# AGENTS.md — MutasiKu

## 1. Project Identity

**Project:** MutasiKu  
**Platform:** Mobile  
**Framework:** Flutter  
**Architecture:** Feature-First + Clean Architecture ringan  
**State Management:** Riverpod  
**Routing:** go_router  
**Local Database:** Drift  
**Purpose:** Aplikasi pengelolaan dan pelacakan mutasi aset internal.

MutasiKu digunakan untuk mengelola proses:

```text
Pemohon
   ↓
Operator
   ↓
Kabag Aset
   ↓
Kadiv (opsional)
   ↓
Staff Aset
   ↓
Pemohon
```

---

# 2. Mandatory Documentation

Sebelum melakukan perubahan kode, agent WAJIB membaca:

```text
docs/PRD.md
docs/ROLE-FLOW.md
docs/SCREEN-SPEC.md
docs/DESIGN.md
docs/TECHNICAL-DESIGN.md
docs/PROJECT-SETUP.md
AGENTS.md
SKILLS.md
```

Jika salah satu file belum tersedia, jangan mengarang isi dokumen tersebut.

---

# 3. Documentation Priority

Jika terdapat konflik requirement, gunakan urutan:

```text
Business Decision
      ↓
PRD
      ↓
ROLE-FLOW
      ↓
SCREEN-SPEC
      ↓
DESIGN
      ↓
TECHNICAL-DESIGN
      ↓
PROJECT-SETUP
      ↓
Implementation
```

Dokumen yang lebih tinggi memiliki prioritas lebih tinggi.

---

# 4. Core Rule

## DO NOT INVENT BUSINESS RULES.

Jika requirement belum ditentukan:

```text
DO NOT GUESS.
DO NOT ASSUME.
DO NOT IMPLEMENT AS FINAL.
```

Tandai sebagai:

```text
OPEN QUESTION
```

Contoh:

- kriteria approval Kadiv belum final;
- aturan dokumen pendukung belum final;
- SLA approval belum final;
- aturan hari libur belum final.

---

# 5. Inspect Before Modify

Sebelum mengubah kode:

```text
1. Inspect project structure.
2. Inspect relevant files.
3. Identify existing implementation.
4. Identify dependencies.
5. Identify possible impact.
6. Make the smallest required change.
```

Jangan langsung mengganti architecture hanya karena memiliki preferensi pribadi.

---

# 6. Preserve Existing Work

Agent dilarang:

- menghapus feature tanpa alasan;
- mengganti architecture secara keseluruhan;
- mengganti dependency utama tanpa kebutuhan;
- melakukan refactor besar tanpa persetujuan;
- menghapus migration/data;
- menghapus konfigurasi;
- menghapus test;
- mengganti design system.

Jika refactor besar memang diperlukan, jelaskan:

```text
WHY
WHAT WILL CHANGE
RISK
ALTERNATIVE
```

sebelum melakukannya.

---

# 7. Architecture Rules

Gunakan:

```text
Presentation
    ↓
Domain
    ↓
Data
```

UI tidak boleh langsung mengakses API.

Tidak diperbolehkan:

```text
Screen
   ↓
HTTP Client
```

Yang benar:

```text
Screen
 ↓
Provider / Controller
 ↓
Use Case
 ↓
Repository
 ↓
Data Source
```

---

# 8. Business Logic

Business logic harus berada di:

```text
Domain / Use Case
```

atau abstraction yang sesuai.

Jangan menaruh workflow penting di widget.

Tidak diperbolehkan:

```dart
onPressed: () {
  if (...) {
    status = ...;
  }
}
```

jika perubahan tersebut merupakan business rule.

---

# 9. Backend Source of Truth

Backend merupakan authoritative source untuk:

```text
User authorization
Mutation status
Ticket number
Approval
Asset lock
SLA
Mutation history
Conflict
```

Flutter hanya melakukan validation dan state handling untuk kebutuhan UX.

---

# 10. Role

Role MVP:

```text
admin
pemohon
operator
kabagAset
kadiv
staffAset
```

Jangan membuat role tambahan tanpa business requirement.

Admin dan Operator adalah role berbeda.

Admin:

```text
Master Data
```

Operator:

```text
Mutation Verification
```

Admin tidak otomatis menjadi approver.

---

# 11. Mutation Workflow

Workflow utama:

```text
Diajukan
   ↓
Operator Verification
   ↓
Menunggu Approval Kabag
   ↓
Kabag Approval
   ↓
Kadiv Approval (opsional)
   ↓
Staff Aset Update
   ↓
Menunggu Konfirmasi Pemohon
   ↓
Selesai
```

Alternative:

```text
Operator invalid
→ Dikembalikan ke Pemohon
```

```text
Kabag/Kadiv reject
→ Ditolak
```

Status tidak boleh dibuat atau diubah sembarangan.

---

# 12. Mutation Status

Gunakan centralized status enum.

```text
diajukan
dikembalikanKePemohon
menungguApprovalKabag
menungguApprovalKadiv
disetujuiMenungguUpdateAset
ditolak
menungguKonfirmasiPemohon
selesai
menungguSinkronisasi
```

Jangan menggunakan string status tersebar di seluruh project.

---

# 13. Ticket Number

Format:

```text
KATEGORI-TAHUN-NOURUT
```

Contoh:

```text
LAPTOP-2026-0001
```

Ticket final dibuat server.

Flutter tidak boleh menentukan nomor ticket final.

Offline:

```text
Save Local
 ↓
Sync
 ↓
Server generates ticket
```

---

# 14. Offline

Offline MVP terutama untuk Pemohon.

Offline submission:

```text
Form
 ↓
Local Database
 ↓
Menunggu Sinkronisasi
 ↓
Connection Available
 ↓
Sync
 ↓
Server
```

Jangan menganggap local data sebagai source of truth.

Jika conflict:

```text
Server wins.
```

Jangan melakukan silent overwrite.

---

# 15. Asset Lock

Satu asset tidak boleh mempunyai lebih dari satu mutation aktif.

Client dapat melakukan pre-check.

Backend wajib melakukan authoritative check.

Jangan mengandalkan Flutter saja untuk mencegah duplicate mutation.

---

# 16. UI Rules

Ikuti `DESIGN.md`.

Wajib:

- Inter;
- centralized colors;
- centralized typography;
- centralized spacing;
- reusable components;
- status menggunakan icon + text + color;
- touch target minimal 44px;
- target implementasi 48px;
- WCAG-oriented contrast.

Dilarang:

- neon;
- glassmorphism;
- excessive gradients;
- excessive shadows;
- random colors;
- random typography;
- color-only status;
- icon-only critical actions.

---

# 17. Design Tokens

Gunakan:

```text
Primary      #0F3D56
Secondary    #0F766E
Background   #F6F8FA
Surface      #FFFFFF
Success      #15803D
Warning      #B45309
Error        #B42318
Info         #175CD3
```

Jangan hardcode warna berulang kali.

---

# 18. Shared Components

Sebelum membuat widget baru, periksa apakah sudah ada:

```text
AppButton
AppTextField
AppDropdown
AppCard
StatusBadge
MutationCard
AssetCard
TimelineWidget
NotificationItem
EmptyState
ErrorState
OfflineBanner
ConfirmationDialog
SectionHeader
```

Jika komponen sudah ada, gunakan kembali.

---

# 19. State Handling

Setiap asynchronous screen minimal harus menangani:

```text
Loading
Success
Empty
Error
```

Jika relevan:

```text
Offline
Syncing
Sync Failed
```

Jangan hanya mengimplementasikan successful state.

---

# 20. Form Submission

Saat submit:

```text
Tap Submit
 ↓
Disable Button
 ↓
Loading
 ↓
Request
 ↓
Success / Error
```

Tujuan:

```text
Prevent Double Submit
```

Jangan menampilkan success jika request sebenarnya gagal.

---

# 21. Error Handling

Jangan menampilkan raw exception kepada user.

Gunakan failure abstraction:

```text
NetworkFailure
UnauthorizedFailure
ForbiddenFailure
ValidationFailure
NotFoundFailure
ConflictFailure
ServerFailure
UnknownFailure
```

User-facing message harus jelas dan dapat dipahami.

---

# 22. Security

Dilarang:

```text
Hardcoded password
Hardcoded API secret
Hardcoded production token
Logging authentication token
Logging password
```

Credential harus menggunakan secure storage mechanism.

Production menggunakan HTTPS.

Authorization harus dilakukan backend.

---

# 23. Environment

Gunakan environment configuration.

Contoh:

```text
API_BASE_URL=
APP_ENV=development
```

Jangan hardcode production URL di banyak file.

---

# 24. Testing Requirement

Setiap feature penting harus memiliki test yang sesuai.

Minimal:

```text
Unit Test
Widget Test
Integration Test
```

Sebelum menyatakan feature selesai:

```bash
flutter analyze
flutter test
```

harus berhasil.

---

# 25. Development Workflow

Setiap task:

```text
READ
 ↓
PLAN
 ↓
IMPLEMENT
 ↓
ANALYZE
 ↓
TEST
 ↓
REVIEW
 ↓
REPORT
```

Jangan mengerjakan task tanpa memahami requirement.

---

# 26. Change Scope

Untuk setiap task, agent harus mengetahui:

```text
What is requested?
What files are affected?
What is NOT requested?
```

Jangan melakukan unrelated changes.

---

# 27. Before Coding

Agent harus memberikan ringkasan singkat:

```text
Task:
Affected files:
Implementation plan:
Potential risk:
```

Untuk task kecil, cukup ringkas.

---

# 28. After Coding

Agent harus melaporkan:

```text
Changed files:
Implemented:
Tests:
Analyzer:
Known limitations:
```

Contoh:

```text
Changed:
- lib/features/auth/...
- test/features/auth/...

Implemented:
- login state
- session handling

Validation:
- flutter analyze ✓
- flutter test ✓

Known limitation:
- backend API belum tersedia; mock repository digunakan.
```

---

# 29. Dependency Rule

Jangan menambahkan package hanya karena "mungkin berguna".

Sebelum menambah dependency:

```text
1. Check whether Flutter/Dart already provides capability.
2. Check existing dependencies.
3. Determine whether dependency is necessary.
4. Add only if justified.
```

---

# 30. No Overengineering

MVP harus sederhana.

Jangan membuat:

- microservices;
- unnecessary abstraction;
- unnecessary generic framework;
- complex state machine library;
- unnecessary caching;
- unnecessary animation system;

jika belum diperlukan.

---

# 31. Definition of Done

Task selesai jika:

- [ ] Requirement terpenuhi.
- [ ] Architecture sesuai.
- [ ] UI sesuai design system.
- [ ] Role/permission benar.
- [ ] Error state tersedia.
- [ ] Loading state tersedia.
- [ ] Validation tersedia.
- [ ] Test sesuai kebutuhan.
- [ ] `flutter analyze` berhasil.
- [ ] `flutter test` berhasil.
- [ ] Tidak ada secret.
- [ ] Tidak ada unrelated modification.
- [ ] Known limitation dilaporkan.

---

# 32. Golden Rule

> **Follow the documentation. Inspect before changing. Do not invent business rules. Keep changes small. Test before finishing.**