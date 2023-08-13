defmodule Hava.Compensator do
  use GenServer

  def init(_init_args) do
    {:ok, %{}}
  end

  def handle_cast(_receive, state) do
    {:noreply, state}
  end
  
  def handle_call(_receive, _from, %{speed: speed, time: time}) do
    {:noreply, %{speed: speed, time: time}}
  end

  def compensate(receive) do
    GenServer.cast(__MODULE__, receive)
  end
end
