defmodule Count.Handler do
  require Logger

  def start() do
    {:ok, socket} =
      :gen_tcp.listen(6969, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port 6969")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Count.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    {:ok, data} = :gen_udp.recv(socket, 0)
    {count_to, _remainder} = Integer.parse(data)
    :inet.setopts(socket, active: true)

    {:ok, pid} =
      DynamicSupervisor.start_child(Count.DynamicSupervisor, {Count.CountTo, {socket, count_to}})

    :gen_tcp.controlling_process(socket, pid)
  end
end
