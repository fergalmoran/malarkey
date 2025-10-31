defmodule MalarkeyWeb.Components.UI do
  @moduledoc """
  Shadcn-inspired UI components for Malarkey.

  These components follow the shadcn/ui design system adapted for Phoenix LiveView.
  """
  use Phoenix.Component

  @doc """
  Renders a button with shadcn styling.

  ## Examples

      <.ui_button>Click me</.ui_button>
      <.ui_button variant="outline">Outlined</.ui_button>
      <.ui_button variant="ghost">Ghost</.ui_button>
      <.ui_button size="lg">Large button</.ui_button>
  """
  attr :variant, :string, default: "default", values: ~w(default outline ghost destructive)
  attr :size, :string, default: "default", values: ~w(default sm lg icon)
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled type phx-click phx-disable-with phx-value-id phx-value-content)
  slot :inner_block, required: true

  def ui_button(assigns) do
    ~H"""
    <button
      class={[
        # Base styles
        "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
        # Variant styles
        variant_classes(@variant),
        # Size styles
        size_classes(@size),
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp variant_classes("default"),
    do: "bg-primary text-primary-foreground shadow hover:bg-primary/90"

  defp variant_classes("outline"),
    do:
      "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground"

  defp variant_classes("ghost"), do: "hover:bg-accent hover:text-accent-foreground"

  defp variant_classes("destructive"),
    do: "bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90"

  defp size_classes("default"), do: "h-9 px-4 py-2"
  defp size_classes("sm"), do: "h-8 rounded-md px-3 text-xs"
  defp size_classes("lg"), do: "h-10 rounded-md px-8"
  defp size_classes("icon"), do: "h-9 w-9"

  @doc """
  Renders a shadcn-styled input field.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :type, :string, default: "text"
  attr :class, :string, default: nil
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"
  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)
  slot :inner_block

  def ui_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> ui_input()
  end

  def ui_input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="flex items-center space-x-2">
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value="true"
        checked={@checked}
        class={[
          "peer h-4 w-4 shrink-0 rounded-sm border border-primary shadow focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
          @class
        ]}
        {@rest}
      />
      <label
        :if={@label}
        for={@id}
        class="text-sm font-medium leading-none text-foreground peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
      >
        <%= @label %>
      </label>
      <.ui_input_error :for={msg <- @errors}><%= msg %></.ui_input_error>
    </div>
    """
  end

  def ui_input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@id} class="block text-sm font-medium leading-6 text-foreground mb-2">
        <%= @label %>
      </label>
      <select
        id={@id}
        name={@name}
        class={[
          "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
          @class
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.ui_input_error :for={msg <- @errors}><%= msg %></.ui_input_error>
    </div>
    """
  end

  def ui_input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@id} class="block text-sm font-medium leading-6 text-foreground mb-2">
        <%= @label %>
      </label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "flex min-h-[60px] w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
          @class
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.ui_input_error :for={msg <- @errors}><%= msg %></.ui_input_error>
    </div>
    """
  end

  def ui_input(assigns) do
    ~H"""
    <div>
      <label :if={@label} for={@id} class="block text-sm font-medium leading-6 text-foreground mb-2">
        <%= @label %>
      </label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
          @class
        ]}
        {@rest}
      />
      <.ui_input_error :for={msg <- @errors}><%= msg %></.ui_input_error>
    </div>
    """
  end

  defp ui_input_error(assigns) do
    ~H"""
    <p class="mt-1 flex gap-1 text-sm leading-6 text-destructive">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 20 20"
        fill="currentColor"
        class="h-5 w-5 flex-none"
      >
        <path
          fill-rule="evenodd"
          d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-5a.75.75 0 01.75.75v4.5a.75.75 0 01-1.5 0v-4.5A.75.75 0 0110 5zm0 10a1 1 0 100-2 1 1 0 000 2z"
          clip-rule="evenodd"
        />
      </svg>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a shadcn-styled card.
  """
  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def ui_card(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "rounded-xl border bg-card text-card-foreground shadow",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a card header.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def ui_card_header(assigns) do
    ~H"""
    <div class={["flex flex-col space-y-1.5 p-6", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a card title.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def ui_card_title(assigns) do
    ~H"""
    <h3 class={["font-semibold leading-none tracking-tight", @class]}>
      <%= render_slot(@inner_block) %>
    </h3>
    """
  end

  @doc """
  Renders a card description.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def ui_card_description(assigns) do
    ~H"""
    <p class={["text-sm text-muted-foreground", @class]}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a card content area.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def ui_card_content(assigns) do
    ~H"""
    <div class={["p-6 pt-0", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a separator.
  """
  attr :class, :string, default: nil
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)

  def ui_separator(assigns) do
    ~H"""
    <div
      class={[
        "shrink-0 bg-border",
        @orientation == "horizontal" && "h-[1px] w-full",
        @orientation == "vertical" && "h-full w-[1px]",
        @class
      ]}
      role="separator"
    />
    """
  end

  @doc """
  Renders an alert with shadcn styling.
  """
  attr :variant, :string, default: "default", values: ~w(default destructive)
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def ui_alert(assigns) do
    ~H"""
    <div
      class={[
        "relative w-full rounded-lg border px-4 py-3 text-sm",
        @variant == "default" && "bg-background text-foreground",
        @variant == "destructive" &&
          "border-destructive/50 text-destructive dark:border-destructive [&>svg]:text-destructive",
        @class
      ]}
      role="alert"
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a badge with shadcn styling.
  """
  attr :variant, :string, default: "default", values: ~w(default secondary outline destructive)
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def ui_badge(assigns) do
    ~H"""
    <div
      class={[
        "inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
        badge_variant_classes(@variant),
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp badge_variant_classes("default"),
    do: "border-transparent bg-primary text-primary-foreground shadow hover:bg-primary/80"

  defp badge_variant_classes("secondary"),
    do: "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80"

  defp badge_variant_classes("outline"), do: "text-foreground"

  defp badge_variant_classes("destructive"),
    do: "border-transparent bg-destructive text-destructive-foreground shadow hover:bg-destructive/80"

  # Helper function to translate errors
  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
