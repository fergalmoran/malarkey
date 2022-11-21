defmodule Robotter.TimelineFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Robotter.Timeline` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        body: "some body",
        likes_count: 42,
        repost_count: 42,
        username: "some username"
      })
      |> Robotter.Timeline.create_post()

    post
  end
end
