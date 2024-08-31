# priv/repo/seeds.exs
alias Hello.Repo
alias Hello.User

admin_user_params = %{
  full_name: "Admin User",
  email: "admin@example.com",
  password: "adminpassword123",
  status: "approved",
  role: "administrator"
}

admin_user_changeset = User.changeset(%User{}, admin_user_params)

case Repo.insert(admin_user_changeset) do
  {:ok, _user} ->
    IO.puts("Administrator user created successfully.")

  {:error, changeset} ->
    IO.inspect(changeset.errors, label: "Failed to create administrator user")
end
