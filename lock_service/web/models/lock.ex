defmodule LockService.Lock do
  use LockService.Web, :model
  @derive {Poison.Encoder, only: [:directory_file_id, :file_id, :lock_token]}
  schema "locks" do
    field :directory_file_id, :integer
    field :file_id, :integer
    field :lock_token, :string
    field :owner_id, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:directory_file_id, :file_id, :lock_token, :owner_id])
    |> validate_required([:directory_file_id, :file_id, :lock_token, :owner_id])
  end
end
