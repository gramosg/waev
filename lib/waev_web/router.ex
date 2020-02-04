defmodule WaevWeb.Router do
  use WaevWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WaevWeb do
    pipe_through :browser

    get "/", PageController, :index
    # index,edit,new,show,create,update
    resources "/exports", ExportsController, only: [:show]
  end

  # Other scopes may use custom stacks.
  # scope "/api", WaevWeb do
  #   pipe_through :api
  # end
end
