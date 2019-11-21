defmodule TwitterEngine.Server do
    use GenServer

    def start_link({name}) do
        GenServer.start_link(__MODULE__, {"clientnode"}, name: String.to_atom(name))
    end

    def init({clientnode}) do
        # state:
        # ets tables
        #IO.puts "Server Started"
        #IO.puts "-------------------------------"
        :ets.new(:tab_user, [:set, :protected, :named_table])
        :ets.new(:tab_tweet, [:set, :protected, :named_table])
        :ets.new(:tab_msgq, [:set, :protected, :named_table])
        :ets.new(:tab_hashtag, [:set, :protected, :named_table])
        :ets.new(:tab_mentions, [:set, :protected, :named_table])
        :ets.new(:tweet_counter, [:set, :public, :named_table])
        :ets.insert(:tweet_counter, {"count",0})
        {:ok, {clientnode}}
    end

    def handle_call({:simulator_add,address},_,{_}) do
         clientnode = address
         IO.puts "Connected to client simulator sucessfully at #{clientnode}."
         IO.puts "All IO showing the progress of the simulation at the Simulator console."
        {:reply,"ok",{clientnode}}
    end

    def handle_cast({:disconnection,x},{clientnode})do
        :ets.update_element(:tab_user,x,{4, "disconnected"})
        :ets.insert_new(:tab_msgq,{x,[]})
        {:noreply,{clientnode}}
    end

    def handle_cast({:registerUser,x},{clientnode}) do
        #update table (add a new user x)
        :ets.insert_new(:tab_user, {x, [], [], "connected",0})
        GenServer.cast(:main,{:registered})
        {:noreply,{clientnode}}
    end

    def handle_cast({:deRegisterUser,x},{clientnode}) do
        #update table (add a new user x)
        :ets.delete(:tab_user,x)
        #GenServer.cast({:orc,clientnode},{:registered})
        {:noreply,{clientnode}}
    end

    def handle_cast({:reconnection,x},{clientnode})do
        :ets.update_element(:tab_user,x,{4, "connected"})
        [{_,tweetlist}]=:ets.lookup(:tab_msgq,x)
        :ets.delete(:tab_msgq,x)
        result = Enum.map(tweetlist,fn(x)-> :ets.lookup(:tab_tweet,x)end)
        GenServer.cast({String.to_atom("user"<>Integer.to_string(x)),clientnode},{:query_result, result})
        {:noreply,{clientnode}}
    end

    def handle_cast({:subscribe,x,subscribe_to},{clientnode})do
        #update table (add subscribe to for user x)
        [{_,old_list,_,_,_}] = :ets.lookup(:tab_user, x)

        #subscribe_to = Enum.uniq(subscribe_to) -- [x]
        #IO.puts "user#{x} is now following #{Enum.at(subscribe_to,0)}, #{Enum.at(subscribe_to,1)}"
        new_list = Enum.uniq(old_list++subscribe_to)
        :ets.update_element(:tab_user, x, {2, new_list})

        #update table (add x to followers list)
        Enum.map(subscribe_to, fn(y)->
            :ets.update_element(:tab_user, y,
                {3, [x]++List.flatten(:ets.match(:tab_user, {y,:"_",:"$1",:"_"}))}
            )
        end)
        #IO.inspect :ets.select(:tab_user, [{{:"$1", :"$2", :"$3",:"$4"}, [], [:"$_"]}])
        {:noreply,{clientnode}}
    end

    def handle_call({:tweet,x,msg, retweet_testing},_from,{clientnode})do
        #update tweet counter
        [{_,_,followers_list,_,old_count}] = :ets.lookup(:tab_user, x)
        :ets.update_element(:tab_user, x, {5, old_count+1})
        #update tweet table (add msg to tweet list of x)
        tweetid = Integer.to_string(x)<>"T"<>Integer.to_string(old_count+1)
        :ets.insert_new(:tab_tweet, {tweetid,x,msg})
        :ets.update_counter(:tweet_counter, "count", {2,1})
        #update hashtag and mentions table
        hashtag_update(tweetid,msg)
        mentions_update(tweetid,msg)
        #cast message to all subscribers of x if ALIVE
        if retweet_testing == 0 do
            Enum.map(followers_list,fn(y)-> send_if_alive(y,x,msg,tweetid,clientnode, 0) end)
        else
            Enum.map(followers_list,fn(y)-> send_if_alive(y,x,msg,tweetid,clientnode, 1) end)
        end
        {:reply,tweetid,{clientnode}}
    end

    def handle_call({:queryHashTags,hashTag},_from,{clientnode}) do
      tweetsWithHashTag = Enum.map elem(Enum.at(:ets.lookup(:tab_hashtag, hashTag),0),1),fn x->
        elem(Enum.at(:ets.lookup(:tab_tweet, x),0),2)
      end
      {:reply,tweetsWithHashTag, {clientnode}}
    end

    def handle_call({:queryMyMention,mention},_from,{clientnode}) do
      tweetsWithMyMentions = Enum.map elem(Enum.at(:ets.lookup(:tab_mentions, mention),0),1),fn x->
        elem(Enum.at(:ets.lookup(:tab_tweet, x),0),2)
      end
      {:reply,tweetsWithMyMentions, {clientnode}}
    end

    def handle_call({:allSubscribedTweets,id},_from,{clientnode}) do
      tweets = Enum.map elem(Enum.at(:ets.lookup(:tab_user, id),0),1),fn x->
        Enum.at(List.flatten(:ets.match(:tab_tweet,{:"_",x,:"$1"})),0)
      end
      {:reply,tweets, {clientnode}}
    end

    def handle_cast({:all_completed},{clientnode}) do
        IO.puts "Exiting."
        GenServer.cast({:orc,clientnode},{:time})
        :global.sync()
        #send(:global.whereis_name(:client_boss),{:all_requests_served})
        send(:global.whereis_name(:server_boss),{:all_requests_served_s})
        {:noreply,{clientnode}}
    end

    def send_if_alive(follower,sender,msg,tweetid,clientnode, retweet_testing) do
        status = :ets.lookup_element(:tab_user,follower,4)
        if status == "connected" do
            if retweet_testing == 0 do
                #GenServer.cast({String.to_atom("user"<>Integer.to_string(follower)),clientnode},{:on_the_feed,sender,msg, 0})
            else
                #GenServer.cast({String.to_atom("user"<>Integer.to_string(follower)),clientnode},{:on_the_feed,sender,msg, 1})
            end
        else
            old_msgq = :ets.lookup_element(:tab_msgq,follower,2)
            new_msgq = old_msgq ++ [tweetid]
            :ets.update_element(:tab_msgq,follower,{2,new_msgq})
        end

    end

    def hashtag_update(tweetid,msg) do
         hashregex = ~r/\#\w*/
         tags = List.flatten(Regex.scan(hashregex,msg))
         Enum.map(tags, fn(x)-> if :ets.insert_new(:tab_hashtag,{x,[tweetid]}) == false do
             :ets.update_element(:tab_hashtag,x,{2,[tweetid]++List.flatten(:ets.match(:tab_hashtag,{x,:"$1"}))}) end end)
    end

    def mentions_update(tweetid,msg) do
        hashregex = ~r/\@\w*/
        tags = List.flatten(Regex.scan(hashregex,msg))
        Enum.map(tags, fn(x)-> if :ets.insert_new(:tab_mentions,{x,[tweetid]}) == false do
            :ets.update_element(:tab_mentions,x,{2,[tweetid]++List.flatten(:ets.match(:tab_mentions,{x,:"$1"}))}) end end)

    end

end
