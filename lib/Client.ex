defmodule Client do
    use GenServer, export: :server 

    def generate_client(num,rqst_count) do
        unless Node.alive?() do
            ip_address = :inet.getif() |> elem(1) |> hd() |> elem(0) |> Tuple.to_list |> Enum.join(".")
            long_name = "client@"<> ip_address |> String.to_atom
            Node.start(long_name,:longnames,15000)
            IO.puts("\nClient Node started at : ")
            IO.puts(Node.self())
            IO.puts("\n")
        end
       
        Node.set_cookie(Node.self,:myconn)

        ip_addr = :inet.getif() |> elem(1) |> hd() |> elem(0) |> Tuple.to_list |> Enum.join(".")
        conn_str = "server@"<>ip_addr |> String.to_atom
        Node.connect(conn_str) 
        
        :global.sync()

        for n <- 1..num do
            user_name = "user"<>to_string(n)
            type = get_client_type(n, num)
            rqst = get_request_count(type, rqst_count)
            GenServer.start_link(__MODULE__ , [user_name,n,type,0,rqst,0] , [name: { :global, String.to_atom(user_name)}] )
            :global.sync()
        end

        type1 = round( 0.05 * num )
        type2 = round( 0.10 * num ) + type1
        type3 = round( 0.15 * num ) + type2
        type4 = round( 0.25 * num ) + type3
        
        # for each clent n type 1 lst -> call type1 functonaltes
        Enum.each(1..type1, fn x -> GenServer.cast({:global, String.to_atom("user"<>to_string(x))} ,{:start_simulation1,"user"<>to_string(x),num}) end) 
        Enum.each((type1+1)..type2, fn x -> GenServer.cast({:global, String.to_atom("user"<>to_string(x))} ,{:start_simulation2,"user"<>to_string(x),num}) end )
        Enum.each((type2+1)..type3, fn x -> GenServer.cast({:global, String.to_atom("user"<>to_string(x))} ,{:start_simulation3,"user"<>to_string(x),num}) end )
        Enum.each((type3+1)..type4, fn x -> GenServer.cast({:global, String.to_atom("user"<>to_string(x))} ,{:start_simulation4,"user"<>to_string(x),num}) end )
        Enum.each((type4+1)..num  , fn x -> GenServer.cast({:global, String.to_atom("user"<>to_string(x))} ,{:start_simulation5,"user"<>to_string(x),num}) end )

    end

    def get_client_type(n, num) do
        type1_count = round( 0.05 * num )
        type2_count = round( 0.10 * num )
        type3_count = round( 0.15 * num )
        type4_count = round( 0.25 * num )

        cond do
            n <= type1_count -> 1

            n <= type2_count -> 2
            n <= type3_count -> 3
            n <= type4_count -> 4
            true             -> 5
        end
    end

    def get_request_count(type,rqst_count) do
        case type do
            1 -> rqst_count 
            2 -> Float.ceil((rqst_count*0.8),0) |> round()
            3 -> Float.ceil((rqst_count*0.6),0) |> round()
            4 -> Float.ceil((rqst_count*0.4),0) |> round()
            5 -> Float.ceil((rqst_count*0.2),0) |> round()
        end
    end

    def get_subscr_count(type, num) do
        case type do
            1 -> sub_count = round( 0.05 * num ) 
                  if sub_count < 100 do
                        sub_count
                  else
                    100
                  end
            
            2 -> sub_count = round( 0.04 * num ) 
                if sub_count < 80 do
                    sub_count
                  else
                        80
                  end
            
            3 -> sub_count = round( 0.03 * num ) 
                  if sub_count < 60 do
                      sub_count
                    else
                          60
                    end
            
            4 -> sub_count = round( 0.02 * num ) 
                 if sub_count < 40 do
                    sub_count
                  else
                    40
                  end
            
            _ -> 1
                
        end
        
    end
    
    def zpf_subscr(user_name, type, num) do
        sub_count = get_subscr_count(type, num)
        sub_list = Enum.shuffle(1..num) |> Enum.slice(0..(sub_count-1))
        Enum.each(sub_list, fn x ->
            GenServer.cast( {:global, String.to_atom("user"<> to_string(x))} , {:start_subscribe,"user"<> to_string(x), user_name})          
                                                                                                end )
        sub_count
    end

    def type1_processes(user_name,num) do
        GenServer.cast( {:global, String.to_atom(user_name)} ,{:type1_processes,user_name,num})
    end

    def type2_processes(user_name,num) do
        GenServer.cast( {:global, String.to_atom(user_name)} ,{:type2_processes,user_name,num})
    end

    def type3_processes(user_name,num) do
        GenServer.cast( {:global, String.to_atom(user_name)} ,{:type3_processes,user_name,num})
    end

    def type4_processes(user_name,num) do
        GenServer.cast( {:global, String.to_atom(user_name)} ,{:type4_processes,user_name,num})
    end

    def type5_processes(user_name,num) do
        GenServer.cast( {:global, String.to_atom(user_name)} ,{:type5_processes,user_name,num})
    end

    def init(state) do
        register(hd(state))
        state = List.replace_at(state,5,1)
        {:ok,state}
    end

    def handle_cast({:update_type,type}, state) do
        state = List.replace_at(state,2,type)
        {:noreply,state}
    end

    def handle_cast({:start_subscribe,user_name, followed_user}, state) do
        subscribe(user_name,followed_user)
        {:noreply,state}
    end

    def handle_cast({:start_simulation1,user_name,num}, state) do
        sub_count = zpf_subscr(user_name,Enum.at(state,2),num)
        type1_processes(user_name, num)
        count = Enum.at(state, 5)
        state = List.replace_at(state,5, count+sub_count)
        {:noreply,state}
    end

    def handle_cast({:start_simulation2,user_name,num}, state) do
        sub_count = zpf_subscr(user_name,Enum.at(state,2),num)
        type2_processes(user_name,num)
        count = Enum.at(state, 5)
        state = List.replace_at(state,5, count+sub_count)
        {:noreply,state}
    end

    def handle_cast({:start_simulation3,user_name,num}, state) do
        sub_count = zpf_subscr(user_name,Enum.at(state,2),num)
        type3_processes(user_name,num)
        count = Enum.at(state, 5)
        state = List.replace_at(state,5, count+sub_count)
        {:noreply,state}
    end

    def handle_cast({:start_simulation4,user_name,num}, state) do
        sub_count = zpf_subscr(user_name,Enum.at(state,2),num)
        type4_processes(user_name,num)
        count = Enum.at(state, 5)
        state = List.replace_at(state,5, count+sub_count)
        {:noreply,state}
    end

    def handle_cast({:start_simulation5,user_name,num}, state) do
        sub_count = zpf_subscr(user_name,Enum.at(state,2),num)
        type5_processes(user_name,num)
        count = Enum.at(state, 5)
        state = List.replace_at(state,5, count+sub_count)
        {:noreply,state}
    end

    def handle_cast({:type1_processes,user_name,num}, state) do

        tweet( user_name,"Message by "<> user_name ) 
        Process.sleep(100)

        mentioned_user = "@user" <> (Enum.random(1..num) |> to_string )        
        tweet( user_name,"Message mention " <> mentioned_user) 
        Process.sleep(100)
        
        hashtag = "#Hashtag" <> (Enum.random(1..100) |> to_string )
        tweet( user_name,"Message about " <> hashtag) 
        Process.sleep(100)

        #query my mentons
        query_mentions(user_name)
        Process.sleep(100)
        
        # query menton
        hashtag = "Hashtag" <> (Enum.random(1..100) |> to_string )
        query_hashtags(hashtag, user_name)
        Process.sleep(100)

        disconnect(user_name)

        sent_mesg = Enum.at(state,5) + 6
        
        if sent_mesg < Enum.at(state,4) do
            Process.sleep(1000)
            reconnect(user_name)
            state = List.replace_at(state,5,sent_mesg+1)
            GenServer.cast( {:global, String.to_atom(user_name)} ,{:type1_processes,user_name,num})
        else
            send(:mainProcess,{:sent_tweets, sent_mesg})
            send(:mainProcess,{:rcvd_tweets, Enum.at(state,3)})
        end
        
        {:noreply,state}
    end

    def handle_cast({:type2_processes,user_name,num}, state) do

        tweet( user_name,"Message by "<> user_name ) 
        Process.sleep(400)

        mentioned_user = "@user" <> (Enum.random(1..num) |> to_string )        
        tweet( user_name,"Message mention " <> mentioned_user) 
        Process.sleep(400)
        
        hashtag = "#Hashtag" <> (Enum.random(1..100) |> to_string )
        tweet( user_name,"Message about " <> hashtag) 
        Process.sleep(400)

        # query my mentons
        query_mentions(user_name)
        Process.sleep(400)
        
        # query menton
        hashtag = "Hashtag" <> (Enum.random(1..100) |> to_string )
        query_hashtags(hashtag, user_name)
        Process.sleep(400)

        disconnect(user_name)
        
        sent_mesg = Enum.at(state,5) + 6
        
        if sent_mesg < Enum.at(state,4) do
            Process.sleep(2000)
            reconnect(user_name)
            state = List.replace_at(state,5,sent_mesg+1)
            GenServer.cast( {:global, String.to_atom(user_name)} ,{:type2_processes,user_name,num})
        else
            send(:mainProcess,{:sent_tweets, sent_mesg})
            send(:mainProcess,{:rcvd_tweets, Enum.at(state,3)})
        end

        {:noreply,state}
    end

    def handle_cast({:type3_processes,user_name,num}, state) do

        tweet( user_name,"Message by "<> user_name ) 
        Process.sleep(600)

        mentioned_user = "@user" <> (Enum.random(1..num) |> to_string )        
        tweet( user_name,"Message mention " <> mentioned_user) 
        Process.sleep(600)
        
        hashtag = "#Hashtag" <> (Enum.random(1..100) |> to_string )
        tweet( user_name,"Message about " <> hashtag) 
        Process.sleep(600)

        # query my mentons
        query_mentions(user_name)
        Process.sleep(600)
        
        # query menton
        hashtag = "Hashtag" <> (Enum.random(1..100) |> to_string )
        query_hashtags(hashtag, user_name)
        Process.sleep(600)

        disconnect(user_name)

        sent_mesg = Enum.at(state,5) + 6
        
        if sent_mesg < Enum.at(state,4) do
            Process.sleep(3000)
            reconnect(user_name)
            state = List.replace_at(state,5,sent_mesg+1 )
            GenServer.cast( {:global, String.to_atom(user_name)} ,{:type3_processes,user_name,num})
        else
            send(:mainProcess,{:sent_tweets, sent_mesg})
            send(:mainProcess,{:rcvd_tweets, Enum.at(state,3)})
        end

        {:noreply,state}
    end

    def handle_cast({:type4_processes,user_name,num}, state) do

        tweet( user_name,"Message by "<> user_name ) 
        Process.sleep(800)

        mentioned_user = "@user" <> (Enum.random(1..num) |> to_string )        
        tweet( user_name,"Message mention " <> mentioned_user) 
        Process.sleep(800)
        
        hashtag = "#Hashtag" <> (Enum.random(1..100) |> to_string )
        tweet( user_name,"Message about " <> hashtag) 
        Process.sleep(800)

        # query my mentons
        query_mentions(user_name)
        Process.sleep(800)
        
        # query menton
        hashtag = "Hashtag" <> (Enum.random(1..100) |> to_string )
        query_hashtags(hashtag, user_name)
        Process.sleep(800)

        disconnect(user_name)
        #Process.sleep(4000)
        #reconnect(user_name)
        
        sent_mesg = Enum.at(state,5) + 6
        #state = List.replace_at(state,5,sent_mesg)
        if sent_mesg < Enum.at(state,4) do
            Process.sleep(4000)
            reconnect(user_name)
            state = List.replace_at(state,5,sent_mesg+1)
            GenServer.cast( {:global, String.to_atom(user_name)} ,{:type4_processes,user_name,num})
        else
            send(:mainProcess,{:sent_tweets, sent_mesg})
            send(:mainProcess,{:rcvd_tweets, Enum.at(state,3)})
        end

        {:noreply,state}
    end

    
    def handle_cast({:type5_processes,user_name,num}, state) do

        tweet( user_name,"Message by "<> user_name ) 
        Process.sleep(1000)

        mentioned_user = "@user" <> (Enum.random(1..num) |> to_string )        
        tweet( user_name,"Message mention " <> mentioned_user) 
        Process.sleep(1000)
        
        hashtag = "#Hashtag" <> (Enum.random(1..100) |> to_string )
        tweet( user_name,"Message about " <> hashtag) 
        Process.sleep(1000)

        # query my mentons
        query_mentions(user_name)
        Process.sleep(1000)
        
        # query menton
        hashtag = "Hashtag" <> (Enum.random(1..100) |> to_string )
        query_hashtags(hashtag, user_name)
        Process.sleep(1000)

        disconnect(user_name)
        
        sent_mesg = Enum.at(state,5) + 6
        
        if sent_mesg < Enum.at(state,4) do
            Process.sleep(5000)
            reconnect(user_name)
            state = List.replace_at(state,5,sent_mesg+1)
            GenServer.cast( {:global, String.to_atom(user_name)} ,{:type5_processes,user_name,num})
        else
            send(:mainProcess,{:sent_tweets, sent_mesg})
            send(:mainProcess,{:rcvd_tweets, Enum.at(state,3)})
        end

        {:noreply,state}
    end

    ### messages from server ###

    def handle_cast({:live_feed,message}, state) do
         IO.inspect [Enum.at(state,0)," received live message ",message]
        receive_count = Enum.at(state,3) + 1
        
        if rem(receive_count,100) == 0 and Enum.at(state,2) == 1, do: retweet(Enum.at(state,0), "rt:" <> message)
        if rem(receive_count,200) == 0 and Enum.at(state,2) == 2, do: retweet(Enum.at(state,0), "rt:" <> message)
        if rem(receive_count,300) == 0 and Enum.at(state,2) == 3, do: retweet(Enum.at(state,0), "rt:" <> message)
        if rem(receive_count,400) == 0 and Enum.at(state,2) == 4, do: retweet(Enum.at(state,0), "rt:" <> message)
        if rem(receive_count,500) == 0 and Enum.at(state,2) == 5, do: retweet(Enum.at(state,0), "rt:" <> message)

        state = List.replace_at(state,3,receive_count)
        {:noreply,state}
    end

    def handle_cast({:old_feed,message},state) do
        IO.inspect [Enum.at(state,0)," received message ",message,"on reconnection"]
        {:noreply,state}
    end

    def handle_cast({:query_response,type,response},state)  do
        IO.inspect type<>" :: "<>response
        {:noreply,state} 
    end

    def handle_call({:update_state,new_state},_from,_state) do
        {:reply,:ok,new_state}
    end

    def handle_info(mesg, state) do
        IO.inspect mesg
        {:noreply, state}
    end

    ### messages to server ###

    def register(user_name) do
        GenServer.call({ :global, :server} , {:register, {user_name, self(),true}}, :infinity)
        IO.inspect "Registered " <> user_name
    end

    def subscribe(user_name,followed_user) do
        GenServer.call({:global, :server}, {:subscribe , {followed_user,user_name}}, :infinity )   
        IO.inspect user_name <> " subscribed to " <> followed_user
    end

    def tweet(user_name,message) do
        #prnt
        GenServer.cast({:global, :server}, {:tweet,user_name,message})
    end

    def retweet(user_name,message) do
        
        tweet(user_name,message)
    end

    def disconnect(user_name) do
        GenServer.cast({:global, :server}, {:disconnect_user, user_name} )
        IO.inspect user_name <> " disconnected "
    end
    
    def reconnect(user_name) do
        GenServer.cast({:global, :server}, {:reconnect_user, user_name} )
        IO.inspect user_name <> " reconnected "
    end

    def query_mentions(user_name) do
        GenServer.call({:global, :server}, {:query_mentions, user_name}, :infinity )
    end
            
    def query_hashtags(hash_tag, user_name) do
        GenServer.call({:global, :server}, {:query_hashtags, user_name, hash_tag}, :infinity )
    end

    def generate_sub_tab() do
        GenServer.call({:global, :server}, {:generate_sub_tab}, :infinity )
    end

end
