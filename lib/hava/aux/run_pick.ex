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

  def new(servers, receive, duration, start_from_index \\ 0) do
    %__MODULE__{
      index: start_from_index,
      servers: servers,
      receive: receive,
      duration: duration,
      gap: get_env(:max_call_gap),
      send_required: receive * get_env(:min_send_ratio)
    }
  end

  def pick_uniform(servers, receive, duration, start_from_index \\ 0) do
    new(servers, receive, duration, start_from_index)
    |> pick_on_max_call_gap()
    |> pick_on_send_required()
    |> adjust_pick_durations()
    |> adjust_pick_after()
  end

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
                  server_index: run_pick.index,
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
    |> Enum.reduce(0, fn item, acc -> item_byte_amount(item) + acc end)
  end

  def get_env(key), do: Application.get_env(:hava, :run_pick)[key]

  # the amount of byte picked item is gonna send
  @spec item_byte_amount(RunPickItem.t()) :: non_neg_integer()
  defp item_byte_amount(%RunPickItem{} = item),
    do: (item.speed * item.duration / 1_000 * 1024 * 1024 / 8) |> trunc()

  def pick_on_send_required(%__MODULE__{} = run_pick) do
    if(
      send_amount(run_pick) |> byte_to_kilobyte() <
        run_pick.send_required |> byte_to_kilobyte()
    ) do
      run_pick |> pick_next() |> pick_on_send_required()
    else
      run_pick
    end
  end

  def adjust_pick_durations(%__MODULE__{} = run_pick) do
    if(
      send_amount(run_pick) |> byte_to_kilobyte() >
        run_pick.send_required |> byte_to_kilobyte()
    ) do
      case decrease_duration(run_pick) do
        {:ok, run_pick} -> adjust_pick_durations(run_pick)
        {:error, _msg} -> run_pick
      end
    else
      run_pick
    end
  end

  defp item_duration_minimal(%RunPickItem{} = item), do: item.duration <= 1_000
  defp byte_to_kilobyte(byte), do: (byte / 1024) |> round()
  # decreases items durations by one second
  defp decrease_duration(%__MODULE__{} = run_pick) do
    if(run_pick.items |> List.first() |> item_duration_minimal()) do
      {:error, "items duraitons are at the bottom"}
    else
      {:ok,
       %{
         run_pick
         | items:
             run_pick.items
             |> Enum.map(fn item -> %{item | duration: item.duration - 1_000} end)
       }}
    end
  end

  def adjust_pick_after(%__MODULE__{} = run_pick) do
    pace = (run_pick.duration / (run_pick.items |> length())) |> round()

    {_, items} =
      run_pick.items
      |> Enum.reduce({0, []}, fn item, {index, items} ->
        {index + 1, [%{item | after: pace * index} | items]}
      end)

    %{run_pick | items: items |> Enum.reverse()}
  end

  # def get_max_send_item_index(%__MODULE__{} = run_pick) do
  #   {fournd_index, _max_send, _next_index} =
  #     run_pick.items
  #     |> Enum.reduce(
  #       {-1, Float.min_finite(), 0},
  #       fn item, {found_index, max_send, index} ->
  #         if(item.speed * item.duration > max_send) do
  #           {index, item.speed * item.duration, index + 1}
  #         else
  #           {found_index, max_send, index + 1}
  #         end
  #       end
  #     )
  #
  #   fournd_index
  # end
end
