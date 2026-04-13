defmodule Product.Item do
  use Ash.Resource, 
    otp_app: :ashcrud,
    domain: Product,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  use Product.Policies.OwnerPolicy

  postgres do
    table "items"
    repo Ashcrud.Repo
  end

  actions do
    # Read dengan filter otomatis
    read :read do
      primary? true
      filter expr(user_id == ^actor(:id))
    end

    destroy :destroy do
      primary? true
    end

    create :create do
      accept [:name, :code, :material_id]
      change relate_actor(:user) # Set user_id otomatis dari actor yang sedang login
    end

    update :update do
      accept [:name, :code, :material_id]
      primary? true
    end
  end

  ## ATTRIBUTES
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

  ## POLICIES DIPINDAH KE Product.Policies.OwnerPolicy
  # policies do
  #   policy action_type(:read) do
  #     authorize_if relates_to_actor_via(:user)
  #   end

  #   policy action_type(:create) do
  #     authorize_if actor_present()
  #   end

  #   policy action_type(:update) do
  #     authorize_if relates_to_actor_via(:user)
  #   end

  #   policy action_type(:destroy) do
  #     authorize_if relates_to_actor_via(:user)
  #   end
  # end
end
