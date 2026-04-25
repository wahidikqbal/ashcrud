# AUDIT CHECKLIST - Ashcrud Project

Checklist ini digunakan untuk melacak status perbaikan dari audit yang dilakukan pada 25 April 2026.

---

## 🟦 **CRITICAL - HARUS PERBAIKI SEGERA**

### **C1. Authorization Bypass - Missing Actor Parameter**
**Deskripsi:** LiveViewsSupplier & Post tidak mengirim `actor` ke Ash actions, sehingga policy tidak dieksekusi.

**File Terkena:**
- `lib/ashcrud_web/live/supplier_live/index.ex` (baris 54, 59, 60)
- `lib/ashcrud_web/live/supplier_live/show.ex` (baris 39)
- `lib/ashcrud_web/live/supplier_live/form.ex` (baris 34)
- `lib/ashcrud_web/live/post_live/index.ex` (baris 73, 78, 79)
- `lib/ashcrud_web/live/post_live/show.ex` (baris 40)
- `lib/ashcrud_web/live/post_live/form.ex` (baris 37)

**Perbaikan Required:** Tambahkan `actor: socket.assigns.current_user` ke semua panggilan Ash.

| No | File | Baris | Status | Catatan |
|----|------|-------|--------|---------|
| C1.1 | supplier_live/index.ex | 54, 59, 60 | ⬜ NOT STARTED | stream/read/destroy tanpa actor |
| C1.2 | supplier_live/show.ex | 39 | ⬜ NOT STARTED | get! tanpa actor |
| C1.3 | supplier_live/form.ex | 34 | ⬜ NOT STARTED | get! tanpa actor |
| C1.4 | post_live/index.ex | 73, 78, 79 | ⬜ NOT STARTED | stream/read/destroy tanpa actor |
| C1.5 | post_live/show.ex | 40 | ⬜ NOT STARTED | get! tanpa actor |
| C1.6 | post_live/form.ex | 37 | ⬜ NOT STARTED | get! tanpa actor |

---

### **C2. Complete Policy Bypass - ItemSupplier**
**Deskripsi:** Policy `bypass always()` mengizinkan siapa pun mengakses join table.

**File:** `lib/product/item_supplier.ex:47-51`

**Status:** ✅ **FIXED** (11 Apr 2026)
**Perubahan:** 
- Mengganti bypass dengan policy admin + ownership check
- Admin: `bypass actor_present() authorize_if expr(^actor(:role) == :admin)`
- Owner: `authorize_if expr(^actor(:id) == item().user_id)`

---

## 🟥 **HIGH PRIORITY**

### **H1. Role Loading Failure Bypass Admin Checks**
**Deskripsi:** Jika `Ash.load(user, [:role])` gagal, role tidak di-load dan admin checks ter-bypass.

**File:** `lib/ashcrud_web/live_user_auth.ex:17-26`

**Perbaikan Required:** Handle error case dengan redirect ke sign-in, bukan fallback ke user tanpa role.

**Status:** ✅ **FIXED** (25 Apr 2026)
**Perubahan:**
- Ganti fallback `_ -> {:cont, socket}` dengan error handling
- Jika `Ash.load` gagal → clear session & redirect ke `/sign-in`
- Prevent bypass dengan memastikan role selalu ada untuk authenticated user

| Status | File | Baris | Catatan |
|--------|------|-------|---------|
| ✅ FIXED | live_user_auth.ex | 17-26 | Redirect jika role gagal di-load |

---

### **H2. Minimal Test Coverage (<5%)**
**Deskripsi:** Tidak ada test untuk LiveView, policies, autentikasi, atau integration.

**Files:** Seluruh codebase

**Perbaikan Required:**
- [ ] Test integrasi untuk LiveView CRUD (Items, Categories, Suppliers, Posts, Materials)
- [ ] Test policy untuk verification otorisasi (user vs admin, ownership)
- [ ] Test autentikasi flows (register, sign-in, password reset, confirmation)
- [ ] Test error handling

**Progress Tracking:**
| Domain | Test File | Status | Catatan |
|--------|-----------|--------|---------|
| Items | `test/ashcrud_web/live/item_live_test.exs` | ⬜ NOT STARTED | |
| Categories | `test/ashcrud_web/live/category_live_test.exs` | ⬜ NOT STARTED | |
| Suppliers | `test/ashcrud_web/live/supplier_live_test.exs` | ⬜ NOT STARTED | |
| Posts | `test/ashcrud_web/live/post_live_test.exs` | ⬜ NOT STARTED | |
| Materials | `test/ashcrud_web/live/material_live_test.exs` | ⬜ NOT STARTED | |
| Policies | `test/product/policy_test.exs` | ⬜ NOT STARTED | |
| Auth | `test/ashcrud_web/authentication_test.exs` | ⬜ NOT STARTED | |

---

### **H3. Hardcoded Secrets in Config**
**Deskripsi:** Secrets masih hardcoded di dev dan test config.

**Files:**
- `config/dev.exs:28` - `secret_key_base`
- `config/dev.exs:73` - `token_signing_secret`
- `config/test.exs:2` - `token_signing_secret`
- `config/test.exs:23` - `secret_key_base`

**Perbaikan Required:** Gunakan environment variables atau runtime.exs untuk semua environments.

| No | File | Baris | Status | Catatan |
|----|------|-------|--------|---------|
| H3.1 | config/dev.exs | 28 | ⬜ NOT STARTED | secret_key_base |
| H3.2 | config/dev.exs | 73 | ⬜ NOT STARTED | token_signing_secret |
| H3.3 | config/test.exs | 2 | ⬜ NOT STARTED | token_signing_secret |
| H3.4 | config/test.exs | 23 | ⬜ NOT STARTED | secret_key_base |

---

## 🟨 **MEDIUM PRIORITY**

### **M1. No Pagination on Resource Listings**
**Deskripsi:** Semua index LiveView menggunakan `Ash.read!` yang load semua records. Tidak scalable.

**Files:** Semua `*_live/index.ex`

**Perbaikan Required:** Implementasi Ash pagination (keyset atau offset).

| Resource | File | Status | Catatan |
|----------|------|--------|---------|
| Items | `item_live/index.ex` | ⬜ NOT STARTED | Sudah load semua dengan relationships |
| Categories | `category_live/index.ex` | ⬜ NOT STARTED | |
| Suppliers | `supplier_live/index.ex` | ⬜ NOT STARTED | |
| Posts | `post_live/index.ex` | ⬜ NOT STARTED | |
| Materials | `material_live/index.ex` | ⬜ NOT STARTED | |

---

### **M2. Material Resource Policy Adjusted (Read All Auth, Modify Admin-Only) ✅ FIXED**

**Deskripsi Awal:** Material menggunakan `AdminPolicy` yang membuat **read hanya admin**. Namun user biasa perlu membaca materials untuk dropdown di Item form. Selain itu, routes material belum dalam admin-only live_session.

**Solusi:**
1. **Policy Khusus di Material** (hapus `use AdminPolicy`):
   - `read`: semua user terautentikasi (`authorize_if actor_present()`)
   - `create/update/destroy`: hanya admin (`bypass` dengan `role == :admin`)
2. **Router:** Pindahkan material routes ke `admin_routes` live_session (dengan `RequireAdmin` on_mount)

**Hasil:**
- ✅ User biasa: bisa read materials (dropdown Item form)
- ✅ Admin: full access (bypass)
- ✅ Material management pages (index/show/edit) hanya admin yang bisa akses

**Files Modified:**
- `lib/product/material.ex` – custom policies inline
- `lib/ashcrud_web/router.ex` – material routes to admin-only session

**Status:** ✅ **FIXED** (25 Apr 2026)

| Status | File | Catatan |
|--------|------|---------|
| ✅ FIXED | product/material.ex | Policy: read all auth, C/U/D admin-only |
| ✅ FIXED | ashcrud_web/router.ex | Routes moved to admin_routes |

---

### **M3. Unpinned postgrex Dependency**
**Deskripsi:** `postgrex` menggunakan `>= 0.0.0` (unpinned) di `mix.exs`.

**File:** `mix.exs`

**Perbaikan Required:** Pin ke major version, misal: `{:postgrex, "~> 0.17"}`

| Status | File | Catatan |
|--------|------|---------|
| ⬜ NOT STARTED | mix.exs | Bisa cause breaking changes di CI |

---

### **M4. Email Sender TODOs**
**Deskripsi:** Email sender masih `noreply@example.com`.

**Files:**
- `lib/ashcrud/accounts/user/senders/send_new_user_confirmation_email.ex:16`
- `lib/ashcrud/accounts/user/senders/send_password_reset_email.ex:16`

**Perbaikan Required:** Konfigurasi email sender sebenarnya (Mailgun/SMTP/etc) untuk production, dan update dev config.

| Status | File | Catatan |
|--------|------|---------|
| ⬜ NOT STARTED | send_new_user_confirmation_email.ex | |
| ⬜ NOT STARTED | send_password_reset_email.ex | |

---

## 🟩 **LOW PRIORITY / NICE-TO-HAVE**

### **L1. Non-Atomic Operations May Cause Race Conditions**
**Deskripsi:** Dua instance menggunakan `require_atomic? false`.

**Files:**
- `lib/product/item.ex:49` (update action)
- `lib/ashcrud/accounts/user.ex:70` (change_password action)

**Review Required:** Evaluate jika atomic operation memungkinkan.

| Status | File | Action | Catatan |
|--------|------|--------|---------|
| ⬜ REVIEW NEEDED | item.ex | update :update | Cek apakah bisa atomic |
| ⬜ REVIEW NEEDED | accounts/user.ex | update :change_password | Kemungkinan aman, tapi review |

---

### **L2. Inline JavaScript in Layouts**
**Deskripsi:** `layouts.ex:155-166` menggunakan `JS.exec` dengan string concatenation untuk toggle sidebar mobile.

**File:** `lib/ashcrud_web/components/layouts.ex`

**Perbaikan Suggested:** Extract ke colocated hook untuk cleaner code.

| Status | File | Catatan |
|--------|------|---------|
| ⬜ OPTIONAL | layouts.ex | Tidak urgent, tapi bisa diabstraksi |

---

## 📋 **SUMMARY STATUS**

| Priority | Total | ✅ Fixed | ⬜ Not Started | 🚧 In Progress |
|----------|-------|---------|----------------|----------------|
| Critical | 2 | 1 (C2) | 1 (C1) | 0 |
| High | 3 | 1 (H1) | 2 (H2, H3) | 0 |
| Medium | 4 | 1 (M2) | 3 (M1, M3, M4) | 0 |
| Low | 2 | 0 | 2 | 0 |
| **Total** | **11** | **3** | **8** | **0** |

---

## 📅 **ACTION LOG**

| Date | Issue | Action Taken | By |
|------|-------|--------------|-----|
| 2026-04-25 | C2. ItemSupplier bypass policy | Replaced bypass dengan policy admin + ownership check | Kilo |
| 2026-04-25 | H1. Role loading failure | Fixed live_user_auth.ex: handle Ash.load error dengan redirect | Kilo |
| 2026-04-25 | M2. Material admin access | Moved routes to admin_routes live_session; fixed AdminPolicy (removed public read) | Kilo |
| 2026-04-25 | - | Audit report created di `docs/audit2.md` | Kilo |
| 2026-04-25 | - | Checklist created & updated di `docs/audit-checklist.md` | Kilo |

---

## 🎯 **NEXT STEPS**

### **Phase 1 - Security Fixes (SISA)**
1. ⬜ **C1. Fix Missing Actor Parameter** (12 locations)
   - Perbaiki `supplier_live/*.ex` (9 locations)
   - Perbaiki `post_live/*.ex` (6 locations)
   - **Effort:** 2 jam

2. ⬜ **H3. Hardcoded Secrets** (4 locations)
   - Pindah ke environment variables di dev & test
   - **Effort:** 30 mnt

### **Phase 2 - Testing & Quality**
3. ⬜ **H2. Comprehensive Test Coverage**
   - Test LiveView CRUD (Items, Categories, Suppliers, Posts, Materials)
   - Test policies (ownership, admin bypass)
   - Test auth flows (register, sign-in, reset, confirmation)
   - **Effort:** 16-40 jam

### **Phase 3 - Scalability**
4. ⬜ **M1. Implement Pagination**
   - All index pages (Items, Categories, Suppliers, Posts, Materials)
   - Gunakan Ash pagination (keyset recommended)
   - **Effort:** 4-8 jam

5. ⬜ **L1. Review Non-Atomic Operations**
   - Evaluate `item.ex:49` dan `user.ex:70`
   - **Effort:** 1 jam

### **Phase 4 - Production Readiness**
6. ⬜ **M3. Pin postgrex dependency**
   - Ubah di `mix.exs` ke `{:postgrex, "~> 0.17"}`
   - **Effort:** 5 mnt

7. ⬜ **M4. Configure Email Sender**
   - Update `*_email.ex` modules dengan configurable from address
   - Setup development mailbox config
   - **Effort:** 15 mnt

8. ⬜ **L2. Extract Inline JS** (optional)
   - Extract `layouts.ex` mobile sidebar JS ke colocated hook
   - **Effort:** 30 mnt

---

---

## 🐞 **POST-AUDIT BUGFIXES**

### **B1. Item Form Supplier Select Not Saved** ✅ FIXED
**Deskripsi:** Field select supplier di Item form tidak menyimpan dataecause using `field={@form[:supplier_ids]}` yang tidak ada, sehingga name attribute tidak ter-set dengan benar.

**File:** `lib/ashcrud_web/live/item_live/form.ex:33-40`

**Perbaikan:** Ganti dengan select input explicit dengan `name="item[supplier_ids][]"` dan tetap Gunakan mapping manual ke `suppliers`.

| Status | File | Catatan |
|--------|------|---------|
| ✅ FIXED | item_live/form.ex | Supplier select sekarang bisa menyimpan relasi |

---

### **B2. Item Creation fails with Forbidden (ItemSupplier policy)** ✅ FIXED

**Deskripsi:** Setelah B1 fixed, creating item masih gagal dengan error:
```
** (Ash.Error.Forbidden) Cannot use a filter to authorize a create.
Filter: actor_id == item.user_id
```

**Root Cause:**
- ItemSupplier policy menggunakan `expr(^actor(:id) == item().user_id)` untuk action `:create`
- Expression ini mereferensikan relationship `item().user_id` yang memerlukan DB query (filter) saat create
- Ash tidak mengizinkan filter expression pada create action (record belum ada)
- `manage_relationship` di Item secara default memicu policy check pada join resource (ItemSupplier) saat membuat join records

**Solution:**
1. **ItemSupplier policy** – remove `:create` dari policy tersebut (hanya `[:read, :destroy]`). Createjoin akan di-handle via parent Item dengan `authorize?: false`.
2. **Item `manage_relationship`** – tambahkan opsi `authorize?: false` untuk menonaktifkan policy check pada join records. 
   - Ini aman karena parent Item action sudah di-authorize via OwnerPolicy.
   - Join records hanya bisa dimodifikasi melalui Item yang sudah diotorisasi.

**Files Modified:**
- `lib/product/item_supplier.ex` – policy action type `[:read, :destroy]` only
- `lib/product/item.ex` – tambah `authorize?: false` pada `manage_relationship` (create & update actions)

**Result:** Item berhasil dibuat dengan suppliers, dan join records aman karena hanya pemilik item (atau admin) yang bisa mengubah melalui item.

| Status | File | Catatan |
|--------|------|---------|
| ✅ FIXED | item_supplier.ex | Policy: read & destroy only (create excluded) |
| ✅ FIXED | item.ex | manage_relationship dengan authorize?: false |

---

**Last Updated:** 25 April 2026
**Audit Reference:** `docs/audit2.md`
