defmodule Count.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Task.Supervisor, name: Count.TaskSupervisor},
      {DynamicSupervisor, name: Count.DynamicSupervisor},
      Supervisor.child_spec({Task, fn -> Count.Handler.start() end}, id: "handler")
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
