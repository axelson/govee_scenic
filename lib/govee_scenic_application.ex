defmodule GoveeScenicApplication do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    # start the application with the viewport
    children =
      [
        GoveeScenic.PubSub.Supervisor,
        # Is this where I really want to start my viewports under?
        {GoveeScenic.ViewPortDynamicSupervisor, name: :govee_scenic_viewport_supervisor},
        {Phoenix.PubSub, name: :govee_scenic_pubsub},
        maybe_start_scenic()
      ]
      |> List.flatten()

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp maybe_start_scenic do
    main_viewport_config = Application.get_env(:govee_scenic, :viewport)

    if main_viewport_config do
      [
        {Scenic, [main_viewport_config]}
      ]
    else
      []
    end
  end
end
