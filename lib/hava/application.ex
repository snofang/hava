defmodule Hava.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger
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
        {Hava.Compensator, []}
      )
      |> append_if(
        Application.get_env(:hava, Inspector)[:enabled],
        {Hava.Inspector, []}
      )
      |> List.flatten()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hava.Supervisor]

    Logger.info(~s"""
      
    ---- HAVA (v#{Application.spec(:hava)[:vsn]}) Started ----
    HAVA_ENABLED=#{Application.get_env(:hava, Inspector)[:enabled]}
    HAVA_INTERFACE=#{Application.get_env(:hava, Inspector)[:usage_interface]}
    HAVA_INTERVAL=#{(Application.get_env(:hava, Inspector)[:interval] / 1_000) |> trunc()} (seconds)
    HAVA_MAX_CALL_GAP=#{(Application.get_env(:hava, :run_pick)[:max_call_gap] / 1_000) |> trunc()} (seconds)
    HAVA_MAX_CALL_DURATION=#{(Application.get_env(:hava, :run_pick)[:max_call_duration] / 1_000) |> trunc()} (seconds)
    HAVA_SEND_RATIO=#{Application.get_env(:hava, :run_pick)[:min_send_ratio]}
    HAVA_RECAP_RATIO=#{Application.get_env(:hava, Compensator)[:recap_ratio]}
    HAVA_KEEP_DURATION_BUSY=#{Application.get_env(:hava, :run_pick)[:keep_duration_busy]}
    ------------------------------------
      
    """)

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
