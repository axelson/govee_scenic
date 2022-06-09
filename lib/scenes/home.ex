defmodule GoveeScenic.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph

  import Scenic.Primitives
  # import Scenic.Components

  @text_size 24

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(scene, _param, _opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {width, height} = scene.viewport.size

    center_x = width / 2
    center_y = height / 3

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph(
        [
          rect_spec({width, height}),
          ray_specs({center_x, center_y}),
          rect_spec({50, 70}, fill: :gray, t: {center_x - 50 / 2, center_y + 60}),
          circle_spec(90, fill: :yellow, t: {center_x, center_y})
        ]
        |> List.flatten()
      )

    scene = push_graph(scene, graph)

    {:ok, scene}
  end

  def handle_input(event, _context, scene) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, scene}
  end

  defp ray_specs({center_x, center_y}) do
    {ray_length, ray_width} = {50, 15}

    interval = :math.pi / 6
    rotations = Enum.map(-1..6, & &1 * interval + :math.pi / 12)

    Enum.map(rotations, fn rotation ->
      rect_spec({ray_length, ray_width},
        fill: :yellow,
        t: {center_x - 175, center_y - ray_width / 2},
        rotate: rotation,
        pin: {center_x - 225, center_y - 200 + ray_width / 2}
      )
    end)
  end
end
