defmodule BroadcasterTEST do
  use ExUnit.Case
  import Broadcaster

  setup do
    {:ok, pid} = start_link()
    {:ok, pid: pid}
  end

  test "keeps track of recipient pids", ctx do
    for _ <- 1..3 do
      rec_pid =
        spawn(fn ->
          receive_msg = fn ->
            receive do
              {:hello, message} -> message
            end

            receive_msg.()
          end

          receive_msg.()
        end)

      add_recipient(ctx[:pid], rec_pid)
    end

    assert List.length(recipients(ctx[:pid])) == 3
  end

  test "sends messages to all recipients", ctx do
    send_msg(ctx[:pid], {:hello, "world"})

    assert_receive {:hello, "world"}
  end

  test "sends a message to a recipient", ctx do
    rec_pid = recipients(ctx[:pid], 0)
    send_msg(ctx[:pid], rec_pid, {:hello, "man"})

    assert_receive {:hello, "man"}
  end

  test "sends different messages to different recipients", ctx do
    rec1_pid = recipients(ctx[:pid], 0)
    rec2_pid = recipients(ctx[:pid], 1)

    send_msg(ctx[:pid], [
      {rec1_pid, {:hello, "world"}},
      {rec2_pid, {:hello, "man"}}
    ])

    assert_receive {:hello, "world"}
    assert_receive {:hello, "man"}
  end
end
