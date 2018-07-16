# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Repo.insert!(%Planga.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
# alias Planga.Repo
IO.inspect :mnesia.system_info(:is_running)

Planga.Repo.insert!(%Planga.Chat.App{
      id: 1,
      name: "tokener",
      api_key_pairs: [
        %Planga.Chat.APIKeyPair{public_id: "foobar", secret_key: <<42::128>>}
      ]
})
# wm = Repo.insert!(%Planga.Chat.User{name: "wm", remote_id: "1234", app_id: app.id})
# rene = Repo.insert!(%Planga.Chat.User{name: "rene", remote_id: "4567", app_id: app.id})

# IO.inspect app
# IO.inspect wm
# IO.inspect rene

# conv = Repo.insert!(%Planga.Chat.Conversation{remote_id: "asdf", app_id: app.id})


# wm
# |> Repo.preload(:conversations)
# |> Repo.preload(:app)
# |> change()
# |> put_assoc(:conversations, [conv])
# |> put_assoc(:app, app)
# |> Repo.update!


# rene
# |> Repo.preload(:conversations)
# |> Repo.preload(:app)
# |> change()
# |> put_assoc(:conversations, [conv])
# |> put_assoc(:app, app)
# |> Repo.update!
