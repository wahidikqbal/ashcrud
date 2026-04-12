defmodule Product.Item do
  use Ash.Resource, otp_app: :ashcrud, domain: Product, data_layer: AshPostgres.DataLayer

  postgres do
    table "items"
    repo Ashcrud.Repo
  end

  actions do
    defaults [:read, :destroy, create: [:name, :code, :material_id], update: [:name, :code, :material_id]]
  end

  attributes do
    integer_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :code, :string do
      public? true
    end

    attribute :material_id, :integer do
      public? true
    end

    timestamps()
  end

  identities do
    identity :unique_code, [:code]
  end

  relationships do
    belongs_to :material, Product.Material,
      allow_nil?: false,
      public?: true,
      attribute_type: :integer

    belongs_to :user, Ashcrud.Accounts.User,
      allow_nil?: false,
      public?: true,
      attribute_type: :uuid
  end

end
