defmodule SocketConnectDisconnect.Repo do
  use Ecto.Repo,
    otp_app: :socketConnectDisconnect,
    adapter: Ecto.Adapters.Postgres
end
