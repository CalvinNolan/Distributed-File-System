defmodule DirectoryService.File do
  use DirectoryService.Web, :model
  @derive {Poison.Encoder, only: [:id, :uid, :owner_id, :owner_name, :filename, :updated_at]}
  schema "files" do
    field :uid, :integer
    field :owner_id, :integer
    field :owner_name, :string
    field :filename, :string
    field :server, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:uid, :owner_id, :owner_name, :filename, :server])
    |> validate_required([:uid, :owner_id, :owner_name, :filename, :server])
    |> validate_length(:filename, min: 3)
    |> unique_constraint(:duplicate_ownership, name: :no_duplicate_file_ownership)
  end
end
