defmodule DirectoryService.Repo.Migrations.CreateServer do
  use Ecto.Migration

  def change do
    create table(:servers) do
      add :host, :string
      add :file_count, :integer
      add :backup, :integer

      timestamps()
    end

  end
end