# Audit Report - Project AshCrud

## Ringkasan

Project ini adalah aplikasi CRUD menggunakan Ash Framework dengan Phoenix sebagai frontend. Terdapat 4 resource utama: `Product.Item`, `Product.Material`, `Blog.Post`, dan `Blog.Category`.

---

## Checklist Perbaikan

### 1. Keamanan - Authorization
- [ ] **Tambah authorizers user_id dan role**
    - Tambahkan user_id di Item agar item mempunyai relasi (kepemilikan) ke User
    - Tambahakn role du User (admin dan user)

- [ ] **Tambah authorizers ke Product.Item** (`lib/product/item.ex`)
  - Tambahkan `authorizers: [Ash.Policy.Authorizer]` di `use Ash.Resource`
  - Tambahkan policies untuk atur siapa yang bisa akses

- [ ] **Tambah authorizers ke Product.Material** (`lib/product/material.ex`)
  - Tambahkan `authorizers: [Ash.Policy.Authorizer]` di `use Ash.Resource`
  - Tambahkan policies untuk atur siapa yang bisa akses

- [ ] **Tambah policies ke Blog.Post** (`lib/blog/post.ex`)
  - Sama seperti Blog.Category, tambahkan policies untuk authorize_if actor_present()

contoh policy :
    policies do
        # ADMIN: bebas semua
        policy always() do
            authorize_if expr(actor.role == :admin)
        end

        # USER: ikut material
        policy action(:read) do
            authorize_if expr(material.user_id == actor.id)
        end

        policy action([:update, :destroy]) do
            authorize_if expr(material.user_id == actor.id)
        end

        policy action(:create) do
            authorize_if actor_present()
        end
    end

### 2. Validasi Data

- [ ] **Set allow_nil? false pada code** (`lib/product/item.ex`)
  - Tambahkan `allow_nil? false` pada attribute `code`
  - Ini mencegah duplikat saat code nil

- [ ] **Validasi return_to di route** (`lib/ashcrud_web/live/item_live/form.ex`)
  - Validasi nilai return_to agar hanya "index" atau "show"
  - Nilai default yang aman kalau invalid

### 3. Performa

- [ ] **Tambah pagination di Item Index** (`lib/ashcrud_web/live/item_live/index.ex`)
  - Ganti `Ash.read!` dengan pagination (limit/offset)
  - Contoh: `Ash.read!(Product.Item, limit: 20, offset: 0, ...)`

- [ ] **Tambah pagination di Material Index**
  - Sama seperti Item, tambahkan pagination

- [ ] **Tambah pagination di Category Index**
  - Sama seperti Item, tambahkan pagination

- [ ] **Tambah pagination di Post Index**
  - Sama seperti Item, tambahkan pagination

### 4. Bug Fixing

- [ ] **Load material saat edit Item** (`lib/ashcrud_web/live/item_live/form.ex:45`)
  - Tambahkan `load: [:material]` saat get item untuk edit
  - Agar material bisa diakses di template saat edit

- [ ] **Load material saat edit Material**
  - Jika ada relationship yang perlu di-load saat edit

### 5. Internationalization (i18n)

- [ ] **Ganti page title hardcoded dengan gettext** (`lib/ashcrud_web/live/*/`)
  - Ganti string seperti "New Item", "Edit Item" dengan `gettext("New Item")`

### 6. Route Safety

- [ ] **Tambah route constraint untuk id** (`lib/ashcrud_web/router.ex`)
  - Tambahkan constraint untuk memastikan id sesuai format (UUID/integer)
  - Mencegah konflik antara id dan "edit"

---

## Detail Masalah per File

### lib/product/item.ex

| Line | Masalah | Solusi |
|------|---------|--------|
| 2 | Tidak ada authorizers | Tambahkan `authorizers: [Ash.Policy.Authorizer]` |
| 21-23 | code nullable di identity | Tambahkan `allow_nil? false` di attribute code |

### lib/product/material.ex

| Line | Masalah | Solusi |
|------|---------|--------|
| 2 | Tidak ada authorizers | Tambahkan `authorizers: [Ash.Policy.Authorizer]` |

### lib/blog/post.ex

| Line | Masalah | Solusi |
|------|---------|--------|
| 2 | Tidak ada authorizers dan policies | Tambahkan authorizers dan policies seperti Category |

### lib/ashcrud_web/live/item_live/index.ex

| Line | Masalah | Solusi |
|------|---------|--------|
| 64 | Load semua data tanpa pagination | Tambahkan limit dan offset |

### lib/ashcrud_web/live/item_live/form.ex

| Line | Masalah | Solusi |
|------|---------|--------|
| 45 | Tidak load material saat edit | Tambahkan `load: [:material]` |
| 66-67 | return_to tidak divalidasi | Validasi dan fallback yang aman |

---

## Catatan Tambahan

1. **Consistency**: Blog.Category punya policies, Blog.Post tidak. Seharusnya konsisten.

2. **Error Handling**: Tidak ada penanganan error yang eksplisit di LiveView.

3. **Testing**: Belum ada test file untuk LiveView.

4. **Monitoring**: Consider add logging untuk audit trail.

---

## Referensi

- [Ash Documentation](https://ash-hq.org)
- [Ash Phoenix Documentation](https://ashphoenix.ash-hq.org)