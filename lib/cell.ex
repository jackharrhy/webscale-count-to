defmodule Count.Cell do
  use GenServer, restart: :temporary
  require Logger

  def log(message) do
    Logger.debug("Cell #{inspect(self())}: #{message}")
  end

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def forgor?(pid) do
    GenServer.call(pid, :forgor?)
  end

  @impl true
  def init(value) do
    stored_value =
      if :rand.uniform() > 0.25 do
        value
      else
        "i forgor 💀"
      end

    log("given #{stored_value}, i think")

    {:ok, stored_value}
  end

  @impl true
  def handle_call(:get, _from, value) do
    {:reply, value, value}
  end

  @impl true
  def handle_call(:forgor?, _from, value) do
    {:reply, value === "i forgor 💀", value}
  end
end
