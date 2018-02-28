defmodule Project41 do
  def main(args) do
    args_list = elem(OptionParser.parse(args),1)
    process = Enum.at(args_list,0)
    Process.register(self(),:mainProcess)
    if process == "server" do
      Server.server
      listen_server()
    end 
    
    if process == "client" do
      num = String.to_integer(Enum.at(args_list,1))
      rqst = String.to_integer(Enum.at(args_list,2))

      num_roundoff =
      cond do
        rem(num,100) != 0 ->  (Float.ceil( (num/100),0) ) *100 |> round()
        true -> num
      end

      rqst_roundoff =
      cond do
        rem(rqst,100) != 0 ->   (Float.ceil( (rqst/5),0) ) *5 |> round()
        true -> rqst
      end

      Client.generate_client(num_roundoff,rqst_roundoff)
      [total_sent, total_received] = listen_client(2*num, 0, 0)
      Process.sleep(1000)

      IO.puts "\n\n=================================="
      IO.puts     "|| Total tweets sent          : " <> to_string(total_sent)<>"||"
      IO.puts     "|| Total live tweets received : "<> to_string(total_received)<>"||"
      IO.puts     "==================================="
    end
  end

  def listen_server() do
    receive do 
      {:endmsg, reqPerSecs} -> 
        IO.puts "\n==========================================="
        IO.puts   "|| No Client Alive. Server Terminating!!! ||"
        IO.puts   "==========================================="
        IO.puts "\n==================================================="
        IO.puts "|| Average Requests Processed/Second : " <> to_string(reqPerSecs) <>"||"
        IO.puts "====================================================="
        exit(:normal)   
    end
    listen_server()
  end

  def listen_client(0,sent,rcvd), do: [sent, rcvd]
  def listen_client(count,sent,rcvd) do
    receive do
      {:sent_tweets, sent_mesg} -> sent = sent + sent_mesg
                              listen_client(count - 1,sent,rcvd)
      {:rcvd_tweets, rcvd_mesg} -> rcvd = rcvd + rcvd_mesg
                              listen_client(count - 1,sent,rcvd)
      _ -> raise "listen_client error!"
    end
  end
end
