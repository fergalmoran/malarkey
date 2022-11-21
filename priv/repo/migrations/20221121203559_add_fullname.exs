defmodule Robotter.Repo.Migrations.AddFullname do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :fullname, :string
    end
  end
end
