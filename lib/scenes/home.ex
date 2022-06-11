defmodule GoveeScenic.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph

  import Scenic.Primitives
  # import Scenic.Components

  @text_size 24

  defmodule State do
    defstruct [:graph, :center_x, :center_y, :fill]
  end

  def init(scene, params, opts) do
    IO.inspect(opts, label: "opts (home.ex:17)")
    IO.inspect(params, label: "params (home.ex:18)")

    topic = Keyword.get(params, :topic)
    :ok = Phoenix.PubSub.subscribe(:govee_scenic_pubsub, to_string(topic))

    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {width, height} = scene.viewport.size

    center_x = width / 2
    center_y = height / 3
    fill = :yellow

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

    state = %State{graph: graph, center_x: center_x, center_y: center_y, fill: fill}

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

  def handle_info({:fill, fill}, scene) do
    IO.puts("#{inspect self()} updating fill!")
    %State{
      graph: graph,
      center_x: center_x,
      center_y: center_y
    } = state = scene.assigns.state

    graph =
      graph
      |> Graph.modify(:circle, bulb_circle_spec(fill))
      # |> Graph.modify(:rays, &render_rays(&1, {center_x, center_y}, :red))
      |> draw(:rays, fn g ->
        render_rays(g, {center_x, center_y}, fill)
      end)

    state = %State{state | graph: graph, fill: fill}

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph)

    {:noreply, scene}
  end

  def handle_info(info, scene) do
    IO.puts("ignore unhandled message: #{inspect info}")
    {:noreply, scene}
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
