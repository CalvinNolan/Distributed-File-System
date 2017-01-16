defmodule LockService.Repo.Migrations.CreateLock do
  use Ecto.Migration

  def change do
    create table(:locks) do
      add :directory_file_id, :integer
      add :file_id, :integer
      add :lock_token, :string
      add :owner_id, :integer

      timestamps()
    end

  end
end
