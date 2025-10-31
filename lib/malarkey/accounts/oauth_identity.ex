defmodule Malarkey.Accounts.OAuthIdentity do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "oauth_identities" do
    field :provider, :string
    field :provider_uid, :string
    field :provider_email, :string
    field :provider_login, :string
    field :provider_token, :string
    field :provider_meta, :map

    belongs_to :user, Malarkey.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(oauth_identity, attrs) do
    oauth_identity
    |> cast(attrs, [:provider, :provider_uid, :provider_email, :provider_login, :provider_token, :provider_meta, :user_id])
    |> validate_required([:provider, :provider_uid])
    |> unique_constraint([:provider, :provider_uid])
  end
end
