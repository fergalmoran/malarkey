defmodule Malarkey.Repo.Migrations.AddUserLikes do
  use Ecto.Migration

  def change do
    create table(:user_likes, primary_key: false) do
      add(:post_id, references(:posts, on_delete: :delete_all), primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)
      timestamps()
    end

    create(index(:user_likes, [:post_id]))
    create(index(:user_likes, [:user_id]))

    create(unique_index(:user_likes, [:user_id, :post_id], name: :user_likes_unique_index))
  end
end
