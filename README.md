# Planga

Planga is the Chat-Service that is very easy to integrate with your existing application!

[Homepage](https://planga.io)

[![Planga](https://img.shields.io/badge/%F0%9F%98%8E%20planga-chat-ff00ff.svg)](http://www.planga.io/)
[![Planga Docs](https://img.shields.io/badge/planga-docs-lightgrey.svg)](http://www.planga.io/docs)


It is currently in a relatively early alpha-stage; check back soon for more information.



# Running Planga Yourself

1. Copy this repository
2. Install Erlang and Elixir
3. Install Elixir dependencies using `mix deps.get`
4. Create the Mnesia database using `mix do ecto.create, ecto.migrate, run priv/repo/seeds.exs`
5. Run the application using `mix phx.server` or with console using `iex -S mix phx.server`
