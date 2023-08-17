defmodule Hava.CmdWrapperImpl do
  require Logger
  alias Hava.CmdWrapper
  @behaviour CmdWrapper

  def run(cmd, timeout \\ 5_000) do
    task =
      Task.async(fn ->
        port = Port.open({:spawn, cmd}, [:binary, :stderr_to_stdout, :exit_status])
        result = loop(port, "", timeout)
        send(port, {self(), :close})
        result
      end)

    Task.await(task, timeout + 1_000)
  end

  defp loop(port, result, timeout) do
    receive do
      {^port, {:data, data}} ->
        loop(port, result <> data, timeout)

      {^port, {:exit_status, 0}} ->
        {:ok, result}

      {^port, {:exit_status, 1}} ->
        {:error, result}
    after
      timeout ->
        {:error, :timeout}
    end
  end
end
