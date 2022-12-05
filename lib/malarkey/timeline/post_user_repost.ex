defmodule Malarkey.Timeline.PostUserRepost do
  use Ecto.Schema

  @primary_key false
  schema "user_reposts" do
    belongs_to :user, Malarkey.Accounts.User, primary_key: true
    belongs_to :post, Malarkey.Timeline.Post, primary_key: true
    timestamps()
  end
end
