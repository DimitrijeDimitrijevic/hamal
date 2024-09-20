defmodule HamalWeb.Admin.UserController do
  use HamalWeb, :controller
  alias Hamal.Accounts

  def index(conn, _) do
    users = Accounts.get_users()
    render(conn, :index, users: users)
  end

  def new(conn, _) do
    user_changeset = Accounts.user_changeset()
    render(conn, :new, user_changeset: user_changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User #{user.username} created successfully!")
        |> redirect(to: ~p"/admin/users")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Please correct errors in inputs to continue!")
        |> render(:new, user_changeset: changeset)
    end
  end

  def edit(conn, %{"id" => user_id}) do
    user = Accounts.get_user!(user_id)
    user_changeset = Accounts.user_changeset(user)
    render(conn, :edit, user: user, user_changeset: user_changeset)
  end

  def update(conn, %{"id" => user_id, "user" => user_params}) do
    user = Accounts.get_user!(user_id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User #{user.username} updated successfully!")
        |> redirect(to: ~p"/admin/users")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Please correct errors in inputs!")
        |> render(:edit, user: user, user_changeset: changeset)
    end
  end

  def delete(conn, %{"id" => user_id}) do
    user = Accounts.get_user!(user_id)

    case Accounts.delete_user(user) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User #{user.username} deleted!")
        |> redirect(to: ~p"/admin/users")

      {:error, _} ->
        conn
        |> put_flash(:error, "Error deleting user #{user.username}!")
        |> redirect(to: ~p"/admin/users")
    end
  end
end
