defmodule Product.ItemSupplier do
  use Ash.Resource,
    otp_app: :ashcrud,
    domain: Product,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]
  
  # use Product.Policies.OwnerPolicy

  postgres do
    table "item_suppliers"
    repo Ashcrud.Repo

    # Jika item atau supplier dihapus, maka relasi ini juga dihapus (cascade delete)
    references do
      reference :item, on_delete: :delete  # ✅ cascade delete
      reference :supplier, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :create, :destroy]
  end

  attributes do
    uuid_primary_key :id

    timestamps()
  end

  relationships do
    belongs_to :item, Product.Item do
      allow_nil? false
      attribute_type :integer
    end

    belongs_to :supplier, Product.Supplier do
      allow_nil? false
      attribute_type :integer
    end
  end

  identities do
    identity :unique_item_supplier, [:item_id, :supplier_id]
  end
  
  policies do
    # Admin memiliki akses penuh
    bypass actor_present() do
      authorize_if expr(^actor(:role) == :admin)
    end

    # Hanya pemilik item yang dapat membaca atau menghapus relasi supplier
    # Catatan: create tidak diinclude karena manage_relationship pada Item akan menggunakan authorize?: false
    policy action_type([:read, :destroy]) do
      authorize_if expr(^actor(:id) == item().user_id)
    end
  end
end
