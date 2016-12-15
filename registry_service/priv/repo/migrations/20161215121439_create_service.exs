defmodule RegistryService.Repo.Migrations.CreateService do
  use Ecto.Migration

  def change do
    create table(:services) do
      add :name, :string
      add :hostname, :string

      timestamps()
    end
    create unique_index(:services, [:name])
  end
end
