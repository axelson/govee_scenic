defmodule GoveeScenic do
  def run(window_name) when is_atom(window_name) do
    {:ok, viewport} = get_viewport()
    new_window(viewport, window_name)
  end

  def get_viewport(view_port_name \\ :main_viewport) do
    Scenic.ViewPort.info(view_port_name)
  end

  def new_window(view_port, name \\ :window3) do
    opts = [
      name: name,
      module: Scenic.Driver.Local,
      window: [resizeable: false, title: "govee_scenic"],
      on_close: :stop_system
    ]

    {:ok, [opts]} = Scenic.Driver.validate([opts])
    Scenic.ViewPort.start_driver(view_port, opts)
  end
end
