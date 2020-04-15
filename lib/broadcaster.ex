defmodule Broadcaster do
  use GenServer

  @moduledoc """
  Implements a generic broadcaster that sends asynchronous
  messages from a sending process to other recipients
  """

  @doc """
  Creates a broadcaster process
  """
  def start_link() do
    initial_state = %{recipients: []}
    GenServer.start_link(__MODULE__, initial_state)
  end

  @doc """
  Adds a recipient process to the 
  broadcaster state
  """
  def add_recipient(pid, rec_pid) do
    GenServer.call(pid, {:add_recipient, rec_pid})
  end

  @doc """
  Returns the recipient pids of the broadcaster
  """
  def recipients(pid) do
    GenServer.call(pid, {:recipients})
  end

  @doc """
  Returns a recipient pid by index
  """
  def recipients(pid, index) do
    GenServer.call(pid, {:recipients, index})
  end

  @doc """
  Sends a message to recipient(s) by applying
  a sender function that takes a recipienst pid.

  Optionally delays or fails delivery to a recipient.
  """
  def send_msg(pid, params) do
    case params do
      {send_fn} ->
        for rec_pid <- recipients(pid) do
          GenServer.call(pid, {:send_msg, rec_pid, send_fn, %{}})
        end

      {send_fn, opts} when is_map(opts) ->
        for rec_pid <- recipients(pid) do
          GenServer.call(pid, {:send_msg, rec_pid, send_fn, opts})
        end

      {send_fn, rec_pid} ->
        GenServer.call(pid, {:send_msg, rec_pid, send_fn, %{}})

      {send_fn, rec_pid, opts} ->
        GenServer.call(pid, {:send_msg, rec_pid, send_fn, opts})
    end
  end

  @doc """
  Sends a message to all recipients
  """
  def send_msgs(pid, msgs) do
    for msg <- msgs do
      case msg do
        {rec_pid, send_fn} -> GenServer.call(pid, {:send_msg, rec_pid, send_fn, %{}})
        {rec_pid, send_fn, opts} -> GenServer.call(pid, {:send_msg, rec_pid, send_fn, opts})
      end
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:add_recipient, pid}, _from, state) do
    recipients = state.recipients ++ [pid]
    {:reply, recipients, %{state | recipients: recipients}}
  end

  @impl true
  def handle_call({:recipients}, _from, state) do
    {:reply, state.recipients, state}
  end

  @impl true
  def handle_call({:recipients, index}, _from, state) do
    {:reply, Enum.at(state.recipients, index), state}
  end

  @impl true
  def handle_call({:send_msg, rec_pid, send_fn, opts}, _from, state) do
    fail = Map.get(opts, :fail, false)
    delay = Map.get(opts, :delay, 0)

    if not fail do
      spawn(fn ->
        Process.sleep(delay)

        send_fn.(rec_pid)
      end)

      {:reply, {:ok, "Message sent"}, state}
    else
      {:reply, {:error, "Message sending failed"}, state}
    end
  end
end
