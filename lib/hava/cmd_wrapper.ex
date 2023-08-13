defmodule Hava.CmdWrapper do
  @initial_timeout 20_000
  
  @moduledoc """
  This is a simple wrapper around special commands
    *- which does not have space in their tockes
    *- and also have their output in stderr 
  caution: it is not intended for general purpose usage
  """
  def run(cmd, duration_time \\0) do
    task = Task.async(fn ->
      port = Port.open({:spawn, cmd}, [:binary, :stderr_to_stdout, :exit_status])
      result = loop(port, "", duration_time)
      send(port, {self(), :close})
      result
    end)
    Task.await(task, @initial_timeout + duration_time + 1_000)
  end

  defp loop(port, result, duration_time) do
    receive do
      {^port, {:data, data}} ->
        loop(port, result <> data, duration_time)

      {^port, {:exit_status, 0}} ->
        {:ok, result}

      {^port, {:exit_status, 1}} ->
        {:error, result}
    after
      @initial_timeout + duration_time ->
        {:error, :timeout}
    end
  end
end
