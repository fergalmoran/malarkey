defmodule Robotter.Repo do
  use Ecto.Repo,
    otp_app: :robotter,
    adapter: Ecto.Adapters.Postgres
end
