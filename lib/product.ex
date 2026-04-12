defmodule Product do
  use Ash.Domain,
    otp_app: :ashcrud

  resources do
    resource Product.Material
    resource Product.Item
  end
end
