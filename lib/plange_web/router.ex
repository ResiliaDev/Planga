defmodule PlangeWeb.Router do
  use PlangeWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Corsica, origins: "*"
  end

  pipeline :api do
    plug :accepts, ["json"]
    resources "/apps", AppController, except: [:new, :edit]
    resources "/users", UserController, except: [:new, :edit]
    resources "/message", MessageController, except: [:new, :edit]
    resources "/conversations", ConversationController, except: [:new, :edit]
    resources "/conversations_users", ConversationUsersController, except: [:new, :edit]

  end

  scope "/", PlangeWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PlangeWeb do
  #   pipe_through :api
  # end
end
