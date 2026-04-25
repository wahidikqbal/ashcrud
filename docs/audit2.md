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

### 3.1 Analisis Policy

#### **Policy User** (`ashcrud/accounts/user.ex:260-265`)
- ✅ Benar-benar membatasi read ke admin atau diri sendiri
- ⚠️ Menggunakan `expr(^actor(:role) == :admin)` tapi role mungkin tidak ter-load kecuali diminta secara eksplisit (lihat di bawah)

**BUG KRITIS:** `actor(:role)` mengasumsikan actor memiliki field `role` yang sudah di-load. Di `live_user_auth.ex:22-25`, ada percobaan untuk load role:
```elixir
case Ash.load(user, [:role]) do
  {:ok, loaded_user} -> assign(socket, :current_user, loaded_user)
  _ -> {:cont, socket}  # ❌ Fallback ke user TANPA role!
end
```

Jika `Ash.load` gagal, role user tidak di-load, dan `actor(:role)` dalam policy akan menjadi `nil`, berpotensi membuka celah admin checks.

**Rekomendasi:** Ubah menjadi:
```elixir
case Ash.load(user, [:role]) do
  {:ok, loaded_user} -> {:cont, assign(socket, :current_user, loaded_user)}
  {:error, _} -> {:halt, redirect(socket, to: ~p"/sign-in")}
end
```

---

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
| 3 | Role loading failure bisa bypass admin checks | `live_user_auth.ex` | 30 mnt |
| 4 | Cakupan test minimal (<5%) | All | 16 jam+ |
| 5 | Hardcoded secrets di config | `dev.exs`, `test.exs` | 30 mnt |

### **Isu Prioritas Sedang**

| # | Isu | File | Effort |
|---|-----|------|--------|
| 6 | Tidak ada pagination pada listing resource | All index LiveViews | 4 jam |
| 7 | Akses Material resource admin tidak dipaksakan | `router.ex`, `material_live` | 1 jam |
| 8 | Dependency `postgrex` tidak dipin | `mix.exs` | 5 mnt |
| 9 | Email sender TODOs | Email sender modules | 15 mnt |

### **Prioritas Rendah / Nice-to-Have**

| # | Isu | File |
|---|-----|------|
| 10 | `require_atomic? false` bisa cause race conditions | `item.ex`, `user.ex` |
| 11 | Inline JavaScript di Layouts (`phx-click` dengan `JS.exec`) | `layouts.ex:155-166` |

---

## 13. RENCANA TINDAK LANJUT REKOMENDASI

### **Fase 1 - Perbaikan Keamanan (Segera)**
1. ✅ Tambahkan `actor: socket.assigns.current_user` ke semua aksi Ash di Supplier dan Post LiveViews
2. ✅ Perbaiki policy ItemSupplier untuk menegaskan minimal ownership checks
3. ✅ Perbaiki `LiveUserAuth.on_mount(:current_user)` untuk redirect saat load gagal

### **Fase 2 - Testing & Quality**
4. ✅ Tulis test integrasi untuk semua flow autentikasi
5. ✅ Tulis test policy untuk verifikasi otorisasi bekerja
6. ✅ Tulis test LiveView untuk operasi CRUD

### **Fase 3 - Skalabilitas**
7. ✅ Implementasi Ash pagination (keyset atau offset) untuk semua index pages
8. ✅ Review penggunaan `require_atomic? false` dan refactor jika memungkinkan
9. ✅ Tambah tuning database connection pooling jika perlu

### **Fase 4 - Production Readiness**
10. ✅ Pastikan semua secrets via environment variables
11. ✅ Review konfigurasi logging (sudah bagus)
12. ✅ Tambah monitoring (AppSignal/Scout/etc.)
13. ✅ Review error handling (gunakan `Ash.get` bukan `Ash.get!` di production)

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

**Tingkat Keamanan:** 🔴 **RISIKO TINGGI**  
**Kualitas Kode:** 🟡 **PERLU PEMBUANGAN**  
**Kesiapan Production:** 🔴 **BELUM SIAP**

Aplikasi mengandung **kerentanan bypass otorisasi kritis** yang memungkinkan user terautentikasi (atau bahkan tidak terautentikasi) untuk mengakses dan memodifikasi resource Supplier dan Post tanpa pemeriksaan kepemilikan atau role. Ini harus diperbaiki **SEBELUM deployment production apapun**.

Cakupan testing sangat rendah (<5%), membuat refactoring berisiko. Test komprehensif sangat diperlukan.

Codebase menunjukkan pemahaman yang baik tentang pola Ash Framework tapi ada celah di area kritis keamanan (actor passing, policy enforcement). Setelah isu kritis diperbaiki dan test ditambahkan, ini akan menjadi aplikasi yang solid.

---

**Audit selesai.**
