defmodule FileService.File do
  use FileService.Web, :model

  schema "files" do
    field :owner_id, :integer
    field :filename, :string
    field :content_type, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:owner_id, :filename, :content_type])
    |> validate_required([:owner_id, :filename, :content_type])
    |> validate_length(:filename, min: 3)
    |> unique_constraint(:duplicate_ownership, name: :no_duplicate_file_ownership)
  end
end
