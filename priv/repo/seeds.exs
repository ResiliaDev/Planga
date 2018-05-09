# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Repo.insert!(%Plange.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Plange.Repo
import Ecto.Changeset

app = Repo.insert!(%Plange.Chat.App{name: "tokener", secret_api_key: "topsecret"})
wm = Repo.insert!(%Plange.Chat.User{name: "wm", remote_id: "1234"})
rene = Repo.insert!(%Plange.Chat.User{name: "rene", remote_id: "4567"})

IO.inspect wm
IO.inspect rene

conv = Repo.insert!(%Plange.Chat.Conversation{remote_id: "asdf"})


wm
|> Repo.preload(:conversations)
|> Repo.preload(:app)
|> change()
|> put_assoc(:conversations, [conv])
|> put_assoc(:app, app)
|> Repo.update!


rene
|> Repo.preload(:conversations)
|> Repo.preload(:app)
|> change()
|> put_assoc(:conversations, [conv])
|> put_assoc(:app, app)
|> Repo.update!
