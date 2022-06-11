defmodule GoveeScenic do
  use TypedStruct

  @behaviour Govee.CommandExecutor

  defmodule Conn do
    typedstruct enforce: true do
      field :driver_pid, pid()
      field :name, atom()
    end
  end

  def execute_command(%Conn{} = conn, command) do
    Phoenix.PubSub.broadcast(:govee_scenic_pubsub, conn.name, command)
  end

  def run(window_name) when is_atom(window_name) do
    {:ok, viewport} = get_viewport()
    new_window(viewport, window_name)
  end

  def run2(view_port_name, window_name) do
    GoveeScenic.ViewPortDynamicSupervisor.start_view_port(view_port_name)
    {:ok, view_port} = GoveeScenic.get_viewport(view_port_name)
    res = new_window(view_port, window_name)

    %{view_port: view_port, res: res}
  end

  def demo do
    GoveeScenic.run2(:ac, :acc)
    GoveeScenic.publish({:fill, :blue})
    GoveeScenic.publish({:fill, :red}, "ac")
  end

  def get_viewport(view_port_name \\ :main_viewport) do
    Scenic.ViewPort.info(view_port_name)
  end

  def new_window(view_port, name \\ :default_window) do
    case Scenic.ViewPort.start_driver(view_port, driver_opts(name)) do
      {:ok, driver_pid} ->
        IO.inspect(name, label: "name (govee_scenic.ex:38)")
        {:ok, %Conn{driver_pid: driver_pid, name: name}}

      err ->
        err
    end
  end

  def publish(message, topic \\ "default_window") do
    Phoenix.PubSub.broadcast(:govee_scenic_pubsub, topic, message)
  end

  def driver_opts(name) when is_atom(name) do
    opts = [
      name: name,
      module: Scenic.Driver.Local,
      window: [resizeable: false, title: to_string(name)],
      on_close: :stop_system
    ]

    {:ok, [opts]} = Scenic.Driver.validate([opts])
    opts
  end
end

defmodule GoveeScenic.ViewPortDynamicSupervisor do
  use DynamicSupervisor

  def start_link(opts) do
    {name, opts} = Keyword.pop_first(opts, :name, nil)
    DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl DynamicSupervisor
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_view_port(name) when is_atom(name) do
    spec =
      Scenic.ViewPort.child_spec(
        name: name,
        size: {800, 600},
        theme: :dark,
        default_scene: {GoveeScenic.Scene.Home, topic: name},
        drivers: []
        # drivers: [GoveeScenic.driver_opts(:aa)]
      )

    DynamicSupervisor.start_child(:govee_scenic_viewport_supervisor, spec)
  end
end
