defmodule Malarkey.Giphy do
  @moduledoc """
  Client for Giphy API integration.
  """

  @api_key Application.compile_env(:malarkey, :giphy_api_key, "")
  @base_url "https://api.giphy.com/v1/gifs"

  @doc """
  Search for GIFs on Giphy.
  """
  def search(query, limit \\ 25, offset \\ 0) do
    params = %{
      api_key: @api_key,
      q: query,
      limit: limit,
      offset: offset,
      rating: "g",
      lang: "en"
    }

    case HTTPoison.get("#{@base_url}/search", [], params: params) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"data" => gifs}} ->
            {:ok, parse_gifs(gifs)}
          {:error, _} = error ->
            error
        end

      {:ok, %{status_code: status}} ->
        {:error, "Giphy API returned status #{status}"}

      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Get trending GIFs from Giphy.
  """
  def trending(limit \\ 25, offset \\ 0) do
    params = %{
      api_key: @api_key,
      limit: limit,
      offset: offset,
      rating: "g"
    }

    case HTTPoison.get("#{@base_url}/trending", [], params: params) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"data" => gifs}} ->
            {:ok, parse_gifs(gifs)}
          {:error, _} = error ->
            error
        end

      {:ok, %{status_code: status}} ->
        {:error, "Giphy API returned status #{status}"}

      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end

  # Private functions

  defp parse_gifs(gifs) do
    Enum.map(gifs, fn gif ->
      %{
        id: gif["id"],
        title: gif["title"],
        url: get_in(gif, ["images", "fixed_height", "url"]),
        preview_url: get_in(gif, ["images", "fixed_height_small", "url"]),
        width: get_in(gif, ["images", "fixed_height", "width"]),
        height: get_in(gif, ["images", "fixed_height", "height"])
      }
    end)
  end
end
