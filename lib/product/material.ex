defmodule Product.Material do
  use Ash.Resource, otp_app: :ashcrud, domain: Product, data_layer: AshPostgres.DataLayer

  postgres do
    table "materials"
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
    has_many :items, Product.Item
  end

end
