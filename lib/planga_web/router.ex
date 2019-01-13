defmodule PlangaWeb.Router do
  use PlangaWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Corsica, origins: "*")
  end

  # pipeline :api do
  #   plug(:accepts, ["json"])
  #   resources("/apps", AppController, except: [:new, :edit])
  #   resources("/users", UserController, except: [:new, :edit])
  #   resources("/message", MessageController, except: [:new, :edit])
  #   resources("/conversations", ConversationController, except: [:new, :edit])
  #   resources("/conversations_users", ConversationUsersController, except: [:new, :edit])
  # end

  scope "/", PlangaWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/example", PageController, :example)
    get("/example2", PageController, :example2)
    get("/private_example", PageController, :private_example)
    get("/", PageController, :index)
  end

  # Other scopes may use custom stacks.
  # scope "/api", PlangaWeb do
  #   pipe_through :api
  # end
end
