# Project Setup Document — MutasiKu

**Project:** MutasiKu  
**Platform:** Mobile  
**Framework:** Flutter  
**Architecture:** Feature-First + Clean Architecture ringan  
**State Management:** Riverpod  
**Routing:** go_router  
**Local Database:** Drift  
**Version:** MVP 1.0  
**Status:** Ready for Initial Implementation

---

# 1. Tujuan

Tahap ini bertujuan menyiapkan fondasi teknis aplikasi MutasiKu sebelum implementasi business feature.

Scope tahap ini:

- Flutter project;
- folder architecture;
- application bootstrap;
- theme;
- design tokens;
- routing;
- authentication skeleton;
- role model;
- core error handling;
- network abstraction;
- local storage abstraction;
- environment configuration;
- shared widgets dasar.

Belum mengimplementasikan seluruh workflow mutasi.

---

# 2. Prinsip Utama

Agent harus mengikuti prinsip:

```text
Setup Foundation
        ↓
Verify Foundation
        ↓
Implement Feature
```

Jangan membuat:

```text
Login
Mutation
Approval
Notification
Offline
Admin
```

sekaligus dalam satu perubahan besar.

---

# 3. Initial Project Structure

Target:

```text
mutasiku/
│
├── android/
├── ios/
├── web/
├── test/
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── lib/
│   │
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   │
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   ├── route_names.dart
│   │   │   └── route_guards.dart
│   │   │
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       ├── app_colors.dart
│   │       ├── app_typography.dart
│   │       └── app_spacing.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── network/
│   │   ├── storage/
│   │   ├── utils/
│   │   ├── validators/
│   │   └── widgets/
│   │
│   └── features/
│       ├── auth/
│       ├── dashboard/
│       ├── mutation/
│       ├── asset/
│       ├── approval/
│       ├── verification/
│       ├── notification/
│       ├── history/
│       └── admin/
│
├── .env.example
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

---

# 4. Application Bootstrap

Entry point:

```text
main.dart
    ↓
initialize dependencies
    ↓
initialize storage
    ↓
initialize services
    ↓
runApp()
```

`main.dart` harus tetap tipis.

Jangan menempatkan:

- business logic;
- API request;
- mutation workflow;
- role logic;

langsung di `main.dart`.

---

# 5. App Root

`app.dart` bertanggung jawab terhadap:

- MaterialApp/MaterialApp.router;
- theme;
- router;
- localization jika nanti diperlukan;
- global configuration.

Struktur:

```text
main.dart
   ↓
MutasiKuApp
   ├── Theme
   └── Router
```

---

# 6. Theme

Semua design token harus centralized.

## Colors

```text
Primary      #0F3D56
Secondary    #0F766E
Background   #F6F8FA
Surface      #FFFFFF

Success      #15803D
Warning      #B45309
Error        #B42318
Info         #175CD3

Text Primary   #172B4D
Text Secondary #52606D
Disabled       #98A2B3
Border         #D0D5DD
```

## Typography

Font utama:

```text
Inter
```

Scale:

```text
Display    32 / 700
H1         24 / 700
H2         20 / 700
H3         18 / 600
Body Large 16
Body       14
Caption    12
Button     14 / 600
Ticket     14 / 600
```

## Spacing

```text
4
8
12
16
20
24
32
40
48
64
```

## Radius

```text
4
8
12
16
24
999
```

Card:

```text
12
```

Button:

```text
8
```

---

# 7. Theme Rule

Dilarang:

```dart
Container(
  color: Color(0xFF0F3D56),
)
```

di banyak screen.

Gunakan:

```dart
Theme.of(context).colorScheme
```

atau centralized design token.

Tujuan:

```text
One Source of Truth
```

---

# 8. Shared Widgets

Buat foundation untuk:

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

Namun jangan membuat semua widget kompleks pada tahap awal.

Mulai dari:

```text
AppButton
AppTextField
AppCard
StatusBadge
EmptyState
ErrorState
OfflineBanner
```

Komponen lain dibuat ketika feature membutuhkan.

---

# 9. Authentication Skeleton

Tahap awal hanya membutuhkan:

```text
Login Screen
Auth State
Current User
Logout
```

Flow:

```text
App Start
    ↓
Check Session
    ↓
┌───────────────┐
│ Authenticated?│
└───────┬───────┘
     No │   │ Yes
        ↓   ↓
      Login Dashboard
```

---

# 10. User Entity

Minimal:

```dart
class User {
  final String id;
  final String username;
  final String name;
  final UserRole role;
}
```

Jangan menambahkan field yang belum diperlukan tanpa alasan.

---

# 11. Role Model

Gunakan:

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

Mapping API dilakukan di data layer.

UI tidak boleh bergantung pada string mentah dari backend.

---

# 12. Routing

Initial routes:

```text
/login
```

Authenticated dashboard route harus diarahkan berdasarkan role.

Contoh:

```text
Admin
→ /admin/dashboard

Pemohon
→ /pemohon/dashboard

Operator
→ /operator/dashboard

Kabag Aset
→ /kabag/dashboard

Kadiv
→ /kadiv/dashboard

Staff Aset
→ /staff-aset/dashboard
```

---

# 13. Route Guard

Route guard memeriksa:

```text
Session
↓
Authentication
↓
Role
↓
Permission
```

Jika tidak memiliki akses:

```text
→ Redirect
```

Jangan hanya menyembunyikan tombol.

Security tetap harus diverifikasi backend.

---

# 14. Auth Repository

Interface:

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

Implementation awal dapat menggunakan mock repository jika backend belum tersedia.

---

# 15. Result Pattern

Gunakan abstraction untuk hasil operation.

Contoh konsep:

```text
Success<T>
Failure
```

Contoh:

```dart
Result<User>
```

sehingga UI tidak bergantung pada exception mentah.

---

# 16. Error Model

Minimal:

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

Semua failure memiliki mapping pesan UI.

---

# 17. Network Layer

Buat abstraction:

```text
core/network/

api_client.dart
api_response.dart
network_exception.dart
```

Responsibilities:

- base URL;
- request;
- response;
- timeout;
- authorization header;
- error mapping.

Feature tidak membuat HTTP client sendiri.

---

# 18. Environment

Buat:

```text
.env.example
```

Contoh:

```text
API_BASE_URL=
APP_ENV=development
```

Jangan commit credential asli.

Contoh:

```text
.env
```

harus masuk `.gitignore` jika digunakan untuk secret/local configuration.

---

# 19. Local Storage

Buat abstraction terlebih dahulu.

```text
core/storage/

secure_storage.dart
local_storage.dart
```

Secure storage:

```text
authentication token
session credential
```

Local database:

```text
offline mutation
cached data
sync queue
```

Database Drift belum perlu mengimplementasikan seluruh tabel pada tahap foundation.

---

# 20. Connectivity

Buat service abstraction:

```text
ConnectivityService
```

Minimal mampu memberikan:

```text
online
offline
```

UI dapat menampilkan:

```text
OfflineBanner
```

Tetapi business logic offline belum diimplementasikan pada foundation.

---

# 21. Mutation Foundation

Pada tahap setup, cukup buat domain enum:

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

Jangan membuat seluruh mutation workflow sebelum foundation selesai.

---

# 22. Testing Foundation

Setiap foundation component minimal harus dapat diuji.

Test:

```text
Auth state
Role mapping
Route guard
Status mapping
Theme
Validators
```

Minimal project harus dapat menjalankan:

```bash
flutter analyze
flutter test
```

tanpa error.

---

# 23. Git Strategy

Gunakan perubahan kecil.

Contoh:

```text
feat: initialize Flutter architecture
feat: add application theme
feat: add authentication foundation
feat: add role based routing
feat: add shared widgets
```

Jangan membuat satu commit:

```text
feat: complete MutasiKu application
```

untuk seluruh MVP.

---

# 24. Agent Development Rules

Sebelum coding:

```text
1. Read PRD.
2. Read DESIGN.md.
3. Read TECHNICAL-DESIGN.md.
4. Inspect existing project.
5. Identify current implementation.
6. Make smallest required change.
7. Run analyzer.
8. Run tests.
9. Report changed files.
```

Agent tidak boleh:

- mengganti architecture tanpa alasan;
- menghapus existing code tanpa pemeriksaan;
- membuat backend palsu seolah production;
- mengarang API;
- mengarang business rule;
- membuat status baru;
- mengubah design token;
- membuat role baru;
- memasukkan secret ke repository.

---

# 25. Initial Acceptance Criteria

Foundation dianggap berhasil jika:

- [ ] Flutter project dapat dijalankan.
- [ ] `main.dart` berhasil bootstrap.
- [ ] App root tersedia.
- [ ] Theme centralized.
- [ ] Design tokens tersedia.
- [ ] Login screen tersedia.
- [ ] Auth state tersedia.
- [ ] User role tersedia.
- [ ] Routing tersedia.
- [ ] Route guard skeleton tersedia.
- [ ] Error abstraction tersedia.
- [ ] Network abstraction tersedia.
- [ ] Storage abstraction tersedia.
- [ ] Connectivity abstraction tersedia.
- [ ] Shared widgets dasar tersedia.
- [ ] `flutter analyze` berhasil.
- [ ] `flutter test` berhasil.
- [ ] Tidak ada credential/secret hardcoded.

---

# 26. Setelah Foundation

Setelah acceptance criteria terpenuhi:

```text
PROJECT SETUP
      ✓
      ↓
AUTHENTICATION
      ↓
ROLE DASHBOARD
      ↓
ASSET
      ↓
MUTATION SUBMISSION
      ↓
VERIFICATION
      ↓
APPROVAL
      ↓
ASSET UPDATE
      ↓
CONFIRMATION
      ↓
NOTIFICATION
      ↓
OFFLINE SYNC
      ↓
ADMIN
      ↓
TESTING
```

**Status: FOUNDATION READY**