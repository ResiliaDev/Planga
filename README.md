# Planga

Planga is the Chat-Service that is very easy to integrate with your existing application!

It is currently in a relatively early alpha-stage; check back soon for more information.

# Table of Contents

<!--ts-->
   * [Planga](#planga)
   * [Table of Contents](#table-of-contents)
   * [Using Planga](#using-planga)
      * [Back-end setup](#back-end-setup)
         * [What should I use for conversation_id?](#what-should-i-use-for-conversation_id)
         * [What is a SHA256-HMAC?](#what-is-a-sha256-hmac)
         * [How do I compute a SHA256-HMAC?](#how-do-i-compute-a-sha256-hmac)
            * [Ruby:](#ruby)
            * [PHP:](#php)
            * [NodeJS:](#nodejs)
            * [Elixir:](#elixir)
            * [Python2](#python2)
            * [Python3](#python3)
      * [Front-end setup](#front-end-setup)
         * [Example:](#example)
   * [Running Planga Yourself](#running-planga-yourself)

<!-- Added by: qqwy, at: 2018-07-13T17:21+02:00 -->

<!--te-->

# Using Planga

_This documentation is a work-in-progress!_



# Running Planga Yourself

1. Copy this repository
2. Install Erlang and Elixir
3. Install Elixir dependencies using `mix deps.get`
4. Create the Mnesia database using `mix do ecto.create, ecto.migrate, run priv/repo/seeds.exs`
5. Run the application using `mix phx.server` or with console using `iex -S mix. phx.server`
