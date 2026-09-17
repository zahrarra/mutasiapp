# SKILLS.md — MutasiKu

## 1. Purpose

File ini mendefinisikan kemampuan/workflow yang digunakan AI coding agent ketika mengembangkan MutasiKu.

Skill harus digunakan sesuai kebutuhan task.

Agent tidak boleh menjalankan skill yang tidak relevan hanya untuk menambah kompleksitas.

---

# 2. Available Skills

```text
flutter-foundation
ui-implementation
authentication
rbac
asset-management
mutation-workflow
form-validation
api-integration
offline-sync
notification
testing
debugging
code-review
```

---

# 3. flutter-foundation

Digunakan untuk:

- Flutter project setup;
- folder architecture;
- application bootstrap;
- theme;
- routing;
- core services;
- dependency setup.

Workflow:

```text
Inspect
 ↓
Setup
 ↓
Analyze
 ↓
Test
```

Acceptance:

```text
flutter analyze ✓
flutter test ✓
```

---

# 4. ui-implementation

Digunakan untuk:

- screen;
- widget;
- form;
- card;
- status badge;
- dashboard;
- responsive mobile layout.

Wajib mengikuti:

```text
DESIGN.md
SCREEN-SPEC.md
```

Prioritas:

```text
Consistency
Readability
Accessibility
Operational clarity
```

Jangan membuat UI berdasarkan improvisasi jika spesifikasi sudah tersedia.

---

# 5. authentication

Digunakan untuk:

- login;
- logout;
- session;
- current user;
- token handling.

Flow:

```text
Login
 ↓
Authenticate
 ↓
Persist Session
 ↓
Load Current User
 ↓
Route by Role
```

Backend authentication mechanism belum final.

Karena itu authentication implementation harus menggunakan abstraction.

---

# 6. rbac

Digunakan untuk:

- role;
- permission;
- route guard;
- conditional action.

Roles:

```text
Admin
Pemohon
Operator
Kabag Aset
Kadiv
Staff Aset
```

Authorization final tetap dilakukan backend.

Flutter hanya menyediakan UX-level access control.

---

# 7. asset-management

Digunakan untuk:

- asset listing;
- asset detail;
- location;
- PIC;
- asset status;
- asset history.

Asset harus memiliki identity yang konsisten.

Jika asset sedang memiliki active mutation:

```text
Block new mutation
```

Authoritative validation tetap dilakukan backend.

---

# 8. mutation-workflow

Ini merupakan core skill MutasiKu.

Workflow:

```text
Pemohon Submit
      ↓
Ticket Generated
      ↓
Operator Verify
      ↓
Kabag Approve
      ↓
Kadiv Approve (conditional)
      ↓
Staff Aset Update
      ↓
Pemohon Confirm
      ↓
Selesai
```

Rejected:

```text
Verification rejected
→ Returned to applicant
```

```text
Approval rejected
→ Ditolak
```

Agent harus mengikuti status yang telah didefinisikan.

---

# 9. form-validation

Digunakan untuk:

- required field;
- format;
- invalid input;
- submit validation;
- server validation mapping.

Prinsip:

```text
Client Validation
+
Server Validation
```

Client validation tidak menggantikan server validation.

---

# 10. api-integration

Digunakan untuk:

- API client;
- repository;
- DTO;
- response mapping;
- error mapping.

Architecture:

```text
UI
 ↓
Provider
 ↓
Use Case
 ↓
Repository
 ↓
Data Source
 ↓
API
```

Dilarang:

```text
Widget
 ↓
HTTP Request
```

API contract harus berasal dari backend specification.

Jika endpoint belum tersedia:

```text
Use Mock Repository.
```

Jangan mengarang API seolah-olah final.

---

# 11. offline-sync

Digunakan untuk:

- local mutation;
- pending queue;
- connectivity;
- sync;
- retry;
- conflict.

Flow:

```text
Offline Submit
 ↓
Local Database
 ↓
Pending Sync
 ↓
Connection Restored
 ↓
Sync
 ↓
Server
```

Ticket final tetap dibuat server.

Conflict harus ditampilkan dengan jelas.

Jangan silent overwrite.

---

# 12. notification

Digunakan untuk:

- in-app notification;
- status updates;
- approval notification;
- returned submission;
- rejection;
- confirmation reminder.

Notification failure tidak boleh membatalkan mutation status update.

---

# 13. testing

Testing harus mencakup:

## Unit

```text
Use Cases
Validators
Status
Permission
Sync
```

## Widget

```text
Login
Forms
Status
Approval
Verification
Confirmation
```

## Integration

```text
Login
→ Submit
→ Verify
→ Approve
→ Update
→ Confirm
→ Complete
```

---

# 14. debugging

Workflow:

```text
Reproduce
 ↓
Read Error
 ↓
Identify Layer
 ↓
Find Root Cause
 ↓
Minimal Fix
 ↓
Test
```

Jangan langsung mengubah banyak file untuk menghilangkan error.

Jangan menutupi error dengan:

```dart
catch (_) {}
```

tanpa alasan.

---

# 15. code-review

Setiap review memeriksa:

```text
Architecture
Business Logic
Security
UI Consistency
Error Handling
Performance
Testing
```

Checklist:

```text
□ No duplicated business logic
□ No hardcoded secrets
□ No unnecessary dependency
□ No direct API from UI
□ No invented business rule
□ Existing components reused
□ Tests updated
```

---

# 16. Skill Selection Rule

Jika task:

```text
"buat login"
```

gunakan:

```text
authentication
rbac
ui-implementation
testing
```

Jika:

```text
"buat pengajuan mutasi"
```

gunakan:

```text
mutation-workflow
ui-implementation
form-validation
api-integration
testing
```

Jika:

```text
"buat offline submit"
```

gunakan:

```text
offline-sync
api-integration
testing
```

---

# 17. Skill Execution Rule

Skill harus:

1. membaca dokumentasi;
2. memeriksa kode existing;
3. membuat plan;
4. melakukan perubahan minimal;
5. menjalankan test;
6. melaporkan hasil.

---

# 18. Forbidden Behavior

Agent tidak boleh:

- mengarang business rule;
- mengarang API contract;
- mengarang role;
- mengubah workflow;
- menghapus feature tanpa alasan;
- membuat fake production backend;
- hardcode credentials;
- hardcode design tokens;
- bypass authorization;
- menganggap mock sebagai production;
- menyatakan selesai tanpa testing.

---

# 19. Skill Priority

Jika beberapa skill diperlukan:

```text
Business Requirement
        ↓
Architecture
        ↓
Feature Skill
        ↓
UI
        ↓
Testing
```

Contoh:

```text
Mutation Feature
      ↓
mutation-workflow
      ↓
api-integration
      ↓
ui-implementation
      ↓
testing
```

---

# 20. Final Rule

> **Skills are implementation procedures, not permission to invent requirements.**

Jika dokumentasi belum menentukan sesuatu:

```text
STOP
IDENTIFY OPEN QUESTION
ASK / REPORT
DO NOT INVENT
```