defmodule TestDispatch.FormTest do
  use TestDispatch.ConnCase

  describe "form with entity and empty form controls" do
    test "dispatches form with attributes", %{conn: conn} do
      attrs = %{
        name: "John Doe",
        email: "john@doe.com",
        description: "Just a regular joe",
        roles: ["admin", "moderator"],
        non_existing_field: "This will not show up in the params",
        color: "green",
        cats: [%{name: "Joe", age: 21}, %{name: "Jane", age: 8}]
      }

      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/new", %{form: "entity_and_form_controls"})
        |> dispatch_form(attrs, :user)

      assert html_response(dispatched_conn, 200) == "user created"

      assert params == %{
               "user" => %{
                 "name" => "John Doe",
                 "email" => "john@doe.com",
                 "description" => "Just a regular joe",
                 "roles" => ["admin", "moderator"],
                 "color" => "green",
                 "cats" => [%{"name" => "Joe", "age" => 21}, %{"name" => "Jane", "age" => 8}]
               }
             }
    end

    test "dispatches form with not all required attributes", %{conn: conn} do
      attrs = %{
        email: "john@doe.com",
        description: "Just a regular joe",
        roles: ["admin", "moderator"]
      }

      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/new", %{form: "entity_and_form_controls"})
        |> dispatch_form(attrs, :user)

      assert html_response(dispatched_conn, 200) == "not all required params are set"

      assert params == %{
               "user" => %{
                 "name" => nil,
                 "email" => "john@doe.com",
                 "description" => "Just a regular joe",
                 "roles" => ["admin", "moderator"],
                 "cats" => [%{"name" => nil, "age" => nil}, %{"name" => nil, "age" => nil}],
                 "color" => "red"
               }
             }
    end

    test "dispatches form without attributes", %{conn: conn} do
      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/new", %{form: "entity_and_form_controls"})
        |> dispatch_form(:user)

      assert html_response(dispatched_conn, 200) == "not all required params are set"

      assert params == %{
               "user" => %{
                 "name" => nil,
                 "email" => nil,
                 "description" => "",
                 "roles" => nil,
                 "cats" => [%{"name" => nil, "age" => nil}, %{"name" => nil, "age" => nil}],
                 "color" => "red"
               }
             }
    end

    test "dispatches form which is lacking the required form controls", %{conn: conn} do
      attrs = %{
        name: "John Doe",
        email: "john@doe.com",
        description: "Just a regular joe",
        roles: ["admin", "moderator"]
      }

      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/new", %{form: "lacking_required_form_controls"})
        |> dispatch_form(attrs, :user)

      assert html_response(dispatched_conn, 200) == "not all required params are set"

      assert params == %{
               "user" => %{
                 "description" => "Just a regular joe"
               }
             }
    end
  end

  describe "form with test_selector and empty form controls" do
    test "dispatches form with attributes",
         %{conn: conn} do
      attrs = %{
        name: "John Doe",
        email: "john@doe.com",
        description: "Just a regular joe",
        roles: ["admin"],
        non_existing_field: "This will not show up in the params"
      }

      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/new", %{form: "test_selector_and_form_controls"})
        |> dispatch_form(attrs, "new-user")

      assert html_response(dispatched_conn, 200) == "user created"

      assert params == %{
               "name" => "John Doe",
               "email" => "john@doe.com",
               "description" => "Just a regular joe",
               "roles" => ["admin"]
             }
    end

    test "dispatches form without attributes", %{conn: conn} do
      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/new", %{form: "test_selector_and_form_controls"})
        |> dispatch_form("new-user")

      assert html_response(dispatched_conn, 200) == "not all required params are set"

      assert params == %{
               "name" => nil,
               "email" => nil,
               "description" => "",
               "roles" => nil
             }
    end
  end

  describe "form with test_selector and no form controls" do
    test "dispatches form without attributes", %{conn: conn} do
      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/index")
        |> dispatch_form("export-users")

      assert html_response(dispatched_conn, 200) == "users exported"
      assert params == %{}
    end

    test "dispatches form and given attributes are ignored", %{conn: conn} do
      attrs = %{
        non_existing_field: "This will not show up in the params",
        another_one: "This one won't either"
      }

      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/index")
        |> dispatch_form(attrs, "export-users")

      assert html_response(dispatched_conn, 200) == "users exported"
      assert params == %{}
    end
  end

  describe "form without entity or test_selector and empty form controls" do
    test "dispatches the last form in the HTML response with attributes", %{conn: conn} do
      attrs = %{
        name: "John Doe",
        email: "john@doe.com",
        description: "Just a regular joe",
        roles: ["admin"],
        color: "green",
        non_existing_field: "This will not show up in the params"
      }

      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/new", %{form: "only_form_controls"})
        |> dispatch_form(attrs)

      assert html_response(dispatched_conn, 200) == "user created"

      assert params == %{
               "name" => "John Doe",
               "email" => "john@doe.com",
               "description" => "Just a regular joe",
               "roles" => ["admin"],
               "color" => "green"
             }
    end

    test "dispatches the last form in the HTML response without attributes", %{conn: conn} do
      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/new", %{form: "only_form_controls"})
        |> dispatch_form(%{})

      assert html_response(dispatched_conn, 200) == "not all required params are set"

      assert params == %{
               "name" => nil,
               "email" => nil,
               "description" => "",
               "roles" => nil,
               "color" => "red"
             }
    end
  end

  describe "form without entity or test_selector and no form controls" do
    test "dispatches the last form in the HTML response without attributes", %{conn: conn} do
      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/index")
        |> dispatch_form()

      assert html_response(dispatched_conn, 200) == "users exported"
      assert params == %{}
    end

    test "dispatches the last form in the HTML response and given attributes are ignored",
         %{conn: conn} do
      attrs = %{
        non_existing_field: "This will not show up in the params",
        another_one: "This one won't either"
      }

      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/index")
        |> dispatch_form(attrs)

      assert html_response(dispatched_conn, 200) == "users exported"
      assert params == %{}
    end
  end

  test "raise when trying to find a form by test_selector while there is none", %{conn: conn} do
    conn = get(conn, "/users/new", %{form: "only_form_controls"})

    assert_raise(
      RuntimeError,
      "No form found for the given test_selector or entity: new-user",
      fn ->
        dispatch_form(conn, "new-user")
      end
    )
  end

  test "raise when trying to find a form by entity while there is none", %{conn: conn} do
    conn = get(conn, "/users/new", %{form: "only_form_controls"})

    assert_raise(RuntimeError, "No form found for the given test_selector or entity: user", fn ->
      dispatch_form(conn, :user)
    end)
  end

  test "raise if no form is found in the HTML response", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.resp(200, "no form here")

    assert_raise(RuntimeError, "No form found for the given test_selector or entity: user", fn ->
      dispatch_form(conn, :user)
    end)
  end

  describe "form with entity AND test_selector" do
    test "use both the entity and selector to dispatch the right form", %{conn: conn} do
      attrs = %{
        name: "John Doe",
        email: "john@doe.com",
        description: "Just a regular joe",
        roles: ["admin", "moderator"],
        non_existing_field: "This will not show up in the params",
        color: "green"
      }

      %Plug.Conn{params: params} =
        dispatched_conn =
        conn
        |> get("/users/new", %{form: "multiple_selector_and_form_controls"})
        |> dispatch_form(attrs, :user, "user-profile")

      assert html_response(dispatched_conn, 200) == "not all required params are set"

      assert params == %{
               "id" => "1",
               "user" => %{
                 "description" => "Just a regular joe",
                 "email" => "john@doe.com",
                 "name" => "John Doe",
                 "roles" => ["admin", "moderator"]
               }
             }
    end
  end
end
