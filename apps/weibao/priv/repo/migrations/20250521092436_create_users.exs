defmodule Weibao.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :phone_number, :string
      add :image, :string
      add :about_me, :text
      add :last_seen, :string
      add :created_at, :string
      add :uid, :string

      timestamps()
    end

    create unique_index(:users, [:uid])
  end
end
