defmodule Weibao.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :name, :string
    field :image, :string
    field :uid, :string
    field :phone_number, :string
    field :about_me, :string
    field :last_seen, :string
    field :created_at, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :phone_number, :image, :about_me, :last_seen, :created_at, :uid])
    |> validate_required([:name, :phone_number, :image, :about_me, :last_seen, :created_at, :uid])
    |> unique_constraint(:uid)
  end
end
