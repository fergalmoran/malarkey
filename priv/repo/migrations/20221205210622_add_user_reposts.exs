defmodule Malarkey.Repo.Migrations.AddUserReposts do
  use Ecto.Migration

  def change do
    create table(:user_reposts, primary_key: false) do
      add(:post_id, references(:posts, on_delete: :delete_all), primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)
      timestamps()
    end

    create(index(:user_reposts, [:post_id]))
    create(index(:user_reposts, [:user_id]))

    create(unique_index(:user_reposts, [:user_id, :post_id], name: :user_reposts_unique_index))
  end
end
