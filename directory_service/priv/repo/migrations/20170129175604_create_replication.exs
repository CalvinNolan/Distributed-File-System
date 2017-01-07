defmodule DirectoryService.Repo.Migrations.CreateReplication do
  use Ecto.Migration

  def change do
    create table(:replications) do
      add :file_id, :integer
      add :server_id, :integer

      timestamps()
    end

  end
end
