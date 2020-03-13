defmodule BroadcasterTest do
  use ExUnit.Case
  import Broadcaster

  setup do
    # Broadcaster server PID
    {:ok, pid} = start_link() 
    
    init_state = %{msg: "", list: []}
    for _ <- 1..3 do
      rec_pid = spawn(fn -> receive_msg(init_state) end)

      add_recipient(pid, rec_pid)
    end

    {:ok, pid: pid}
  end

  # Some utility functions to help with the tests
  defp send_fn(message) do
    fn pid -> send(pid, message) end
  end

  defp receive_msg(data) do
    receive do
      {:msg, message} ->
        receive_msg(%{data | msg: message})

      {:add, message} ->
        new_data = %{data | list: data.list ++ [message]}
        receive_msg(new_data)

      {:query, origin, params} ->
        case params do
          :msg -> send(origin, {:msg, data.msg})
          :list -> send(origin, {:list, data.list})
        end

        receive_msg(data)
    end
  end

  defp query_process(pid, query_params) do
    send(pid, {:query, self(), query_params})

    receive do
      {:msg, message} -> message
      {:list, list} -> list
    end
  end

  test "keeps track of recipient pids", ctx do
    assert length(recipients(ctx.pid)) == 3
  end

  test "sends messages to all recipients", ctx do
    send_msg(ctx.pid, send_fn({:msg, "hello world"}))

    for rec_pid <- recipients(ctx.pid) do
      assert query_process(rec_pid, :msg) == "hello world"
    end
  end

  test "sends a message to a recipient", ctx do
    rec_pid = recipients(ctx.pid, 0)
    send_msg(ctx.pid, rec_pid, send_fn({:msg, "hello man"}))

    assert query_process(rec_pid, :msg) == "hello man"
  end

  test "sends different messages to different recipients", ctx do
    rec1_pid = recipients(ctx.pid, 0)
    rec2_pid = recipients(ctx.pid, 1)

    send_msg(ctx.pid, [
      {rec1_pid, send_fn({:msg, "how are you?"})},
      {rec2_pid, send_fn({:msg, "i'm fine"})}
    ])

    assert query_process(rec1_pid, :msg) == "how are you?"
    assert query_process(rec2_pid, :msg) == "i'm fine"
  end

  test "adds an optional delay to a message", ctx do
    rec_pid = recipients(ctx.pid, 2)
    send_msg(ctx.pid, rec_pid, send_fn({:add, "world"}), %{delay: 3000})
    send_msg(ctx.pid, rec_pid, send_fn({:add, "hello"}))

    # check the ordering of list... since "world" has a delayed delivery,
    # it should be last
    assert query_process(rec_pid, :list) == ["hello", "world"]
  end

  test "delivers messages asynchronously", ctx do
    rec1_pid = recipients(ctx.pid, 0)
    rec2_pid = recipients(ctx.pid, 1)

    send_msg(ctx.pid, rec1_pid, send_fn({:msg, "life is good"}), %{delay: 3000})
    send_msg(ctx.pid, rec2_pid, send_fn({:msg, "life is cool"}))

    # rec2 should immediately update its state while rec1 keeps its old one
    assert query_process(rec2_pid, :msg) == "life is cool"
    assert query_process(rec1_pid, :msg) == "hello man"

    # wait for delay to finish and check that rec1's state is updated
    Process.sleep(3000)
    assert query_process(rec1_pid, :msg) == "life is good"
  end

  test "fails a message delivery on purpose", ctx do
    rec_pid = recipients(ctx.pid, 0)
    send_msg(ctx.pid, rec_pid, send_fn({:add, "something"}), %{fail: true})

    assert query_process(rec_pid, :list) == []
  end
end
