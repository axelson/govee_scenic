defmodule GoveeScenic do
  @behaviour Govee.CommandExecutor
  alias GoveeScenic.Conn

  # def execute_command(%Conn{} = conn, command) do
  def execute_command(%Conn{} = conn, command) do
    IO.puts("broadcast! #{inspect(command)} to: #{to_string(conn.name)}")
    IO.inspect(conn, label: "conn (govee_scenic.ex:15)")
    Phoenix.PubSub.broadcast(:govee_scenic_pubsub, to_string(conn.name), command)
    # TODO: Don't hardcode
    # Phoenix.PubSub.broadcast(:govee_scenic_pubsub, "default_window", command)
  end

  def start_conn(view_port_name, window_name, device) do
    topic = window_name

    {:ok, view_port_pid} =
      GoveeScenic.ViewPortDynamicSupervisor.start_view_port(view_port_name, topic)

    {:ok, view_port} = GoveeScenic.get_viewport(view_port_pid)
    new_window(view_port, window_name, topic, device)
  end

  def stop_conn(conn) do
    IO.puts("Stopping!")
    # %GoveeScenic.Conn{
    #   device: %Govee.Device{
    #     # addr: #Address<01:26:12:41:50:3C>,
    #     att_client: nil,
    #     connection_status: :disconnected,
    #     type: :h6001
    #   },
    #   # driver_pid: #PID<0.919.0>,
    #   name: :govee_scenic_conn30_window,
    #   topic: :govee_scenic_conn30_window,
    #   view_port_name: :govee_scenic_conn30_view_port
    # }

    {:ok, view_port} = GoveeScenic.get_viewport(conn.view_port_name)
    IO.inspect(view_port, label: "view_port (govee_scenic.ex:53)")

    Scenic.ViewPort.stop_driver(view_port, conn.driver_pid)
    |> IO.inspect(label: "stop_driver (govee_scenic.ex:56)")

    Scenic.ViewPort.stop(view_port)
    |> IO.inspect(label: "stop view_port (govee_scenic.ex:59)")
  end

  def demo do
    device =
      Govee.Device.new!(
        type: :h6001,
        addr: Govee.Device.random_addr()
      )

    GoveeScenic.start_conn(:ac, :acc, device)
    GoveeScenic.publish({:fill, :blue})
    GoveeScenic.publish({:fill, :red}, "ac")
  end

  def get_viewport(view_port_name \\ :main_viewport) do
    Scenic.ViewPort.info(view_port_name)
  end

  def new_window(view_port, name, topic, device) do
    Scenic.ViewPort.set_root(view_port, GoveeScenic.Scene.Home, topic: to_string(name))

    case Scenic.ViewPort.start_driver(view_port, driver_opts(name)) do
      {:ok, driver_pid} ->
        {:ok,
         %Conn{
           device: device,
           driver_pid: driver_pid,
           name: name,
           topic: topic,
           view_port_name: view_port.name
         }}

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

  def start_view_port_old(name, topic) when is_atom(name) and is_atom(topic) do
    spec =
      Scenic.ViewPort.child_spec(
        name: name,
        size: {800, 600},
        theme: :dark,
        default_scene: {GoveeScenic.Scene.Home, topic: topic},
        drivers: []
        # drivers: [GoveeScenic.driver_opts(:aa)]
      )

    DynamicSupervisor.start_child(:govee_scenic_viewport_supervisor, spec)
  end

  def start_view_port(name, topic) when is_atom(name) and is_atom(topic) do
    Scenic.ViewPort.start(
      name: name,
      size: {800, 600},
      theme: :dark,
      default_scene: {GoveeScenic.Scene.Home, topic: topic},
      drivers: []
      # drivers: [GoveeScenic.driver_opts(:aa)]
    )
  end
end
