defmodule Count do
  use Application

  @impl true
  def start(_type, _args) do
    Count.Supervisor.start_link(name: Count.Supervisor)
  end
end
