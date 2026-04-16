defmodule Product.ItemSupplier do
  use Ash.Resource,
    otp_app: :ashcrud,
    domain: Product,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "item_suppliers"
    repo Ashcrud.Repo
  end

  attributes do
    uuid_primary_key :id
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
