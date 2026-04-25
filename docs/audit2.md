# AUDIT REPORT: Project Ashcrud

**Proyek:** Aplikasi Web Phoenix + Ash Framework  
**Tanggal Audit:** 25 April 2026  
**Versi Elixir:** ~> 1.15  
**Versi Phoenix:** ~> 1.8.5  

---

## 1. GAMBARAN UMUM

Ashcrud adalah aplikasi Phoenix yang menggunakan Ash Framework untuk manajemen sumber daya (resources). Fitur utama:

- **3 Ash Domain:** Product, Blog, Ashcrud.Accounts
- **Autentikasi:** AshAuthentication dengan password, magic link, reset password
- **Otorisasi:** Ash policies dengan role-based access (user/admin)
- **UI:** Phoenix LiveView dengan Tailwind CSS + daisyUI
- **Database:** PostgreSQL via AshPostgres

**Struktur Resource:**
```
Product Domain:   Material, Item, Supplier, ItemSupplier (join)
Blog Domain:      Post, Category
Accounts Domain:  User, Token
```

---

## 2. MASALAH KEAMANAN KRITIS

### 2.1 Authorization Bypass - PARAMETER ACTOR TIDAK DIPASangkan 🔴 KRITIS

**Tingkat:** KRITIS  
**Dampak:** Akses data yang tidak sah, eskalasi privilege

**Temuan:** Beberapa LiveView memanggil aksi Ash tanpa menyertakan parameter `actor`, sehingga melewati pengecekan otorisasi policy Ash sepenuhnya.

**File Terkena:**

| File | Baris | Masalah |
|------|-------|---------|
| `lib/ashcrud_web/live/supplier_live/index.ex` | 54, 59, 60 | `Ash.read!`, `Ash.get!`, `Ash.destroy!` tanpa actor |
| `lib/ashcrud_web/live/supplier_live/show.ex` | 39 | `Ash.get!` tanpa actor |
| `lib/ashcrud_web/live/supplier_live/form.ex` | 34 | `Ash.get!` tanpa actor |
| `lib/ashcrud_web/live/post_live/index.ex` | 73, 78, 79 | `Ash.read!`, `Ash.get!`, `Ash.destroy!` tanpa actor |
| `lib/ashcrud_web/live/post_live/show.ex` | 40 | `Ash.get!` tanpa actor |
| `lib/ashcrud_web/live/post_live/form.ex` | 37 | `Ash.get!` tanpa actor |

**Perbandingan dengan Kode yang Benar:**
LiveView lain (Item, Material, Category) benar-benar menyertakan `actor: socket.assigns.current_user`:
```elixir
# Pola benar (dari item_live/index.ex:82)
Ash.read!(Product.Item, load: [...], actor: socket.assigns[:current_user])

# Pola salah (dari supplier_live/index.ex:54)
Ash.read!(Product.Supplier)  # ❌ TIDAK ADA ACTOR
```

**Rekomendasi:**
Tambahkan parameter `actor` ke SEMUA panggilan aksi Ash:
```elixir
# Perbaikan untuk supplier_live/index.ex:54
stream(:suppliers, Ash.read!(Product.Supplier, actor: socket.assigns[:current_user]))

# Perbaikan untuk supplier_live/index.ex:59-60
supplier = Ash.get!(Product.Supplier, id, actor: socket.assigns.current_user)
Ash.destroy!(supplier, actor: socket.assigns.current_user)
```

---
### 2.2 Bypass Otentikasi Lengkap via Policy 🔴 KRITIS

**Fil
e:** `lib/product/item_supplier.ex:47-51`
```elixir
policies do
  bypass always() do
    authorize_if always()
  end
end
```

Policy ini secara efektif mengizinkan **SEMUA operasi oleh SINI who** tanpa pemeriksaan apapun. Join table harus setidaknya menegaskan bahwa user memiliki item terkait atau adalah admin.

**Rekomendasi:** Hapus bypass ini dan implementasikan pengecekan kepemilikan (ownership) yang benar.

---

### 2.3 Hardcoded Secrets di Development 🟡 SEDANG

**File:**
- `config/dev.exs:28` - `secret_key_base` hardcoded
- `config/dev.exs:73` - `token_signing_secret` hardcoded
- `config/test.exs:2` - `token_signing_secret` hardcoded
- `config/test.exs:23` - `secret_key_base` hardcoded

**Risiko:** Secrets ini dikomit ke version control. Meski dev/test tidak kritis, mereka menampilkan pola dan dapat disalahgunakan jika repo diakses.

**Rekomendasi:** Gunakan environment variables meski di dev/test, atau minimal tambahkan file-file ini ke `.gitignore` dan gunakan runtime configuration.

---

### 2.4 Konfigurasi CSRF Protection 🟢 OKE

`router.ex:13` menyertakan `plug :protect_from_forgery`. Baik.

Namun, `config/dev.exs:25` memiliki `check_origin: false` yang dapat diterima untuk development localhost tapi akan rentan di production jika tidak di-override di `prod.exs` (dan memang di-override - `prod.exs:13-20` mengkonfigurasi `force_ssl` dengan benar).

---

## 3. MASALAH POLICY & OTORISASI

### 3.1 Role Loading Failure - Admin Bypass 🔴 KRITIS

**Tingkat:** KRITIS  
**Dampak:** Admin checks dapat di-bypass jika role gagal di-load

**Temuan:** `LiveUserAuth.on_mount(:current_user)` memiliki fallback yang berbahaya:
```elixir
# Sebelum (baris 22-25)
case Ash.load(user, [:role]) do
  {:ok, loaded_user} -> assign(socket, :current_user, loaded_user)
  _ -> {:cont, socket}  # ❌ Fallback ke user TANPA role!
end
```

Jika `Ash.load` gagal, `actor(:role)` akan `nil` di policy checks, memungkinkan bypass admin checks.

**Status:** ✅ **FIXED** (25 Apr 2026)  
**Perbaikan:** `lib/ashcrud_web/live_user_auth.ex:22-27`
```elixir
case Ash.load(user, [:role]) do
  {:ok, loaded_user} -> {:cont, assign(socket, :current_user, loaded_user)}
  {:error, _} ->
    socket =
      socket
      |> put_flash(:error, "Sesi tidak valid, silakan login kembali")
      |> clear_session()
    {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
end
```

---

### 3.2 Material Resource - Read Access for All Authenticated ✅ FIXED

**Masalah Awal:** Material policy menggunakan `AdminPolicy` yang hanya mengizinkan admin read & modify. Namun user biasa perlu read materials untuk **dropdown di Item form**.

**Solusi:** Buat policy khusus di `Material` resource:

```elixir
policies do
  # Semua user terautentikasi dapat membaca material (untuk dropdown)
  policy action_type(:read) do
    authorize_if actor_present()
  end

  # Hanya admin yang dapat create/update/destroy
  bypass actor_present() do
    authorize_if expr(^actor(:role) == :admin)
  end
end
```

**Implications:**
- ✅ User biasa: bisa read materials (dropdown Item form)
- ✅ Admin: full access (bypass)
- ✅ Material LiveViews tetap admin-only (via `RequireAdmin` on_mount di router)
- 🔒 Create/Update/Delete tetap restricted ke admin

**Files Changed:**
- `product/material.ex` - custom policy (removed `use AdminPolicy`)
- `ashcrud_web/router.ex` - material routes di `admin_routes` session

**Status:** ✅ **FIXED** (25 Apr 2026)

### 3.2 Resource Khusus Admin: Material

`Material` menggunakan `AdminPolicy` yang:
- ✅ Hanya mengizinkan admin create/update/destroy
- ⚠️ Mengizinkan semua user terautentikasi untuk read

Cek router: routes material berada di dalam `:authenticated_routes` tapi TIDAK di dalam `live_session` admin-only. Komentar `admin_routes` menunjukkan ini sengaja tapi belum lengkap.

**Rekomendasi:** Pilih salah satu:
1. Pindahkan routes material ke `live_session` admin-only dengan plugin `RequireAdmin`
2. ATAU sesuaikan policy Material untuk membatasi read ke admin saja

---

## 4. KEAMANAN DATA & ATOMICITY

### 4.1 Operasi Non-Atomic

**Ditemukan 2 instance `require_atomic? false`:**

1. `product/item.ex:49` - Action update
2. `ashcrud/accounts/user.ex:70` - Action change password

**Risiko:** Update non-atomic dapat menyebabkan race condition ketika beberapa prosesupdate_record yang sama secara bersamaan. Ini dapat diterima untuk validasi kompleks yang membutuhkan multiple DB reads, tapi harus digunakan dengan hati-hati.

**Rekomendasi:** Tinjau apakah operasi atomic memang tidak mungkin. Untuk pergantian password, ini kemungkinan aman karena hanya update satu field (change sudah di-hash sebelumnya). Untuk update Item, pertimbangkan apakah update atomic memungkinkan.

---

## 5. KODE QUALITY & MAINTENANCE

### 5.1 TODOs yang Tertinggal

**File dengan TODOs belum ditangani:**
- `ashcrud/accounts/user/senders/send_new_user_confirmation_email.ex:16`
- `ashcrud/accounts/user/senders/send_password_reset_email.ex:16`

Keduanya berisi: `# TODO: Replace with your email`

**Risiko:** Email development akan dikirim dari `noreply@example.com`, yang mungkin diblokir atau dianggap spam.

**Rekomendasi:** Konfigurasi pengirim email yang sebenarnya di production dan update konfigurasi email dev/test.

---

### 5.2 Penamaan & Dokumentasi

- ✅ Good use of module attributes and descriptive names
- ⚠️ Bahasa Indonesia digunakan di beberapa pesan (`RequireAdmin.ex:11-17`) - acceptable untuk app lokal, tapi pertimbangkan i18n untuk penggunaan lebih luas
- ✅ Komentar ada dan membantu

---

## 6. TINGKAT TESTING

### 6.1 Cakupan Test Sangat Terbatas

**File Test:** 5 files  
**Total Baris Test:** ~36 baris

**Test Saat Ini:**
- `error_html_test.exs` - 2 test untuk halaman error
- `error_json_test.exs` - 2 test untuk JSON error
- `page_controller_test.exs` - 1 test untuk home page
- ❌ Tidak ada test LiveView
- ❌ Tidak ada test resource/action
- ❌ Tidak ada test autentikasi/otorisasi
- ❌ Tidak ada test integrasi

**Estimasi Cakupan:** < 5%

**Risiko:** Aplikasi tidak siap production tanpa test komprehensif.

**Rekomendasi:**
1. Buat test integrasi untuk setiap flow LiveView (operasi CRUD)
2. Tambah test policy untuk memverifikasi otorisasi bekerja
3. Test flow autentikasi (register, sign-in, password reset)
4. Gunakan helper `AshPhoenix.Test` untuk testing LiveView Ash

---

## 7. KONFIGURASI & DEPLOYMENT

### 7.1 Konfigurasi Keamanan

| Setting | Dev | Test | Prod | Status |
|---------|-----|------|------|--------|
| `debug_errors` | true | - | false | ✅ |
| `check_origin` | false | - | - | ⚠️ Lihat catatan |
| `force_ssl` | - | - | true | ✅ |
| `secret_key_base` | env | env | env | ✅ |
| `token_signing_secret` | hardcoded | hardcoded | env | ⚠️ |

**Catatan:** `check_origin: false` di dev acceptable, tapi pastikan `force_ssl` dengan `rewrite_on: [:x_forwarded_proto]` menangani proxy headers dengan benar di production.

### 7.2 Konfigurasi Database

- ✅ Pool size dikonfigurasi sesuai (`pool_size: 10` dev, `String.to_integer(POOL_SIZE)` prod)
- ✅ Ecto sandbox mode untuk tests
- ✅ PostgreSQL 16+ required
- ✅ Extensions terinstall: `citext`, `ash-functions`

**Kualitas Migrasi:**
- Migrasi auto-generated oleh Ash
- Foreign keys benar dengan `on_delete: :delete` di `item_suppliers` ✅
- Unique indexes pada field identity ✅

---

## 8. ASSET PIPELINE & FRONTEND

### 8.1 Tailwind CSS v4 ✅

`assets/css/app.css` menggunakan sintaks import Tailwind v4 yang benar:
```css
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../../lib/ashcrud_web";
```

✅ Tidak menggunakan `@apply` (sesuai guidelines)

### 8.2 JavaScript ✅

- `app.js` benar-benar mengimpor vendor dependencies
- Integrasi colocated hooks ada
- Konfigurasi LiveSocket menyertakan CSRF token
- Debug tools development dengan benar dibatasi

---

## 9. DEPENDENCIES & KERENTANAN

### 9.1 Audit Dependency

Jalankan `mix deps.audit` untuk cek kerentanan known. Dependency terkini:

| Dependency | Versi | Catatan |
|------------|-------|---------|
| `ash` | ~> 3.0 | Core framework - pastikan patch terbaru |
| `phoenix` | ~> 1.8.5 | Stabil |
| `ash_authentication` | ~> 4.0 | Cek security patches |
| `postgrex` | >= 0.0.0 | Tidak dipin - bisa cause instability CI |

⚠️ `postgrex` menggunakan `>= 0.0.0` (tidak dipin). Rekomendasikan pin ke major version untuk mencegah breaking changes.

---

## 10. PERFORMA & SKALABILITAS

### 10.1 Database Queries

- ✅ `stream/3` digunakan di LiveViews untuk pagination
- ❌ **Potensi N+1:** `Ash.read!(Product.Supplier)` tanpa load ( tapi Supplier tidak punya relationship kompleks)
- ⚠️ `ItemLive.Index` load semua relationship dengan `load: [:material, :suppliers, :user]` di setiap item - bisa berat

**Rekomendasi:** Pertimbangkan pagination via Ash's pagination features bukan `Ash.read!` semua.

### 10.2 Overhead Actor Loading

`LiveUserAuth.on_mount(:current_user)` load role untuk setiap request via `Ash.load(user, [:role])`. Karena role jarang berubah, pertimbangkan:
- Cache role di session/assigns
- Load via preload di authentication plug

---

## 11. ARSITEKTUR & STRUKTUR

### 11.1 Kekuatan
- Pemisahan domain yang bersih (Product, Blog, Accounts)
- Policy reuse via macro modules (`OwnerPolicy`, `AdminPolicy`)
- Struktur LiveView konsisten (index, show, form)
- Abstraksi component baik (CoreComponents)

### 11.2 Area Peningkatan
- **Separasi concerns:** Beberapa LiveView mixed view logic dengan data fetching - acceptable untuk app sederhana tapi pertimbangkan menggunakan `AshPhoenix.Form` exclusively
- **Error handling:** `Ash.get!`/`Ash.read!` menggunakan bang versions yang raise exceptions - pertimbangkan handle errors dengan `Ash.get`/`Ash.read`
- **Pagination:** Saat ini load ALL records untuk Suppliers, Posts, Categories - tidak akan scalable

---

## 12. RINGKASAN TEMUAN

### **Isu Kritis (Perbaikan Segera)**

| # | Isu | File Terkena | Effort |
|---|-----|--------------|--------|
| 1 | **Parameter actor tidak disertakan** - Bypass otorisasi | 6 LiveViews (Supplier, Post) | 2 jam |
| 2 | **Bypass policy lengkap** - ItemSupplier mengizinkan semua | `item_supplier.ex` | 1 jam |

### **Isu Prioritas Tinggi**

| # | Isu | File | Effort |
|---|-----|------|--------|
| 3 | Role loading failure bisa bypass admin checks | `live_user_auth.ex` | ✅ FIXED |
| 4 | Cakupan test minimal (<5%) | All | 16 jam+ |
| 5 | Hardcoded secrets di config | `dev.exs`, `test.exs` | 30 mnt |

### **Isu Prioritas Sedang**

| # | Isu | File | Effort |
|---|-----|------|--------|
| 6 | Tidak ada pagination pada listing resource | All index LiveViews | 4 jam |
| 7 | Material resource policy adjusted (read all auth, modify admin-only) | `router.ex`, `material.ex` | ✅ FIXED |
| 8 | Dependency `postgrex` tidak dipin | `mix.exs` | 5 mnt |
| 9 | Email sender TODOs | Email sender modules | 15 mnt |

### **Prioritas Rendah / Nice-to-Have**

| # | Isu | File |
|---|-----|------|
| 10 | `require_atomic? false` bisa cause race conditions | `item.ex`, `user.ex` |
| 11 | Inline JavaScript di Layouts (`phx-click` dengan `JS.exec`) | `layouts.ex:155-166` |

---

## 13. RENCANA TINDAK LANJUT REKOMENDASI

### **Fase 1 - Perbaikan Keamanan (SELESAI)**
1. ✅ Perbaiki policy ItemSupplier untuk menegaskan ownership checks (C2)
2. ✅ Perbaiki `LiveUserAuth.on_mount(:current_user)` redirect on error (H1)
3. ✅ Material resource: policy read all authenticated, admin-only C/U/D + admin-only routes (M2)

### **Fase 1 - PERLU LANJUT (BELUM SELESAI)**
4. ⬜ Tambahkan `actor: socket.assigns.current_user` ke semua aksi Ash di Supplier & Post LiveViews (C1)

### **Fase 2 - Testing & Quality**
5. ⬜ Tulis test integrasi untuk semua flow autentikasi
6. ⬜ Tulis test policy untuk verifikasi otorisasi bekerja
7. ⬜ Tulis test LiveView untuk operasi CRUD

### **Fase 3 - Skalabilitas**
8. ⬜ Implementasi Ash pagination (keyset atau offset) untuk semua index pages
9. ⬜ Review penggunaan `require_atomic? false` dan refactor jika memungkinkan
10. ⬜ Tambah tuning database connection pooling jika perlu

### **Fase 4 - Production Readiness**
11. ⬜ Pastikan semua secrets via environment variables
12. ⬜ Review konfigurasi logging (sudah bagus)
13. ⬜ Tambah monitoring (AppSignal/Scout/etc.)
14. ⬜ Review error handling (gunakan `Ash.get` bukan `Ash.get!` di production)

---

## 14. KESESUAIAN DENGAN PROJECT GUIDELINES

✅ **Phoenix v1.8 Guidelines** - Layouts.app digunakan dengan benar  
✅ **Tailwind v4** - Sintaks import benar, tidak ada `@apply`  
✅ **HEEx** - Interpolasi `{}` dan `<%= %>` digunakan dengan benar  
⚠️ **LiveView Streams** - Tidak digunakan di semua tempat (Supplier/Post masih pakai `@streams` dengan `phx-update="stream"` manual di template, tapi bekerja)  
✅ **Icons** - Menggunakan component `<.icon>`  
✅ **Session security** - CSRF protection aktif  
✅ **SQL Injection** - Semua query pakai Ash, aman  

---

## 15. PENILAIAN AKHIR

**Tingkat Keamanan:** 🟡 **RISIKO SEDANG** (1 kritikal repaired, 1 kritikal masih open)  
**Kualitas Kode:** 🟡 **PERLU PEMBUANGAN**  
**Kesiapan Production:** 🔴 **BELUM SIAP**

**Status Perbaikan Isu Kritis:**
- ✅ **C2. ItemSupplier bypass policy** - DIPERBAIKI (ownership + admin policy)
- ✅ **H1. Role loading failure** - DIPERBAIKI (redirect on error)
- ✅ **M2. Material admin access** - DIPERBAIKI (read all authenticated, C/U/D admin-only + admin routes)
- ⬜ **C1. Missing actor parameter** - **MASIH TERBUKA** (12 lokasi di Supplier & Post LiveViews)

Aplikasi masih mengandung **kerentanan authorization bypass** di Supplier & Post LiveViews (12 lokasi). Ini harus diperbaiki **SEBELUM deployment production**.

Cakupan testing sangat rendah (<5%), membuat refactoring berisiko. Test komprehensif sangat diperlukan.

Codebase menunjukkan pemahaman yang baik tentang pola Ash Framework. Setelah isu kritis terakhir (C1) diperbaiki dan test ditambahkan, ini akan menjadi aplikasi yang solid dan aman.

---

## 16. BUGFIXES - POST-AUDIT DISCOVERIES

### **16.1 Item Form Supplier Not Saved** ✅ FIXED

**Problem:** Supplier multi-select field di Item form tidak menyimpan data karena using `field={@form[:supplier_ids]}` yang tidak ada dalam Ash form, sehingga `name` attribute tidak ter-set dengan benar.

**File:** `lib/ashcrud_web/live/item_live/form.ex:33-40`

**Solution:** Ganti dengan select input explicit dengan `name="item[supplier_ids][]"`.

```heex
<.input
  type="select"
  label="Supplier"
  options={@suppliers}
  multiple
  value={@selected_supplier_ids}
  name="item[supplier_ids][]"
  id="item-supplier-ids"
/>
```

---

### **16.2 Item Creation Fails with Forbidden Error** ✅ FIXED

**Problem:** Setelah bugfix 16.1, item creation still fails with:
```
** (Ash.Error.Forbidden) Cannot use a filter to authorize a create.
Filter: "e13bbf74-f8f2-44e5-b809-913eea909568" == item.user_id
```

**Root Cause:** 
- `ItemSupplier` policy menggunakan `expr(^actor(:id) == item().user_id)` untuk action `:create`
- Policy ini references relationship `item().user_id` yang memerlukan DB query (filter)
- Ash tidak mengizinkan filter expression pada create action (karena record belum ada)
- `manage_relationship` di Item secara default **memicu policy check** pada join resource (ItemSupplier) saat membuat join records

**Solution:**
1. **ItemSupplier policy** – remove `:create` dari policy yang menggunakan `item().user_id`. Sekarang hanya `:read` dan `:destroy` yang dicek ownership.
2. **Item manage_relationship** – tambahkan opsi `authorize?: false` untuk menonaktifkan policy check pada join records. 
   - Ini aman karena parent Item action sudah di-authorize via OwnerPolicy.
   - Join records hanya bisa dimodifikasi melalui Item yang sudah diotorisasi.

**Files Modified:**
- `lib/product/item_supplier.ex:47-51` – policy action type dikurangi ke `[:read, :destroy]`
- `lib/product/item.ex:39-43` dan `56-60` – tambah `authorize?: false` pada `manage_relationship`

**Result:** Item dapat dibuat dengan suppliers tanpa error, dan join records aman karena hanya pemilik item (atau admin) yang bisa mengubah melalui item.

---

**Audit selesai.**  
**Last checklist update:** 25 April 2026
