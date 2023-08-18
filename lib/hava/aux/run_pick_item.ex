defmodule Hava.Aux.RunPickItem do
  defstruct server_id: nil,
            server_index: 0,
            speed: 0,
            duration: 0,
            after: 0

  @type t :: %__MODULE__{
          server_id: binary(),
          server_index: non_neg_integer(),
          speed: float(),
          duration: non_neg_integer(),
          after: non_neg_integer()
        }
end
