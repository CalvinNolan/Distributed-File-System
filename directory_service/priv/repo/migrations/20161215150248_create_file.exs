defmodule DirectoryService.Repo.Migrations.CreateFile do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :uid, :integer
      add :owner_id, :integer
      add :owner_name, :string
      add :filename, :string
      add :server, :string

      timestamps()
    end

    create unique_index(:files, [:uid, :owner_id, :filename], name: :no_duplicate_file_ownership)
  end
end
