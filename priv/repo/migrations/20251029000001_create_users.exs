defmodule Malarkey.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string
      add :username, :string, null: false
      add :display_name, :string
      add :bio, :text
      add :location, :string
      add :website, :string
      add :avatar_url, :string
      add :header_url, :string
      add :hashed_password, :string
      add :verified, :boolean, default: false
      add :followers_count, :integer, default: 0
      add :following_count, :integer, default: 0
      add :posts_count, :integer, default: 0
      add :confirmed_at, :naive_datetime

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
  end
end
