defmodule Malarkey.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    # Users tokens for sessions, email confirmation, password reset
    create table(:users_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    # OAuth identities table
    create table(:oauth_identities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :provider_uid, :string, null: false
      add :provider_email, :string
      add :provider_login, :string
      add :provider_token, :text
      add :provider_meta, :map

      timestamps()
    end

    create index(:oauth_identities, [:user_id])
    create unique_index(:oauth_identities, [:provider, :provider_uid])
  end
end
