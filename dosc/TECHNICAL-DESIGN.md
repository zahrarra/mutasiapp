# Technical Design Document — MutasiKu

**Project:** MutasiKu  
**Platform:** Mobile  
**Framework:** Flutter  
**Version:** MVP 1.0  
**Tanggal:** 16 September 2026

---

## 1. Tujuan

Dokumen ini menerjemahkan kebutuhan pada PRD, alur setiap role, spesifikasi screen, dan design system MutasiKu menjadi rancangan teknis yang dapat digunakan sebagai acuan implementasi Flutter.

Technical design harus:

- menjaga alur bisnis sesuai PRD;
- memisahkan UI, business logic, dan data access;
- mendukung role-based access;
- mendukung offline submission untuk Pemohon;
- menangani sinkronisasi dan konflik data;
- menjaga agar perubahan backend tidak menyebabkan perubahan besar pada UI;
- mudah diuji dan dikembangkan.

Dokumen ini berlaku sebagai **technical source of truth** setelah PRD dan design system.

---

# 2. Prinsip Arsitektur

MutasiKu menggunakan pendekatan:

> **Feature-First + Layered Architecture / Clean Architecture ringan**

Arsitektur tidak boleh dibuat terlalu kompleks untuk kebutuhan MVP.

Struktur logis:

```text
Presentation
     ↓
Domain
     ↓
Data
     ↓
External Services
```

### Presentation

Berisi:

- screens;
- widgets;
- state management;
- navigation;
- form handling.

### Domain

Berisi:

- entities;
- business rules;
- use cases;
- repository contracts.

### Data

Berisi:

- API implementation;
- local database;
- DTO/model;
- repository implementation;
- synchronization.

### External Services

Berisi:

- backend API;
- local database;
- file storage;
- notification service;
- connectivity service.

---

# 3. Struktur Folder Flutter

Struktur utama:

```text
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   ├── route_guards.dart
│   │   └── route_names.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       ├── app_typography.dart
│       └── app_spacing.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   ├── utils/
│   ├── validators/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── mutation/
│   ├── asset/
│   ├── approval/
│   ├── verification/
│   ├── notification/
│   ├── history/
│   └── admin/
│
└── main.dart
```

Setiap feature dapat memiliki:

```text
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

---

# 4. Feature Structure

## 4.1 Auth

```text
features/auth/

data/
├── datasources/
│   └── auth_remote_datasource.dart
├── models/
│   └── user_model.dart
└── repositories/
    └── auth_repository_impl.dart

domain/
├── entities/
│   └── user.dart
├── repositories/
│   └── auth_repository.dart
└── usecases/
    ├── login.dart
    ├── logout.dart
    └── get_current_user.dart

presentation/
├── providers/
│   └── auth_provider.dart
├── screens/
│   └── login_screen.dart
└── widgets/
```

---

# 5. Mutation Feature

Feature utama:

```text
features/mutation/
```

Struktur:

```text
mutation/
├── data/
│   ├── datasources/
│   │   ├── mutation_remote_datasource.dart
│   │   └── mutation_local_datasource.dart
│   │
│   ├── models/
│   │   ├── mutation_model.dart
│   │   ├── mutation_dto.dart
│   │   └── mutation_sync_model.dart
│   │
│   └── repositories/
│       └── mutation_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── mutation_request.dart
│   │   ├── mutation_status.dart
│   │   └── mutation_history.dart
│   │
│   ├── repositories/
│   │   └── mutation_repository.dart
│   │
│   └── usecases/
│       ├── submit_mutation.dart
│       ├── get_my_mutations.dart
│       ├── get_mutation_detail.dart
│       ├── update_mutation.dart
│       ├── confirm_mutation.dart
│       └── sync_mutations.dart
│
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

---

# 6. Role-Based Feature

Role bukan dibuat sebagai aplikasi terpisah.

Semua role menggunakan:

- design system yang sama;
- authentication system yang sama;
- API layer yang sama;
- navigation system yang sama.

Perbedaan ditentukan oleh:

```text
Role
+
Permission
+
Workflow State
```

Contoh:

```text
Pemohon
    ↓
Ajukan Mutasi
    ↓
Track Mutation
```

sedangkan:

```text
Operator
    ↓
Pengajuan Masuk
    ↓
Verifikasi
```

dan:

```text
Kabag
    ↓
Menunggu Approval
    ↓
Approve / Reject
```

---

# 7. Role Enum

Gunakan enum/domain representation untuk role.

```dart
enum UserRole {
  admin,
  pemohon,
  operator,
  kabagAset,
  kadiv,
  staffAset,
}
```

Jangan menggunakan string role secara acak di seluruh UI.

Contoh yang harus dihindari:

```dart
if (user.role == "Kabag Aset") {}
```

Gunakan abstraction:

```dart
if (user.role == UserRole.kabagAset) {}
```

Mapping dari API dilakukan pada layer data.

---

# 8. Mutation Status

Status harus menjadi centralized enum.

Contoh:

```dart
enum MutationStatus {
  diajukan,
  dikembalikanKePemohon,
  menungguApprovalKabag,
  menungguApprovalKadiv,
  disetujuiMenungguUpdateAset,
  ditolak,
  menungguKonfirmasiPemohon,
  selesai,
  menungguSinkronisasi,
}
```

Status tidak boleh ditulis sebagai string literal di banyak screen.

Mapping tampilan:

```text
Domain Status
      ↓
Status Presentation
      ↓
Label + Icon + Color
```

Status tetap mengikuti PRD.

Jangan membuat status baru hanya untuk mempermudah implementasi UI.

---

# 9. Workflow State Machine

Alur utama:

```text
Diajukan
    ↓
Verifikasi Operator
    ↓
┌───────────────┐
│ Valid?        │
└───────┬───────┘
    Tidak│      │Ya
         ↓      ↓
Dikembalikan   Menunggu Approval Kabag
                    ↓
                Kabag Review
                    ↓
             ┌──────┴──────┐
             │             │
           Tolak         Setuju
             ↓             ↓
          Ditolak     Perlu Kadiv?
                           │
                    ┌──────┴──────┐
                    │             │
                   Ya            Tidak
                    ↓             ↓
              Approval Kadiv   Update Aset
                    ↓
              Update Aset
                    ↓
          Menunggu Konfirmasi
                    ↓
                 Selesai
```

Implementasi tidak boleh membiarkan UI mengubah status secara langsung.

Contoh yang **tidak diperbolehkan**:

```dart
status = MutationStatus.selesai;
```

di dalam widget.

Status harus berubah melalui use case/repository sesuai workflow.

---

# 10. Domain Entity

Entity utama:

```text
User
Asset
AssetCategory
Location
MutationRequest
Approval
MutationHistory
Notification
Document
```

Contoh:

```dart
class MutationRequest {
  final String id;
  final String? ticketNumber;
  final String assetId;
  final String applicantId;
  final String originLocationId;
  final String destinationLocationId;
  final String newPicId;
  final MutationStatus status;
  final String? reason;
  final DateTime createdAt;
}
```

Field final menyesuaikan API contract yang nantinya disepakati.

Agent **tidak boleh mengarang field backend**.

---

# 11. Repository Pattern

UI tidak boleh berkomunikasi langsung dengan HTTP client.

Alur:

```text
Screen
 ↓
Provider / Controller
 ↓
Use Case
 ↓
Repository Interface
 ↓
Repository Implementation
 ↓
Remote / Local Data Source
```

Contoh:

```dart
abstract class MutationRepository {
  Future<Result<MutationRequest>> submitMutation(
    MutationRequest request,
  );

  Future<Result<List<MutationRequest>>> getMyMutations();

  Future<Result<MutationRequest>> getMutationDetail(
    String id,
  );

  Future<Result<void>> confirmMutation(
    String id,
  );
}
```

---

# 12. State Management

Untuk MVP, gunakan satu state management solution secara konsisten.

Rekomendasi:

> **Riverpod**

Alasan teknis:

- dependency injection;
- reactive state;
- mudah memisahkan UI dan business logic;
- testable;
- cocok untuk asynchronous state;
- mendukung feature-based architecture.

Jangan mencampurkan:

```text
setState
Provider
Bloc
Riverpod
GetX
```

secara tidak terkontrol.

`setState` masih dapat digunakan untuk state UI lokal sederhana yang tidak memiliki business logic.

---

# 13. Navigation

Gunakan centralized routing.

Contoh:

```text
/login

/pemohon/dashboard
/pemohon/mutations
/pemohon/mutations/create
/pemohon/mutations/:id
/pemohon/mutations/:id/confirm

/operator/dashboard
/operator/mutations
/operator/mutations/:id
/operator/mutations/:id/verify

/kabag/dashboard
/kabag/approvals
/kabag/approvals/:id

/kadiv/dashboard
/kadiv/approvals
/kadiv/approvals/:id

/staff-aset/dashboard
/staff-aset/mutations
/staff-aset/mutations/:id
/staff-aset/mutations/:id/update

/admin/dashboard
/admin/users
/admin/roles
/admin/locations
/admin/asset-categories
/admin/approval-criteria
```

Nama route harus centralized.

---

# 14. Route Guard

Route guard harus memeriksa:

```text
Authenticated?
     ↓
Role?
     ↓
Permission?
     ↓
Allow / Redirect
```

Contoh:

```text
User belum login
    ↓
Login

User login sebagai Pemohon
    ↓
Tidak boleh membuka Admin

User login sebagai Staff Aset
    ↓
Boleh membuka update aset
```

Route guard adalah lapisan keamanan UI.

Namun **authorization sebenarnya tetap harus dilakukan backend**.

Jangan menganggap route guard Flutter sebagai security boundary utama.

---

# 15. Authentication

Backend authentication masih merupakan Open Question pada PRD.

Karena itu frontend menggunakan abstraction:

```dart
abstract class AuthRepository {
  Future<Result<User>> login(
    String username,
    String password,
  );

  Future<Result<User?>> getCurrentUser();

  Future<void> logout();
}
```

Implementasi authentication dapat diganti tanpa mengubah screen login.

Contoh kemungkinan:

```text
Token-based API
JWT
Sanctum
OAuth
SSO
```

Keputusan final mengikuti backend.

Jangan mengunci implementasi tertentu sebelum backend ditentukan.

---

# 16. Session Management

Session harus menangani:

```text
Login
 ↓
Store credential/token securely
 ↓
Attach token to API request
 ↓
Refresh/re-authentication if required
 ↓
Logout
 ↓
Clear session
```

Credential/token tidak boleh disimpan menggunakan plain text storage jika mekanisme tersebut merupakan credential sensitif.

Gunakan secure storage abstraction.

---

# 17. API Client

Semua request API melalui satu HTTP abstraction.

Contoh:

```text
core/network/

api_client.dart
api_response.dart
network_exception.dart
```

API client menangani:

- base URL;
- authentication header;
- timeout;
- JSON parsing;
- HTTP errors;
- retry sesuai kebutuhan;
- logging development.

Feature tidak boleh membuat HTTP client sendiri-sendiri.

---

# 18. API Contract

Endpoint adalah **asumsi teknis sementara** sampai backend final tersedia.

Contoh struktur:

```text
POST   /auth/login

GET    /assets
GET    /assets/{id}

POST   /mutations
GET    /mutations
GET    /mutations/{id}
PUT    /mutations/{id}

POST   /mutations/{id}/verify
POST   /mutations/{id}/approve
POST   /mutations/{id}/reject
POST   /mutations/{id}/kadiv-approve
POST   /mutations/{id}/asset-update
POST   /mutations/{id}/confirm

GET    /notifications
```

Endpoint final harus mengikuti kontrak backend.

Agent tidak boleh membuat endpoint baru tanpa instruksi atau API specification.

---

# 19. Ticket Number

Format:

```text
KATEGORI-TAHUN-NOURUT
```

Contoh:

```text
LAPTOP-2026-0001
```

Ticket **harus dianggap server-generated**.

### Online

```text
Submit
 ↓
Server validates
 ↓
Server creates mutation
 ↓
Server generates ticket
 ↓
Flutter receives ticket
```

### Offline

```text
Submit
 ↓
Save local
 ↓
Menunggu Sinkronisasi
 ↓
Internet available
 ↓
Sync
 ↓
Server creates mutation
 ↓
Server generates ticket
```

Flutter tidak boleh membuat ticket final sendiri karena berpotensi menghasilkan duplicate number.

---

# 20. Offline Architecture

Offline MVP terutama berlaku untuk Pemohon.

Arsitektur:

```text
UI
 ↓
Mutation Repository
 ↓
Connectivity Check
 ↓
┌──────────────┴──────────────┐
Online                        Offline
 ↓                             ↓
Remote API                 Local Database
 ↓                             ↓
Server Ticket               Pending Sync
```

Local mutation memiliki:

```text
localId
payload
createdAt
syncStatus
retryCount
lastError
```

Status lokal:

```text
pending
syncing
synced
failed
conflict
```

Status ini berbeda dari business status mutation.

Jangan mencampurkan:

```text
syncStatus
```

dengan:

```text
mutationStatus
```

---

# 21. Synchronization

Ketika koneksi tersedia:

```text
Connectivity detected
       ↓
Read pending queue
       ↓
Validate local payload
       ↓
Send to server
       ↓
Success?
   ┌───┴───┐
  Yes      No
   ↓        ↓
Synced   Retry / Error
```

Retry harus memiliki batas.

Jangan melakukan infinite retry.

Contoh:

```text
retry 1
retry 2
retry 3
↓
failed
```

User harus dapat melihat bahwa data membutuhkan perhatian jika sync gagal.

---

# 22. Conflict Handling

Conflict dapat terjadi apabila:

```text
User A offline menyimpan mutation
          ↓
Server asset berubah
          ↓
User A melakukan sync
```

Server menjadi source of truth.

Jika conflict:

```text
Server rejects mutation
        ↓
Flutter receives conflict
        ↓
Mutation status = conflict
        ↓
User receives explanation
```

Jangan melakukan silent overwrite terhadap data server.

---

# 23. Asset Lock

Satu asset tidak boleh memiliki lebih dari satu mutation aktif.

Pengecekan dilakukan minimal pada:

```text
Flutter
+
Backend
```

Flutter dapat melakukan pre-check untuk UX.

Backend wajib melakukan authoritative validation.

Contoh:

```text
Asset A
   ↓
Mutation #001 active
   ↓
Mutation #002
   ↓
BLOCKED
```

Race condition tetap harus ditangani server.

---

# 24. Local Database

Offline storage membutuhkan database lokal.

Pilihan teknis yang dapat digunakan:

> **Drift**

Alasan:

- relational;
- cocok dengan struktur mutation;
- transaction support;
- query typed;
- cocok untuk pending synchronization queue.

Namun pilihan database lokal masih dapat diganti apabila kebutuhan backend/offline berubah.

Struktur:

```text
local database
├── pending_mutations
├── cached_assets
├── cached_locations
├── cached_users
└── sync_queue
```

Jangan menyimpan seluruh database server secara lokal hanya untuk membuat offline terlihat bekerja.

Cache harus dibatasi pada kebutuhan MVP.

---

# 25. Error Handling

Gunakan centralized failure model.

Contoh:

```dart
sealed class Failure {}

class NetworkFailure extends Failure {}

class UnauthorizedFailure extends Failure {}

class ForbiddenFailure extends Failure {}

class ValidationFailure extends Failure {}

class NotFoundFailure extends Failure {}

class ConflictFailure extends Failure {}

class ServerFailure extends Failure {}

class UnknownFailure extends Failure {}
```

UI kemudian memetakan failure menjadi pesan yang dapat dipahami user.

Contoh:

```text
NetworkFailure
→ "Koneksi internet tidak tersedia."

ValidationFailure
→ "Periksa kembali data pengajuan."

ConflictFailure
→ "Aset sedang memiliki proses mutasi lain."
```

Jangan menampilkan raw exception kepada user.

---

# 26. Form Validation

Validasi dilakukan dua tahap:

```text
Client Validation
        ↓
Server Validation
```

Client validation digunakan untuk UX.

Server validation menjadi sumber kebenaran.

Contoh:

```text
Asset wajib dipilih
Lokasi tujuan wajib dipilih
PIC baru wajib valid
Alasan wajib diisi jika diperlukan
Dokumen wajib jika aturan bisnis menetapkannya
```

Jangan menambahkan field wajib yang belum ditentukan PRD/business rule.

---

# 27. Document Upload

Supporting document masih merupakan Open Question.

Karena itu implementasi harus abstraction-friendly.

```text
DocumentPicker
      ↓
File Validation
      ↓
Upload Service
      ↓
Server
```

Validasi dapat mencakup:

- extension;
- MIME type;
- file size.

Aturan final mengikuti backend/business requirement.

---

# 28. Notification

Notification bersifat asynchronous.

Contoh:

```text
Mutation submitted
       ↓
Backend changes status
       ↓
Notification created
       ↓
Flutter fetches notification
```

Notification failure tidak boleh membatalkan perubahan status.

Sesuai PRD:

```text
Status Update
      ↓
Success
      ↓
Notification
      ↓
Notification failed?
      ↓
Status tetap berhasil
```

---

# 29. Timeline / Mutation History

Timeline adalah read-oriented component.

Data:

```text
Event
├── status
├── actor
├── timestamp
├── description
└── metadata
```

Contoh:

```text
16 Sep 2026 09:10
Pemohon mengajukan mutasi

16 Sep 2026 10:20
Operator memverifikasi data

16 Sep 2026 13:40
Kabag Aset menyetujui

17 Sep 2026 09:15
Staff Aset memperbarui lokasi
```

Timeline tidak boleh dibuat berdasarkan asumsi lokal Flutter.

History harus berasal dari server setelah tersedia.

---

# 30. Audit Trail

Aktivitas penting harus dapat ditelusuri.

Minimal event:

```text
Login
Mutation Created
Mutation Updated
Verification
Approval
Rejection
Asset Update
Applicant Confirmation
Sync Conflict
```

Audit trail authoritative berada di backend.

Flutter hanya menampilkan data audit/history yang dikirim server.

---

# 31. Security

Minimal:

- HTTPS untuk production;
- secure credential storage;
- token tidak disimpan di source code;
- API authorization;
- role-based access;
- input validation;
- file validation;
- timeout;
- logout/session invalidation;
- tidak menampilkan sensitive information di log production.

Jangan:

```dart
const apiKey = "...";
```

atau:

```dart
const password = "...";
```

di source code.

---

# 32. Environment Configuration

Gunakan konfigurasi environment.

Contoh:

```text
.env.example

API_BASE_URL=
APP_ENV=
```

Environment:

```text
development
staging
production
```

API URL tidak boleh tersebar sebagai hardcoded string di setiap repository.

---

# 33. Theme Implementation

Design system harus diimplementasikan centralized.

```text
app/theme/

app_colors.dart
app_typography.dart
app_spacing.dart
app_theme.dart
```

Gunakan token yang telah ditetapkan:

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

Jangan membuat:

```dart
Colors.blue
Colors.green
Colors.red
```

secara sembarangan pada feature screen.

Gunakan semantic color.

---

# 34. Shared Components

Komponen berikut harus reusable:

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

Komponen tidak boleh dibuat ulang hanya karena screen berbeda.

Contoh:

```text
StatusBadge
```

digunakan oleh:

```text
Pemohon
Operator
Kabag
Kadiv
Staff Aset
```

dengan status yang sama.

---

# 35. UI State

Setiap screen harus menangani minimal:

```text
Initial
Loading
Success
Empty
Error
```

Untuk screen yang membutuhkan koneksi:

```text
Offline
Syncing
Sync Failed
```

Contoh:

```text
Loading
   ↓
Success

Loading
   ↓
Empty

Loading
   ↓
Error
```

Jangan hanya membuat happy path.

---

# 36. Loading Rules

Gunakan loading indicator pada action yang membutuhkan waktu.

Contoh:

```text
Submit
 ↓
Loading
 ↓
Success
```

Saat submit sedang berlangsung:

```text
Button disabled
```

Tujuannya mencegah duplicate request.

---

# 37. Double Submit Protection

Form submission harus memiliki protection:

```text
User tap Submit
      ↓
isSubmitting = true
      ↓
Disable Submit
      ↓
Request
      ↓
Success/Error
      ↓
isSubmitting = false
```

Untuk duplicate request yang lebih serius, backend tetap harus memiliki idempotency/concurrency protection bila diperlukan.

---

# 38. Permission Architecture

Permission sebaiknya tidak ditentukan hanya dari screen.

Model:

```text
User
 ↓
Role
 ↓
Permission
 ↓
Action
```

Contoh:

```text
mutation.create
mutation.verify
mutation.approve
mutation.reject
asset.update
user.manage
criteria.manage
```

Admin dapat memiliki permission master data.

Operator memiliki permission verification.

Kabag memiliki approval permission.

Staff Aset memiliki asset update permission.

Namun permission final harus mengikuti backend/business rules.

---

# 39. Admin Architecture

Admin tidak menangani approval mutation.

Admin feature:

```text
admin/
├── users
├── roles
├── locations
├── asset_categories
└── approval_criteria
```

Perubahan approval criteria:

```text
Admin update criteria
       ↓
Backend saves criteria
       ↓
Criteria applies to NEW submissions
```

PRD menetapkan perubahan kriteria tidak mengubah submission yang sedang berjalan.

---

# 40. Applicant Confirmation

Flow:

```text
Staff Aset update
       ↓
Menunggu Konfirmasi Pemohon
       ↓
Pemohon menerima notification
       ↓
Confirm
       ↓
Selesai
```

Auto-close:

```text
1 × 24 jam kerja
```

masih merupakan business rule yang perlu dikonfirmasi final.

Flutter tidak boleh membuat timer business rule sendiri sebagai sumber kebenaran.

Server harus menjadi source of truth untuk SLA dan auto-close.

---

# 41. Working Hours

Asumsi PRD:

```text
08:00–17:00
Senin–Jumat
```

Tetapi:

- holiday handling;
- weekend;
- timezone;
- SLA calculation;

masih perlu keputusan final.

Flutter tidak boleh mengimplementasikan perhitungan SLA final sebelum business rule ditetapkan.

---

# 42. Testing Strategy

Testing minimal:

## Unit Test

Untuk:

```text
Use cases
Validators
Status mapping
Permission logic
Sync logic
```

Contoh:

```text
submit mutation
→ success

submit mutation
→ validation failure

sync pending mutation
→ success

sync
→ conflict
```

## Widget Test

Untuk:

```text
Login
Mutation form
Status badge
Approval screen
Verification screen
Confirmation screen
```

## Integration Test

Minimal:

```text
Login
→ Create Mutation
→ Verification
→ Approval
→ Asset Update
→ Confirmation
→ Completed
```

---

# 43. Offline Testing

Test scenario:

```text
Internet ON
→ Submit
→ Server success
```

```text
Internet OFF
→ Submit
→ Local save
→ Menunggu Sinkronisasi
```

```text
Internet OFF
→ Submit
→ Internet ON
→ Auto Sync
→ Ticket received
```

```text
Offline
→ Server asset already mutated
→ Sync
→ Conflict
```

---

# 44. API Mocking

Sebelum backend final tersedia, frontend dapat menggunakan mock repository/data source.

Contoh:

```text
MockAuthRepository
MockMutationRepository
MockAssetRepository
```

Tujuan:

- UI dapat dikembangkan;
- workflow dapat diuji;
- backend belum menjadi blocker;
- API contract dapat diuji lebih awal.

Mock harus diberi label jelas dan tidak dianggap sebagai production implementation.

---

# 45. Dependency Injection

Dependency injection digunakan agar implementation dapat diganti.

Contoh:

```text
MutationRepository
       ↑
       |
MutationRepositoryImpl
       |
       ├── RemoteDataSource
       └── LocalDataSource
```

Testing:

```text
MutationRepository
       ↑
MockMutationRepository
```

---

# 46. Logging

Development:

```text
API request
API response
sync event
routing
error
```

Production:

- jangan log password;
- jangan log token;
- jangan log sensitive personal data;
- jangan log dokumen content.

Logging harus memiliki abstraction agar mudah dinonaktifkan/diubah.

---

# 47. Performance

MVP harus memperhatikan:

- pagination untuk daftar panjang;
- lazy loading;
- image/file size;
- debounce search;
- avoid unnecessary rebuild;
- local query efficiency;
- dispose controllers;
- avoid loading seluruh asset database sekaligus.

Jangan melakukan premature optimization.

---

# 48. Accessibility

Mengikuti design system:

```text
Touch target ≥ 44 × 44
Target implementasi = 48 × 48
```

Status:

```text
Icon + Text + Color
```

bukan warna saja.

Text harus readable.

Form harus memiliki label yang jelas.

Interactive element harus memiliki semantic meaning.

---

# 49. Coding Rules for Agent

AI coding agent wajib mengikuti aturan:

### Rule 1 — PRD First

Jika requirement belum jelas:

```text
DO NOT INVENT.
```

Tandai sebagai:

```text
OPEN QUESTION
```

### Rule 2 — Business Logic Tidak di UI

Jangan menaruh workflow approval di widget.

### Rule 3 — No Direct API in Screen

Screen:

```text
Provider
```

Provider:

```text
Use Case
```

Use Case:

```text
Repository
```

### Rule 4 — Reuse Components

Sebelum membuat widget baru:

```text
CHECK EXISTING SHARED COMPONENT.
```

### Rule 5 — No Hardcoded Design Token

Gunakan:

```text
AppColors
AppTypography
AppSpacing
```

### Rule 6 — Backend Is Source of Truth

Terutama untuk:

```text
status
ticket
authorization
SLA
asset lock
approval
```

### Rule 7 — No Fake Success

Jangan menampilkan:

```text
"Berhasil"
```

jika request/save sebenarnya gagal.

### Rule 8 — Handle Failure

Setiap asynchronous operation harus memiliki:

```text
loading
success
error
```

### Rule 9 — Preserve Existing Code

Jangan menghapus architecture atau feature yang sudah ada tanpa alasan dan konfirmasi.

### Rule 10 — Small Changes

Implementasi dilakukan secara incremental.

---

# 50. Implementation Sequence

Jangan langsung membuat seluruh aplikasi sekaligus.

Urutan:

```text
Phase 1
Project Setup
    ↓
Theme
    ↓
Core
```

```text
Phase 2
Authentication
    ↓
Role
    ↓
Navigation
    ↓
Route Guard
```

```text
Phase 3
Asset
    ↓
Location
    ↓
Master Data Read
```

```text
Phase 4
Mutation Submission
    ↓
Ticket
    ↓
Tracking
```

```text
Phase 5
Operator Verification
```

```text
Phase 6
Kabag Approval
```

```text
Phase 7
Kadiv Conditional Approval
```

```text
Phase 8
Staff Aset Update
```

```text
Phase 9
Applicant Confirmation
```

```text
Phase 10
Notification
```

```text
Phase 11
Offline + Sync
```

```text
Phase 12
Admin Master Data
```

```text
Phase 13
Testing
    ↓
UAT
```

---

# 51. Definition of Done

Feature dianggap selesai apabila:

- [ ] UI mengikuti design system.
- [ ] Role permission benar.
- [ ] Navigation benar.
- [ ] Loading state tersedia.
- [ ] Empty state tersedia jika relevan.
- [ ] Error state tersedia.
- [ ] Validation tersedia.
- [ ] Tidak ada hardcoded API URL.
- [ ] Tidak ada hardcoded design token.
- [ ] Tidak ada business logic penting di UI.
- [ ] Repository digunakan.
- [ ] Unit test relevan tersedia.
- [ ] Tidak ada debug code yang tertinggal.
- [ ] Tidak ada fake data pada production path.
- [ ] Workflow sesuai PRD.
- [ ] Backend error ditangani.
- [ ] Tidak terjadi duplicate submission.
- [ ] Security-sensitive data tidak masuk log.

---

# 52. Technical Open Questions

Keputusan berikut belum boleh diasumsikan final:

1. Backend technology.
2. Database backend.
3. Authentication mechanism.
4. API specification final.
5. Supporting document requirements.
6. Kadiv approval criteria.
7. Approval SLA.
8. Auto-close rule.
9. Working hours dan holiday calculation.
10. Offline scope selain Pemohon.
11. Initial asset categories.
12. Notification implementation.
13. Production deployment.
14. Numeric success metrics.

---

# 53. Technical Source of Truth

Urutan authority:

```text
1. Business Decision
        ↓
2. PRD
        ↓
3. Role Flow
        ↓
4. Screen Specification
        ↓
5. Design System
        ↓
6. Technical Design
        ↓
7. Implementation
```

Jika terjadi konflik:

```text
Higher-level requirement wins.
```

Agent tidak boleh mengubah business rule hanya karena implementasi teknis lebih mudah.

---

# 54. Final Architecture

Target architecture:

```text
                         ┌─────────────────────┐
                         │      Flutter UI     │
                         │ Screens / Widgets   │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │ Presentation State  │
                         │     Riverpod        │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │      Use Cases      │
                         │       Domain        │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │    Repository       │
                         │     Interface       │
                         └──────────┬──────────┘
                                    │
                     ┌──────────────┴──────────────┐
                     ▼                             ▼
          ┌──────────────────┐          ┌──────────────────┐
          │ Remote DataSource│          │ Local DataSource │
          │      API         │          │ Drift / Offline  │
          └────────┬─────────┘          └────────┬─────────┘
                   │                             │
                   ▼                             ▼
          ┌──────────────────┐          ┌──────────────────┐
          │ Backend Server   │          │ Local Database   │
          └──────────────────┘          └──────────────────┘
```

---

# 55. Status

```text
PRD               ✓
ROLE FLOW         ✓
DESIGN BRIEF      ✓
SCREEN SPEC       ✓
WIREFRAME         ✓
DESIGN SYSTEM     ✓
TECHNICAL DESIGN  ✓
────────────────────────
NEXT:
FLUTTER PROJECT SETUP
```

**Technical Design Status: READY FOR IMPLEMENTATION**