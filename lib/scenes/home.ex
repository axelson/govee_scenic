defmodule GoveeScenic.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias GoveeScenic.Scene.ErrorScene
  alias Govee.Command

  import Scenic.Primitives
  # import Scenic.Components

  @text_size 24
  @on_fill :yellow

  defmodule State do
    use TypedStruct

    typedstruct enforce: true do
      field :graph, Scenic.Graph.t()
      field :center_x, pos_integer()
      field :center_y, pos_integer()
      field :bulb_fill, Scenic.Color.t()
      field :ray_fill, Scenic.Color.t()
      # integer from 0 to 255
      field :brightness, integer()
    end
  end

  def init(scene, params, _opts) do
    IO.inspect(params, label: "params (home.ex:20)")

    if is_list(params) do
      case Keyword.fetch(params, :topic) do
        {:ok, topic} ->
          do_init(scene, topic)

        :error ->
          ErrorScene.render_error_scene(
            scene,
            ":topic not passed in params.\nReceived: #{inspect(params)}"
          )
      end
    else
      ErrorScene.render_error_scene(
        scene,
        "Params needs to be a list.\nReceived: #{inspect(params)}"
      )
    end
  end

  def do_init(scene, topic) do
    :ok = Phoenix.PubSub.subscribe(:govee_scenic_pubsub, to_string(topic))
    IO.inspect(to_string(topic), label: "Scene Subscribe to")

    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {width, height} = scene.viewport.size

    center_x = width / 2
    center_y = height / 3
    fill = @on_fill

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph(
        [
          rect_spec({width, height}),
          rect_spec({50, 70}, fill: :gray, t: {center_x - 50 / 2, center_y + 60}),
          bulb_circle_spec(fill, id: :circle, t: {center_x, center_y})
        ]
        |> List.flatten()
      )
      |> draw(:rays, fn g ->
        group(
          g,
          fn g ->
            render_rays(g, {center_x, center_y}, fill)
          end,
          id: :rays
        )
      end)

    state = %State{
      graph: graph,
      center_x: center_x,
      center_y: center_y,
      brightness: 255,
      bulb_fill: fill,
      ray_fill: fill
    }

    scene =
      scene
      |> push_graph(graph)
      |> assign(:state, state)

    {:ok, scene}
  end

  def handle_input(event, _context, scene) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, scene}
  end

  def handle_info(%Command{type: :turn_off}, scene) do
    scene = update_fills(scene, :gray, :black)

    scene = push_graph(scene, scene.assigns.state.graph)
    {:noreply, scene}
  end

  def handle_info(%Command{type: :turn_on}, scene) do
    scene = update_fills(scene, @on_fill, @on_fill)

    scene = push_graph(scene, scene.assigns.state.graph)
    {:noreply, scene}
  end

  def handle_info(%Command{type: :set_color, value: rgb} = command, scene) do
    IO.inspect(command, label: "command (home.ex:120)")
    # Convert an integer into separate rgb values:
    # https://stackoverflow.com/a/2262152/175830
    r = Bitwise.bsl(rgb, -16) |> Bitwise.&&&(255)
    g = Bitwise.bsl(rgb, -8) |> Bitwise.&&&(255)
    b = rgb |> Bitwise.&&&(255)
    fill = {:color_rgb, {r, g, b}}

    scene = update_fills(scene, fill, fill)
    scene = push_graph(scene, scene.assigns.state.graph)
    {:noreply, scene}
  end

  def handle_info(
        %Command{
          type: :set_white,
          value: white_value
        },
        scene
      ) do
    {:color_hsv, {h, s, _v}} = Scenic.Color.to_hsv(:white)
    v = white_value * 50 + 50

    # Workaround a bug in Scenic. Can be removed after
    # https://github.com/boydm/scenic/pull/274 is merged
    v = if v > 99.0, do: 99.0, else: v

    fill = {:color_hsv, {h, s, v}}
    scene = update_fills(scene, fill, fill)

    scene = push_graph(scene, scene.assigns.state.graph)
    {:noreply, scene}
  end

  def handle_info(
        %Command{
          type: :set_brightness,
          value: brightness
        },
        scene
      ) do
    scene =
      use_state(scene, fn state ->
        %State{state | brightness: brightness}
        |> render_graph()
      end)

    scene = push_graph(scene, scene.assigns.state.graph)
    {:noreply, scene}
  end

  def handle_info(info, scene) do
    Logger.info("ignore unhandled message: #{inspect(info)}")
    {:noreply, scene}
  end

  defp use_state(scene, fun) when is_function(fun, 1) do
    state = fun.(scene.assigns.state)
    assign(scene, :state, state)
  end

  defp update_fills(scene, bulb_fill, ray_fill) do
    use_state(scene, fn state ->
      %State{state | bulb_fill: bulb_fill, ray_fill: ray_fill}
      |> render_graph()
    end)
  end

  defp render_graph(%State{graph: graph} = state) do
    %State{
      brightness: brightness,
      bulb_fill: bulb_fill,
      center_x: center_x,
      center_y: center_y,
      ray_fill: ray_fill
    } = state

    bulb_hsl =
      Scenic.Color.to_hsl(bulb_fill)
      |> set_hsl_brightness(brightness)

    ray_hsl =
      Scenic.Color.to_hsl(ray_fill)
      |> set_hsl_brightness(brightness)

    graph =
      graph
      |> Graph.modify(:circle, bulb_circle_spec(bulb_hsl))
      |> draw(:rays, fn g ->
        render_rays(g, {center_x, center_y}, ray_hsl)
      end)

    %State{state | graph: graph}
  end

  defp set_hsl_brightness(hsl, brightness) do
    {:color_hsl, {h, s, l}} = hsl
    brightness_ratio = brightness / 255
    {:color_hsl, {h, s, l * brightness_ratio}}
  end

  defp render_rays(graph, {center_x, center_y}, fill) do
    {ray_length, ray_width} = {50, 15}

    interval = :math.pi() / 6
    rotations = Enum.map(-1..6, &(&1 * interval + :math.pi() / 12))

    Enum.reduce(rotations, graph, fn rotation, graph ->
      rect(graph, {ray_length, ray_width},
        fill: fill,
        t: {center_x - 175, center_y - ray_width / 2},
        rotate: rotation,
        pin: {center_x - 225, center_y - 200 + ray_width / 2}
      )
    end)
  end

  defp bulb_circle_spec(fill, opts \\ []) do
    opts = Keyword.merge(opts, fill: fill)
    Scenic.Primitives.circle_spec(90, opts)
  end

  def draw(graph, id, fun) do
    case Graph.get(graph, id) do
      [] ->
        fun.(graph)

      # Work around not being able to modify a group primitive
      # Bug: https://github.com/boydm/scenic/issues/27
      [%{module: Scenic.Primitive.Group}] ->
        graph = Graph.delete(graph, id)
        fun.(graph)

      [_] ->
        Graph.modify(graph, id, fn graph ->
          fun.(graph)
        end)
    end
  end
end
