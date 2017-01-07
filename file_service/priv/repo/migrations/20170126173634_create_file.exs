defmodule FileService.Repo.Migrations.CreateFile do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :owner_id, :integer
      add :filename, :string
      add :content_type, :string

      timestamps()
    end

    # create unique_index(:files, [:owner_id, :filename], name: :no_duplicate_file_ownership)
  end
end
