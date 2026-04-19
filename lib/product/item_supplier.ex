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
    bypass always() do
      authorize_if always()
    end
  end
end
