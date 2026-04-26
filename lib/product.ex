defmodule Product do
  use Ash.Domain,
    otp_app: :ashcrud

  resources do
    resource Product.Material
    resource Product.Item
    resource Product.Supplier
    resource Product.ItemSupplier
  end

  authorization do
    authorize :by_default
  end
end
