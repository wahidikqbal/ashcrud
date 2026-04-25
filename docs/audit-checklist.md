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

**Perbaikan Required:** Handle error case dengan redirect, bukan fallback ke user tanpa role.

| Status | File | Baris | Catatan |
|--------|------|-------|---------|
| ⬜ NOT STARTED | live_user_auth.ex | 17-26 | Perbaiki fallback error ke redirect |

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

### **M2. Material Resource Admin Access Not Enforced**
**Deskripsi:** Material policy mengizinkan read untuk semua authenticated user, dan routes tidak dalam admin-only live_session.

**Files:**
- `lib/product/material.ex` (policy)
- `lib/ashcrud_web/router.ex` (routes)

**Perbaikan Required:** Pilih salah satu:
- [ ] Opsi A: Pindahkan routes material ke admin-only live_session
- [ ] Opsi B: Ubah policy Material untuk restrict read ke admin saja

| Status | File | Catatan |
|--------|------|---------|
| ⬜ NOT STARTED | router.ex & material.ex | Belum dipaksakan akses admin |

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
| Critical | 2 | 1 | 1 | 0 |
| High | 3 | 0 | 3 | 0 |
| Medium | 4 | 0 | 4 | 0 |
| Low | 2 | 0 | 2 | 0 |
| **Total** | **11** | **1** | **10** | **0** |

---

## 📅 **ACTION LOG**

| Date | Issue | Action Taken | By |
|------|-------|--------------|-----|
| 2026-04-25 | C2. ItemSupplier bypass policy | Replaced bypass dengan policy admin + ownership check | Kilo |
| 2026-04-25 | - | Audit report created di `docs/audit2.md` | Kilo |
| 2026-04-25 | - | Checklist created di `docs/audit-checklist.md` | Kilo |

---

## 🎯 **NEXT STEPS**

1. **Segera (Critical + High):**
   - [ ] Fix C1: Tambahkan actor ke semua Ash actions di Supplier & Post LiveViews
   - [ ] Fix H1: Handle Ash.load failure di LiveUserAuth.on_mount
   - [ ] Fix H3: Move secrets ke environment variables

2. **Testing (High):**
   - [ ] Setup test skeleton untuk LiveView tests
   - [ ] Write policy tests untuk verify ownership works
   - [ ] Write autentikasi flow tests

3. **Scalability (Medium):**
   - [ ] Implement pagination di semua index
   - [ ] Enforce Material admin access

4. **Production Readiness:**
   - [ ] Review require_atomic? usage
   - [ ] Configure production email sender
   - [ ] Pin postgrex dependency

---

**Last Updated:** 25 April 2026  
**Audit Reference:** `docs/audit2.md`
