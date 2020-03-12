defmodule BroadcasterTEST do
  use ExUnit.Case
  import Broadcaster

  setup do
    {:ok, pid} = start_link()
    {:ok, pid: pid}
  end

  # Some utility functions to help with the tests
  defp send_fn(message) do
    fn pid -> send(pid, message) end
  end

  defp receive_msg(data) do
    receive do
      {:hello, message} ->
        receive_msg(data, %{data | hello: message})

      {:add, message, from} ->
        new_data = %{data | list: data.list ++ [message]}
        receive_msg(new_data)

      {:query, origin, params} ->
        case params do
          {:hello} -> send(origin, {:hello, data.hello})
        end

        receive_msg(data)
    end
  end

  defp query_process(pid, query_params) do
    send(pid, {:query, self(), query_params})

    receive do
      {:hello, message} -> message
    end
  end

  test "keeps track of recipient pids", ctx do
    for _ <- 1..3 do
      rec_pid = spawn(fn -> receive_msg(%{list: []}) end)

      add_recipient(ctx[:pid], rec_pid)
    end

    assert List.length(recipients(ctx[:pid])) == 3
  end

  test "sends messages to all recipients", ctx do
    send_msg(ctx[:pid], send_fn({:hello, "world"}))
  end

  test "sends a message to a recipient", ctx do
    rec_pid = recipients(ctx[:pid], 0)
    send_msg(ctx[:pid], rec_pid, send_fn({:hello, "man"}))

    query_process(rec_pid, {:hello}) == "man"
  end

  test "sends different messages to different recipients", ctx do
    rec1_pid = recipients(ctx[:pid], 0)
    rec2_pid = recipients(ctx[:pid], 1)

    send_msg(ctx[:pid], [
      {rec1_pid, send_fn({:hello, "world"})},
      {rec2_pid, send_fn({:hello, "man"})}
    ])
  end

  test "adds an optional delay to a message", ctx do
    rec_pid = recipients(ctx[:pid], 2)
    send_msg(ctx[:pid], rec_pid, send_fn({:add, "world"}), %{delay: 3000})
    send_msg(ctx[:pid], rec_pid, send_fn({:add, "hello"}))
  end

  test "delivers messages while others have not been delivered", ctx do
  end

  test "fails a message delivery on purpose", ctx do
    rec_pid = recipients(ctx[:pid], 0)
    send_msg(ctx[:pid], rec_pid, send_fn({:hello, "world"}), %{fail: true})
  end
end
