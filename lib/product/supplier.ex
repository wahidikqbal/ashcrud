defmodule Product.Supplier do
  use Ash.Resource,
    otp_app: :ashcrud,
    domain: Product,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "suppliers"
    repo Ashcrud.Repo
  end

  actions do
    defaults [:read, :destroy, create: [:name], update: [:name]]
  end

  attributes do
    integer_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  identities do
    identity :unique_name, [:name]
  end

  relationships do
    many_to_many :items, Product.Item do
      through Product.ItemSupplier
      source_attribute_on_join_resource :supplier_id
      destination_attribute_on_join_resource :item_id
    end
  end
end
