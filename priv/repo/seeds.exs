# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Plange.Repo.insert!(%Plange.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Plange.Repo.insert!(%Plange.Chat.App{name: "tokener", secret_api_key: "topsecret"})
Plange.Repo.insert!(%Plange.Chat.User{name:"wm", remote_id: "1234"})
Plange.Repo.insert!(%Plange.Chat.User{name:"rene", remote_id: "4567"})
