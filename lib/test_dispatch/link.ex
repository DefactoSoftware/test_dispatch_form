defmodule TestDispatch.Link do
  @moduledoc false
  import TestDispatch.Form, only: [parse_conn: 1]
  import TestSelector.Test.FlokiHelpers

  def find_link(conn_or_floki_tree, test_selector, test_value \\ nil) do
    value = conn_or_floki_tree |> _find_link(test_selector, test_value) |> List.first()

    if is_nil(value),
      do: not_found_raise(test_selector, test_value),
      else: value
  end

  defp _find_link(conn_or_tree, test_selector, test_value \\ nil)

  defp _find_link(%Plug.Conn{} = conn, test_selector, test_value),
    do: conn |> parse_conn() |> _find_link(test_selector, test_value)

  defp _find_link(tree, test_selector, nil),
    do: tree |> Floki.find("a") |> find_test_selectors(test_selector)

  defp _find_link(tree, test_selector, test_value),
    do: tree |> _find_link(test_selector) |> find_test_values(test_value)

  defp not_found_raise(test_selector, nil) do
    raise("No `a` element found for just the selector #{inspect(test_selector)}")
  end

  defp not_found_raise(test_selector, test_value) do
    raise(
      "No `a` element found for selector #{inspect(test_selector)} with value #{
        inspect(test_value)
      }"
    )
  end
end
