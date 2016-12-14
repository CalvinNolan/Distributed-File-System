defmodule SecurityService.Repo.Migrations.CreateAuthToken do
  use Ecto.Migration

  def change do
    create table(:auth_tokens) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :token, :string
      add :valid, :boolean

      timestamps
    end
    create unique_index(:auth_tokens, [:token])
  end
end
