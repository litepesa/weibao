defmodule Weibao.Repo do
  use Ecto.Repo,
    otp_app: :weibao,
    adapter: Ecto.Adapters.Postgres
end
