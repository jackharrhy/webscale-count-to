defmodule Count.CountTo do
  use GenServer, restart: :temporary
  require Logger

  def log(message) do
    Logger.debug("CountTo #{inspect(self())}: #{message}")
  end

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init({socket, number}) do
    log("#{number} (#{inspect(socket)})")
    attempt(number)
    {:ok, {socket, 1}}
  end

  def attempt(number) do
    GenServer.cast(self(), {:attempt, number})
  end

  @impl true
  def handle_cast({:attempt, number}, {socket, attempts} = state) do
    log("attempt #{attempts} to reach #{number}")

    pids =
      1..number
      |> Enum.map(fn n ->
        {:ok, pid} = Count.Cell.start_link(n)
        pid
      end)

    forgor_any = Enum.any?(pids |> Enum.map(fn pid -> Count.Cell.forgor?(pid) end))

    if forgor_any do
      log("they forgor 💀")
      :gen_tcp.send(socket, "i forgor 💀 on attempt #{attempts}\n")
      attempt(number)
      pids |> Enum.map(&GenServer.stop(&1))
      {:noreply, {socket, attempts + 1}}
    else
      log("they remember")

      pids
      |> Enum.map(fn pid ->
        value = Count.Cell.get(pid)
        :gen_tcp.send(socket, "#{value}, ")
        :timer.sleep(250)
      end)

      pids |> Enum.map(&GenServer.stop(&1))

      :gen_tcp.send(socket, "done!\nonly took #{attempts} attempts :)\n")

      {:stop, :normal, state}
    end
  end

  @impl true
  def handle_info({:tcp, _socket, _data}, state), do: {:noreply, state}

  @impl true
  def handle_info({:tcp_closed, _socket}, state), do: {:stop, :normal, state}

  @impl true
  def handle_info({:tcp_error, _socket, reason}, state), do: {:stop, reason, state}
end
