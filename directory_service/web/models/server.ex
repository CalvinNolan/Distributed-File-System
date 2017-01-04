defmodule DirectoryService.Server do
  use DirectoryService.Web, :model

  schema "servers" do
    field :host, :string
    field :file_count, :integer
    field :backup, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:host, :file_count, :backup])
    |> validate_required([:host, :file_count, :backup])
  end
end
