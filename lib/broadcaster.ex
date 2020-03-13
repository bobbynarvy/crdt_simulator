defmodule Broadcaster do
  use GenServer

  def start_link() do
    initial_state = %{recipients: []}
    GenServer.start_link(__MODULE__, initial_state)
  end

  def add_recipient(pid, rec_pid) do
    GenServer.call(pid, {:add_recipient, rec_pid})
  end

  def recipients(pid) do
    GenServer.call(pid, {:recipients})
  end

  def recipients(pid, index) do
    GenServer.call(pid, {:recipients, index})
  end

  def send_msg(pid, send_fn) do
    GenServer.call(pid, {:send_msg, send_fn})
  end

  def send_msg(pid, rec_pid, send_fn) do
    GenServer.call(pid, {:send_msg, rec_pid, send_fn})
  end

  def send_msg(pid, rec_pid, send_fn, opts) do
    
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
  def handle_call({:send_msg, send_fn}, _from, state) do
    for rec_pid <- state.recipients do
      spawn(fn -> send_fn.(rec_pid) end)
    end

    {:reply, :ok, state}
  end

  def handle_call({:send_msg, rec_pid, send_fn}, _from, state) do
    spawn(fn -> send_fn.(rec_pid) end)

    {:reply, :ok, state}
  end
end