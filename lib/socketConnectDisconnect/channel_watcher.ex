# Source : https://stackoverflow.com/questions/33934029/how-to-detect-if-a-user-left-a-phoenix-channel-due-to-a-network-disconnect

defmodule SocketConnectDisconnect.ChannelWatcher do
    use GenServer
  
    ## Client API
  
    def monitor(server_name, pid) do
      GenServer.call(server_name, {:monitor, pid})
    end
  
    def demonitor(server_name, pid) do
      GenServer.call(server_name, {:demonitor, pid})
    end
  
    ## Server API
  
    def start_link(name) do
        GenServer.start_link(__MODULE__, [], name: name)
    end
    
    def init(_) do
      Process.flag(:trap_exit, true)
      {:ok, %{channels: HashDict.new()}}
    end
  
    def handle_call({:monitor, pid}, _from, state) do
      Process.link(pid)
      {:reply, :ok, put_channel(state, pid)}
    end
  
    def handle_call({:demonitor, pid}, _from, state) do
      case HashDict.fetch(state.channels, pid) do
        :error       -> {:reply, :ok, state}
        {:ok,  _mfa} ->
          Process.unlink(pid)
          {:reply, :ok, drop_channel(state, pid)}
      end
    end
  
    def handle_info({:EXIT, pid, _reason}, state) do
      case HashDict.fetch(state.channels, pid) do
        :error -> {:noreply, state}
        {:ok, {mod, func, args}} ->
          Task.start_link(fn -> apply(mod, func, args) end)
          {:noreply, drop_channel(state, pid)}
      end
    end
  
    defp drop_channel(state, pid) do
      %{state | channels: HashDict.delete(state.channels, pid)}
    end
  
    defp put_channel(state, pid) do
      %{state | channels: HashDict.put(state.channels, pid)}
    end

  end