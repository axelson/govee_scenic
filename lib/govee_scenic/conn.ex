# TODO: Rename to GoveeScenic.Device
defmodule GoveeScenic.Conn do
  use TypedStruct

  typedstruct enforce: true do
    field :driver_pid, pid()
    # Name has to be an atom because of scenic
    field :name, atom()
    # ViewPort name has to be an atom because of scenic
    field :view_port_name, atom()
    # Topic doesn't really have to be an atom
    field :topic, atom()
    # Do we really need this?
    field :device, Govee.Device.t()
  end
end

defimpl Govee.ConnBuilder, for: GoveeScenic.Conn do
  def build(govee_scenic_conn) do
    %Govee.Conn{
      name: to_string(govee_scenic_conn.name),
      raw_device: govee_scenic_conn
    }
  end
end
