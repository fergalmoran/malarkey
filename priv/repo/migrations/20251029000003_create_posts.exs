defmodule Malarkey.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :reply_to_id, references(:posts, type: :binary_id, on_delete: :nilify_all)
      add :repost_of_id, references(:posts, type: :binary_id, on_delete: :delete_all)
      add :quote_post_id, references(:posts, type: :binary_id, on_delete: :nilify_all)
      add :media_urls, {:array, :string}, default: []
      add :likes_count, :integer, default: 0
      add :reposts_count, :integer, default: 0
      add :replies_count, :integer, default: 0
      add :views_count, :integer, default: 0

      timestamps()
    end

    create index(:posts, [:user_id])
    create index(:posts, [:reply_to_id])
    create index(:posts, [:repost_of_id])
    create index(:posts, [:quote_post_id])
    create index(:posts, [:inserted_at])
  end
end
