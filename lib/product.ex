defmodule Product do
  use Ash.Domain,
    otp_app: :ashcrud

  authorization do
    authorize :by_default
  end

  resources do
    resource Product.Material
    resource Product.Item
  end
end
