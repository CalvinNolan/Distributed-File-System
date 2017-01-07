defmodule DirectoryService.Replication do
  use DirectoryService.Web, :model

  schema "replications" do
    field :file_id, :integer
    field :server_id, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:file_id, :server_id])
    |> validate_required([:file_id, :server_id])
  end
end
