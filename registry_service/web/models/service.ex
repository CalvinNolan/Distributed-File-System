defmodule RegistryService.Service do
  use RegistryService.Web, :model

  schema "services" do
    field :name, :string
    field :hostname, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :hostname])
    |> validate_required([:name, :hostname])
    |> unique_constraint(:name)
  end
end
