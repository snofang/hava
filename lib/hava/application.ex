defmodule Hava.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias Hava.Compensator
  require Config

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Starts a worker by calling: Hava.Worker.start_link(arg)
        # {Hava.Worker, arg}
        {Task.Supervisor, name: Hava.TaskSupervisor}
      ]
      |> append_if(
        Application.get_env(:hava, Compensator)[:enabled],
        {Hava.Compensator}
      )
      |> append_if(
        Application.get_env(:hava, Inspector)[:enabled],
        {Hava.Inspector}
      )
      |> List.flatten()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hava.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp append_if(children, condition, child) do
    if condition do
      [children] ++ [child]
    else
      children
    end
  end
end
