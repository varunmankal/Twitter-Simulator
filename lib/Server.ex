defmodule Server do
    use GenServer
    
    def server do
        unless Node.alive?() do
            ip_address = :inet.getif() |> elem(1) |> hd() |> elem(0) |> Tuple.to_list |> Enum.join(".")
            long_name = "server@"<> ip_address |> String.to_atom
            Node.start(long_name,:longnames,15000)
            IO.puts("\nServer Node started at : ")
            IO.puts(Node.self())
            IO.puts("\n")
        end
        
        Node.set_cookie(Node.self,:myconn)
        
        GenServer.start( __MODULE__ , 0, [name: {:global, :server}] )
    end
    
    def create_tables do
        :ets.new(:user_details, [:set, :protected, :named_table])
        :ets.new(:subscriber_table, [:bag, :protected, :named_table])
        :ets.new(:waiting_table, [:bag, :public, :named_table]) 
        :ets.new(:user_mention_table, [:ordered_set, :public, :named_table])
        :ets.new(:hashtag_table, [:ordered_set, :public, :named_table])  
    end

    def init(totalCount) do
        create_tables()
        startTime=System.system_time(:millisecond)
        {:ok,{totalCount,startTime}}
    end
    
    
    def terminate(_,_) do
         IO.inspect ["Server Dead !!!"]
     end

    def handle_cast( {:tweet,user_name,message},state) do
        totalCount=elem(state,0) + 1
        check_user_mention(message)
        check_hashtags(message)

        subscribers = :ets.match_object(:subscriber_table,{user_name,:"_"})
        
        forward_tweets(subscribers,message)
        {:noreply, {totalCount, elem(state,1)}, 20000}
    end

    def handle_cast({:disconnect_user, user_name},state) do
        totalCount=elem(state,0) + 1
        [user_tuple] = :ets.match_object(:user_details,{user_name,:"_",:"_"})
        :ets.insert(:user_details,{elem(user_tuple,0),elem(user_tuple,1),false})
        {:noreply, {totalCount, elem(state,1)}, 20000}
    end

    def handle_cast({:reconnect_user,user_name},state) do
        totalCount=elem(state,0) + 2
        [user_tuple] = :ets.match_object(:user_details,{user_name,:"_",:"_"})
        :ets.insert(:user_details,{elem(user_tuple,0),elem(user_tuple,1),true})
        send_waiting_messages(user_name)
        {:noreply, {totalCount, elem(state,1)}, 20000} 
    end

    def handle_call({:register, signup},_from, state) do
        status = :ets.insert(:user_details, signup)
        totalCount=elem(state,0)+1
  
        if status == true do
            {:reply,:ok,{totalCount, elem(state,1)}}
        else
            {:reply,:false,{totalCount, elem(state,1)}}
        end
    end

    def handle_call( {:subscribe, sub_list}, _from, state) do
        status = :ets.insert(:subscriber_table,sub_list)
        totalCount=elem(state,0)+1
        if status == true do
            {:reply,:ok,{totalCount, elem(state,1)}}
        else
            {:reply,:false,{totalCount, elem(state,1)}}
        end
    end

    def handle_call( {:query_mentions, user_name},_from ,state)   do
        type = "my mentions"
        totalCount=elem(state,0) + 1
        user_tuple = :ets.match(:user_mention_table,{user_name,:"$1"})
        Enum.each(user_tuple,
        fn([x]) -> GenServer.cast({ :global, String.to_atom(user_name)}, {:query_response, type, x} )  end)
        {:reply,:ok,{totalCount, elem(state,1)}, 20000}
    end
  
    def handle_call( {:query_hashtags, user_name, hash_tag},_from ,state)  do
        type = hash_tag<>" mention "
        totalCount=elem(state,0) + 1
        user_tuple = :ets.match(:hashtag_table,{hash_tag,:"$1"})
        Enum.each(user_tuple,
        fn([x]) -> GenServer.cast( { :global, String.to_atom(user_name)} , {:query_response, type, x} )  end)
        {:reply,:ok,{totalCount, elem(state,1)}, 20000}
    end

    def handle_call({:generate_sub_tab},_from ,state)  do
        totalCount=elem(state,0) + 1
        :ets.tab2file(:subscriber_table, 'subscriber_table.txt')
        {:reply,:ok,{totalCount, elem(state,1)}, 20000}
    end

    def handle_info(:timeout, state) do
        endTime=System.system_time(:millisecond)
        totaltime=(endTime-elem(state,1) - 40000) / 1000
        reqPerSecs=elem(state,0)/totaltime
        Kernel.send :mainProcess,{:endmsg, reqPerSecs}
        {:noreply, state}
    end

    def check_user_mention(message) do
        word_list =  String.split(message," ") 
        mentioned_users = Enum.filter(word_list, fn(x) -> String.match?(x, ~r/@/) end)
        size_table=elem(Enum.at(:ets.info(:user_mention_table),7),1)
        #count=:ets.last(:user_mention_table)
        
        if(size_table>=100) do
            Enum.each(mentioned_users, fn(x) -> 
                count=:ets.last(:user_mention_table)+1
                :ets.delete(:user_mention_table,:ets.first(:user_mention_table))
                :ets.insert(:user_mention_table,{count,String.slice(x, 1..-1)  ,message})     
            end )
        else

            Enum.each(mentioned_users, fn(x) -> 
                            temp=:ets.last(:user_mention_table)
                            count=
                            if(is_integer(temp)==true) do
                                temp+1
                            else
                                0    
                            end
                            :ets.insert(:user_mention_table,{count,String.slice(x, 1..-1)  ,message}) 
            end)   
        end
        
    end
  
    def check_hashtags(message) do
        word_list =  String.split(message," ") 
        hash_tags = Enum.filter(word_list, fn(x) -> String.match?(x, ~r/#/) end)
        size_table=elem(Enum.at(:ets.info(:hashtag_table),7),1)
        #count = :ets.last(:hashtag_table)
        
        if(size_table>=100) do
            Enum.each(hash_tags, fn(x) -> 
                count = :ets.last(:hashtag_table)+1
                :ets.delete(:hashtag_table,:ets.first(:hashtag_table))
                :ets.insert(:hashtag_table,{count,String.slice(x, 1..-1)  ,message})     
                 
            end )
        else

            Enum.each(hash_tags, fn(x) -> 
                            temp=:ets.last(:hashtag_table)
                            count = 
                            if(is_integer(temp)==true) do
                                temp+1
                            else
                                0    
                            end
                            :ets.insert(:hashtag_table,{count,String.slice(x, 1..-1)  ,message}) 
            end)   
        end    

    end

    def forward_tweets(subscribers,message) do
        
        Enum.each(subscribers,
        fn({_,i}) ->      
         
            sub_name=i
            [alive_status]=Enum.at(:ets.match(:user_details,{sub_name,:"_",:"$1"}),0)
          
            if alive_status == true do
                GenServer.cast( {:global, String.to_atom(sub_name)},{:live_feed,message})
            else     
                :ets.insert(:waiting_table,{sub_name,message})
            end
        end)
    end

    def send_waiting_messages(user_name) do
        all_messages=:ets.lookup(:waiting_table,user_name)
        for i<-all_messages do
            single_message = elem(i,1) 
            GenServer.cast( {:global, String.to_atom(user_name)},{:old_feed,single_message})
        end
        :ets.delete(:waiting_table,user_name)
    end

end
