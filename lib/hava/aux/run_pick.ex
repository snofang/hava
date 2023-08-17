defmodule Hava.Aux.RunPick do
  alias Hava.Aux.RunPickItem

  defstruct servers: [],
            index: 0,
            receive: 0,
            duration: 0,
            send_required: 0,
            gap: 0,
            items: []

  @type t :: %__MODULE__{
          servers: list(%{server_id: binary(), speed: float()}),
          index: non_neg_integer(),
          receive: non_neg_integer(),
          duration: non_neg_integer(),
          send_required: non_neg_integer(),
          items: list(RunPickItem.t())
        }

  def new(servers, receive, duration) do
    %__MODULE__{
      servers: servers,
      receive: receive,
      duration: duration,
      gap: get_env(:max_call_gap),
      send_required: receive * get_env(:min_send_ratio)
    }
  end

  # def pick_uniform(servers, index, tx_amount, duration, picked_servers // []) do
  #   
  #   if duration <= 0 do
  #     picked_servers
  #   else
  #     current_server = Enum.at(servers, server_index)
  #
  #     pick_servers(
  #       %{
  #         servers: servers,
  #         server_index: Integer.mod(server_index + 1, length(servers))
  #       },
  #       receive - (current_server.speed * duration),
  #       duration,
  #       [current_server.server_id | selected_server_ids]
  #     )
  #   end
  # end

  def pick_next(%__MODULE__{} = run_pick) do
    server = Enum.at(run_pick.servers, run_pick.index)

    if(server.speed > 0) do
      %{
        run_pick
        | index: Integer.mod(run_pick.index + 1, length(run_pick.servers)),
          items:
            run_pick.items ++
              [
                %RunPickItem{
                  server_id: server.server_id,
                  speed: server.speed,
                  duration: get_env(:max_call_duration)
                }
              ]
      }
    else
      pick_next(%{
        run_pick
        | index:
            (run_pick.index + 1)
            |> Integer.mod(
              run_pick.servers
              |> length()
            )
      })
    end
  end

  def pick_on_max_call_gap(%__MODULE__{} = run_pick) when run_pick.gap <= 0 do
    run_pick
  end

  def pick_on_max_call_gap(%__MODULE__{} = run_pick) do
    count = (run_pick.duration / run_pick.gap) |> Float.ceil() |> trunc()

    if(run_pick.items |> length() < count) do
      run_pick |> pick_next() |> pick_on_max_call_gap()
    else
      run_pick
    end
  end

  # in mega byte
  def send_amount(%__MODULE__{} = run_pick) do
    run_pick.items
    |> Enum.reduce(0, fn item, acc -> item.speed * item.duration / 1_000 + acc end) 
    |> trunc()
    |> div(8)
  end

  def get_env(key), do: Application.get_env(:hava, :run_pick)[key]

  def pick_on_send_required(%__MODULE__{} = run_pick) do
    if(send_amount(run_pick) < run_pick.send_required) do
      run_pick |> pick_next() |> pick_on_send_required()
    else
      run_pick
    end
  end
end
