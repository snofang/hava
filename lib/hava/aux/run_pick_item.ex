defmodule Hava.Aux.RunPickItem do
  defstruct server_id: nil,
            speed: 0,
            duration: 0,
            after: 0

  @type t :: %__MODULE__{
          server_id: binary(),
          speed: float(),
          duration: non_neg_integer(),
          after: non_neg_integer()
        }
end
