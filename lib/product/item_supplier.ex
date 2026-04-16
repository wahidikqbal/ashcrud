defmodule Product.ItemSupplier do
  use Ash.Resource,
    otp_app: :ashcrud,
    domain: Product,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "item_suppliers"
    repo Ashcrud.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:item_id, :supplier_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :item_id, :integer do
      allow_nil? false
    end

    attribute :supplier_id, :integer do
      allow_nil? false
    end
  end

  relationships do
    belongs_to :item, Product.Item do
      allow_nil? false
    end

    belongs_to :supplier, Product.Supplier do
      allow_nil? false
    end
  end

  identities do
    identity :unique_item_supplier, [:item_id, :supplier_id]
  end
end
