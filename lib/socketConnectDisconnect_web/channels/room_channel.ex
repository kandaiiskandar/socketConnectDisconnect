defmodule SocketConnectDisconnectWeb.RoomChannel do
    use Phoenix.Channel
    require Logger
  
    def join("room:admin", _message, socket) do
      Logger.info("Connect admin Transport id : #{inspect(socket.transport_pid)}")
      {:ok, %{reason: "Connected to room:admin"}, assign(socket, :transport_pid, pid_to_string(socket.transport_pid))}
    end

    def join("room:client", _message, socket) do
      Logger.info("Connect client Transport id : #{inspect(socket.transport_pid)}")
      {:ok, %{reason: "Connected to room:client"}, assign(socket, :transport_pid, pid_to_string(socket.transport_pid))}
    end
  
    def join("room:" <> _private_room_id, _params, _socket) do
      {:error, %{reason: "unauthorized"}}
    end

    # Check when websocket disconnect
    def terminate(reason, socket) do
      Logger.info("Disconnected Socket : #{inspect(socket.topic)}")
      Logger.info("Disconnect Transport id : #{inspect(socket.transport_pid)}")
      # Do stuffs.
    end
  
    def handle_in("msg_from_admin", %{"body" => body}, socket) do  
      # push(socket, "from_admin_to_client", %{body: "its working"})
      Logger.info("body : #{inspect(body)}")
       if (body === "test") do
         push(socket, "from_admin_to_client", %{body: "test working"})
         {:noreply, socket}
        else 
         Phoenix.PubSub.broadcast(
           SocketConnectDisconnect.PubSub,
           "room:client",
           %{subject: "from_admin_to_client", payload:  %{data: body}}
         )
         {:noreply, socket}
        end  
    end

    def handle_in("msg_from_client", %{"body" => body}, socket) do  
    Phoenix.PubSub.broadcast(
      SocketConnectDisconnect.PubSub,
      "room:admin",
      %{subject: "from_client_to_admin", payload:  %{data: %{"transport_pid"=> socket.assigns.transport_pid}}}
    )
   {:noreply, socket}
   end

   intercept ["from_client_to_admin", "from_admin_to_client"]

   def handle_info(%{subject: "from_client_to_admin"}=info, socket) do
    #Logger.info("from_client_to_admin received")
    #Logger.info("from_client_to_admin Socket : #{inspect(socket)}")
    if (socket.topic === "room:admin" ) do
      push(socket, "from_client_to_admin", %{body: info.payload.data})
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{subject: "from_admin_to_client"}=info, socket) do
    transport_pid = socket.assigns.transport_pid
    if (transport_pid === info.payload.data["to"] ) do
      Logger.info("from_admin_to_client Socket : #{inspect(info.payload.data["to"])}")
       push socket, "from_admin_to_client", %{body: info.payload.data}
       {:noreply, socket}
    else
       {:noreply, socket}
    end
  end

#   def handle_in("from_admin", %{"body" => body}, socket) do  
#     broadcast! socket, "from_admin_to_client", %{
#       message: body,
#       to_transport_pid: "get transport id from db"}
#    {:noreply, socket}
#  end

  def pid_to_string(getId) do
    :erlang.pid_to_list(getId)
      |>to_string
      |>String.replace(~r"[<,>]", "")
  end
    
  end
  