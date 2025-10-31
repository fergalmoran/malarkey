defmodule MalarkeyWeb.Components.Avatar do
  use Phoenix.Component

  @doc """
  Renders a user avatar with fallback to initials.

  ## Examples

      <.avatar user={@user} size="sm" />
      <.avatar user={@user} size="md" />
      <.avatar user={@user} size="lg" />
      <.avatar user={@user} size="xl" />
  """
  attr :user, :map, required: true, doc: "The user struct containing avatar_url and username"
  attr :size, :string, default: "md", values: ["sm", "md", "lg", "xl"]
  attr :class, :string, default: "", doc: "Additional CSS classes"

  def avatar(assigns) do
    ~H"""
    <%= if @user.avatar_url do %>
      <img
        src={@user.avatar_url}
        alt={@user.username}
        class={[
          "rounded-full object-cover",
          size_class(@size),
          @class
        ]}
      />
    <% else %>
      <div class={[
        "rounded-full flex items-center justify-center font-semibold",
        "bg-gray-300 dark:bg-gray-600 text-gray-600 dark:text-gray-300",
        size_class(@size),
        @class
      ]}>
        <%= initial(@user) %>
      </div>
    <% end %>
    """
  end

  defp size_class("sm"), do: "w-8 h-8 text-xs"
  defp size_class("md"), do: "w-10 h-10 text-sm"
  defp size_class("lg"), do: "w-12 h-12 text-base"
  defp size_class("xl"), do: "w-16 h-16 text-xl"

  defp initial(user) do
    (user.display_name || user.username)
    |> String.first()
    |> String.upcase()
  end
end
