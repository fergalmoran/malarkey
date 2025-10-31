defmodule Malarkey.Repo.Migrations.AddMediaTypesToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :media_types, {:array, :string}, default: []
    end
  end
end
