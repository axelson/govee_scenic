defmodule GoveeScenic.Scene.ErrorScene do
  use Scenic.Scene
  require Logger

  import Scenic.Primitives
  alias Scenic.Graph
  alias Scenic.ViewPort

  def init(scene, params, _opts) do
    error_message = Keyword.get(params, :error_message, "Unknown Error")
    Logger.warning("Displaying error: #{error_message}")
    {width, height} = scene.viewport.size
    center_x = width / 2
    center_y = height / 2

    graph =
      Graph.build(font: :roboto, font_size: 24)
      |> text(error_message, t: {center_x, center_y}, text_align: :center)

    scene = push_graph(scene, graph)

    {:ok, scene}
  end

  def render_error_scene(scene, error_message) when is_binary(error_message) do
    ViewPort.set_root(scene.viewport, __MODULE__, error_message: error_message)
  end
end
