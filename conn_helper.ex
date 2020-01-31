defmodule DetroitWeb.TestHelpers.ConnHelper do
  @moduledoc """
  A module that contains functions that makes writing tests easier.
  """
  @form_methods ["post", "put", "delete", "get"]

  import DetroitWeb.TestHelpers.ViewHelpers,
    only: [attribute: 2, attribute: 3, parse_fragment: 1, find_test_selector: 2]

  import Phoenix.ConnTest, only: [dispatch: 5, html_response: 2]
  alias DetroitWeb.Endpoint

  @spec post_form_with(
          %Plug.Conn{},
          %{required(atom()) => term()} | binary,
          String.t() | atom() | nil
        ) ::
          %Plug.Conn{}
  def post_form_with(conn, attrs_or_test_selector, entity \\ nil)

  def post_form_with(%Plug.Conn{} = conn, %{} = attrs, entity)
      when is_binary(entity) or is_nil(entity) or is_atom(entity) do
    form = find_form(conn, entity)
    entity = to_string(entity)

    form
    |> find_inputs(entity)
    |> Enum.map(&input_to_tuple(&1, entity))
    |> update_input_values(attrs)
    |> prepend_entity(entity)
    |> send_to_action(form, conn)
  end

  def post_form_with(%Plug.Conn{} = conn, test_selector, nil) do
    form = find_form(conn, nil, test_selector)
    send_to_action(%{}, form, conn)
  end

  def find_inputs(form, "") do
    fields = find_input_fields(form, "")
    selects = find_selects(form, "")

    Enum.uniq(fields ++ selects)
  end

  def find_inputs(form, entity), do: find_input_fields(form, entity)

  defp find_selects(form, _), do: Floki.find(form, "select")

  defp find_input_fields(form, ""),
    do:
      form
      |> Floki.filter_out("input[type=hidden]")
      |> Floki.find("input")

  defp find_input_fields(form, entity), do: Floki.find(form, "*[id^=#{entity}_]")

  defp prepend_entity(attrs, ""), do: attrs
  defp prepend_entity(attrs, entity), do: %{entity => attrs}

  defp update_input_values(list, attrs),
    do:
      Enum.reduce(list, %{}, fn {key, value}, acc ->
        Map.put(acc, key, Map.get(attrs, key, value))
      end)

  defp input_to_tuple(input, entity), do: input |> elem(0) |> _input_to_tuple(input, entity)

  defp _input_to_tuple("textarea", input, entity) do
    key = key_for_input(input, entity)
    value = Floki.text(input)

    {key, value}
  end

  defp _input_to_tuple("select", input, entity) do
    key = key_for_input(input, entity)
    value = input |> Floki.find("option[selected=selected]") |> attribute("value")

    {key, value}
  end

  defp _input_to_tuple("input", input, entity) do
    value = attribute(input, "value")
    key = key_for_input(input, entity)

    {key, value}
  end

  defp send_to_action(params, form, conn) do
    action = attribute(form, "action")
    method = get_method_of_form(form)

    dispatch(conn, Endpoint, method, action, params)
  end

  defp get_method_of_form(form),
    do:
      form
      |> attribute("input[name=_method]", "value")
      |> downcase
      |> method(form)

  defp method(method, _) when method in @form_methods, do: method
  defp method(_, form), do: attribute(form, "method") || "post"

  defp downcase(nil), do: nil
  defp downcase(string), do: String.downcase(string)

  defp key_for_input(input, entity) do
    input
    |> attribute("id")
    |> String.replace_leading("#{entity}_", "")
    |> String.to_atom()
  end

  defp find_form(%Plug.Conn{status: status} = conn, nil) do
    conn
    |> html_response(status)
    |> parse_fragment()
    |> Floki.find("form")
    |> List.last()
  end

  defp find_form(%Plug.Conn{status: status} = conn, entity) when status in 200..299 do
    conn
    |> html_response(status)
    |> parse_fragment()
    |> Floki.find("form")
    |> Enum.find(fn form ->
      form
      |> Floki.find("*[id^=#{entity}_]")
      |> Enum.any?()
    end)
  end

  defp find_form(%Plug.Conn{status: status}, _),
    do:
      raise(
        Plug.BadRequestError,
        "The provided conn had the status #{status} that doesn't fall into the 2xx range"
      )

  defp find_form(%Plug.Conn{status: status} = conn, nil, test_selector) when status in 200..299 do
    conn
    |> html_response(status)
    |> parse_fragment()
    |> Floki.find("form")
    |> Enum.find(&find_test_selector(&1, test_selector))
  end
end
