# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Ashcrud.Repo.insert!(%Ashcrud.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Product.Material
alias Product.Supplier

materials = [
    "Material 1",
    "Material 2",
    "Material 3",
    "Material 4",
    "Material 5",
]

Enum.each(materials, fn name ->
  Material
  |> Ash.Changeset.for_create(:create, %{name: name})
  |> Ash.create!()
end)

IO.puts("Created #{length(materials)} materials")

suppliers = [
    "Supplier 1",
    "Supplier 2",
    "Supplier 3",
    "Supplier 4",
    "Supplier 5",
]

Enum.each(suppliers, fn name ->
  Supplier
  |> Ash.Changeset.for_create(:create, %{name: name})
  |> Ash.create!()
end)

IO.puts("Created #{length(suppliers)} suppliers")