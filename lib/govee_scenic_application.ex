defmodule GoveeScenicApplication do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    # load the viewport configuration from config
    main_view_port_config = Application.get_env(:govee_scenic, :viewport)

    # start the application with the viewport
    children =
      List.flatten([
        GoveeScenic.PubSub.Supervisor,
        {GoveeScenic.ViewPortDynamicSupervisor, name: :govee_scenic_viewport_supervisor},
        {Phoenix.PubSub, name: :govee_scenic_pubsub},
        {Scenic, [main_view_port_config]},
        live_reload(main_view_port_config)
      ])

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def live_reload(view_port_config) do
    if Code.ensure_loaded?(ScenicLiveReload) do
      [{ScenicLiveReload, viewports: [view_port_config]}]
    else
      []
    end
  end
end
