defmodule Malarkey.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :body, :string
      add :likes_count, :integer
      add :repost_count, :integer

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
