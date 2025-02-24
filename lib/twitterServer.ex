defmodule TwitterEngine.Server do
  use GenServer

  def start_link({name, numClients}) do
    GenServer.start_link(__MODULE__, {0, numClients}, name: String.to_atom(name))
  end

  def init({extra_activities, numClients}) do
    # extra_activities:
    # ets tables
    # IO.puts "Server Started"
    # IO.puts "-------------------------------"
    :ets.new(:user_dB, [:set, :protected, :named_table])
    :ets.new(:tweet_dB, [:set, :protected, :named_table])
    :ets.new(:msgQueue_dB, [:set, :protected, :named_table])
    :ets.new(:hashtag_dB, [:set, :protected, :named_table])
    :ets.new(:mentions_dB, [:set, :protected, :named_table])
    {:ok, {extra_activities, 1, numClients}}
  end

  def handle_cast({:registerUser, x}, {extra_activities, clientsCompleted, numClients}) do
    # update table (add a new user x)
    exists = :ets.insert_new(:user_dB, {x, [], [], "connected", 0})

    if !exists do
      GenServer.cast(String.to_atom("client_" <> Integer.to_string(x)),{:notification, "account already exists"})
    end

    if :global.whereis_name(:main) != :undefined do
      send(:global.whereis_name(:main), {:registered})
    end

    {:noreply, {extra_activities, clientsCompleted, numClients}}
  end

  def handle_cast({:deleteAccount, x}, {extra_activities, clientsCompleted, numClients}) do
    # update table (add a new user x)
    :ets.delete(:user_dB, x)
    # GenServer.cast({:orc,extra_activities},{:registered})
    {:noreply, {extra_activities + 1, clientsCompleted, numClients}}
  end

  def handle_cast({:disconnection, x}, {extra_activities, clientsCompleted, numClients}) do
    :ets.update_element(:user_dB, x, {4, "disconnected"})
    :ets.insert_new(:msgQueue_dB, {x, []})
    {:noreply, {extra_activities, clientsCompleted, numClients}}
  end

  def handle_cast({:reconnection, id}, {extra_activities, clientsCompleted, numClients}) do
    :ets.update_element(:user_dB, id, {4, "connected"})
    [{_, tweetlist}] = :ets.lookup(:msgQueue_dB, id)
    :ets.delete(:msgQueue_dB, id)
    result = Enum.map(tweetlist, fn z -> :ets.lookup(:tweet_dB, z) end)

    Enum.map(result, fn [{a, b, c}] ->
      GenServer.cast(String.to_atom("client_" <> Integer.to_string(id)), {:on_the_feed, b, c, 0})
    end)

    {:noreply, {extra_activities + 1, clientsCompleted, numClients}}
  end

  def handle_cast({:subscribe, x, subscribe_to}, {extra_activities, clientsCompleted, numClients}) do
    # update table (add subscribe to for user x)
    subscribe_to = subscribe_to -- [x]
    [{_, old_list, _, _, _}] = :ets.lookup(:user_dB, x)

    # subscribe_to = Enum.uniq(subscribe_to) -- [x]
    # IO.puts "user#{x} is now following #{Enum.at(subscribe_to,0)}, #{Enum.at(subscribe_to,1)}"
    new_list = Enum.uniq(old_list ++ subscribe_to)
    :ets.update_element(:user_dB, x, {2, new_list})

    # update table (add x to followers list)
    Enum.map(subscribe_to, fn y ->
      # IO.inspect ["in", y, elem(Enum.at(:ets.lookup(:user_dB, y), 0), 3)], charlists: :as_lists
      :ets.update_element(:user_dB, y, {3, [x | elem(Enum.at(:ets.lookup(:user_dB, y), 0), 2)]})
    end)

    # IO.inspect :ets.select(:user_dB, [{{:"$1", :"$2", :"$3",:"$4"}, [], [:"$_"]}])
    {:noreply, {extra_activities, clientsCompleted, numClients}}
  end

  def handle_cast({:tweet, id, message, retweet_testing},{extra_activities, clientsCompleted, numClients}) do
    # update tweet counter
    # IO.inspect "#{id} --> #{message} "
    if analyze(message) == false do
       GenServer.cast(String.to_atom("client_" <> Integer.to_string(id)),{:notification, "this might hurt someone's sentiment"})
    else
    	exists = :ets.lookup(:user_dB, id)

	    if exists == [] do
	      GenServer.cast(
	        String.to_atom("client_" <> Integer.to_string(id)),
	        {:notification, "Create an account first!"})
    	else
	        [{_, _, followers_list, _, old_count}] = :ets.lookup(:user_dB, id)
	        :ets.update_element(:user_dB, id, {5, old_count + 1})
	        # update tweet table (add msg to tweet list of x)
	        tweetid = Integer.to_string(id) <> "T" <> Integer.to_string(old_count + 1)
	        :ets.insert_new(:tweet_dB, {tweetid, id, message})
	        # update hashtag and mentions table
	        updateHashTagDB(tweetid, message)
	        updateMentionsDB(tweetid, message)
	        # cast message to all subscribers of x if ALIVE
	        if retweet_testing == 0 do
	          Enum.map(followers_list, fn y ->
	            send_if_alive(y, id, message, tweetid, extra_activities, 0)
	          end)
	        else
              Enum.map(followers_list, fn y ->
                send_if_alive(y, id, message, tweetid, extra_activities, 1)
              end)
            end
        end
    end

    
    {:noreply, {extra_activities, clientsCompleted, numClients}}
  end

  def handle_call(
        {:queryHashTags, hashTag},
        _from,
        {extra_activities, clientsCompleted, numClients}
      ) do
    # IO.inspect ["qht", Enum.at(:ets.lookup(:hashtag_dB, hashTag),0)]
    tweetsWithHashTag =
      if Enum.at(:ets.lookup(:hashtag_dB, hashTag), 0) != nil do
        Enum.map(elem(Enum.at(:ets.lookup(:hashtag_dB, hashTag), 0), 1), fn x ->
          elem(Enum.at(:ets.lookup(:tweet_dB, x), 0), 2)
        end)
      else
        ""
      end

    # tweetsWithHashTag  = ""
    {:reply, tweetsWithHashTag, {extra_activities + 1, clientsCompleted, numClients}}
  end

  def handle_call(
        {:queryMyMention, mention},
        _from,
        {extra_activities, clientsCompleted, numClients}
      ) do
    tweetsWithMyMentions =
      if Enum.at(:ets.lookup(:mentions_dB, mention), 0) != nil do
        Enum.map(elem(Enum.at(:ets.lookup(:mentions_dB, mention), 0), 1), fn x ->
          elem(Enum.at(:ets.lookup(:tweet_dB, x), 0), 2)
        end)
      else
        ""
      end

    {:reply, tweetsWithMyMentions, {extra_activities + 1, clientsCompleted, numClients}}
  end

  def handle_call(
        {:allSubscribedTweets, id},
        _from,
        {extra_activities, clientsCompleted, numClients}
      ) do
    tweets =
      Enum.map(elem(Enum.at(:ets.lookup(:user_dB, id), 0), 1), fn x ->
        Enum.at(List.flatten(:ets.match(:tweet_dB, {:_, x, :"$1"})), 0)
      end)

    {:reply, tweets, {extra_activities, clientsCompleted, numClients}}
  end

  def handle_cast({:done}, {extra_activities, clientsCompleted, numClients}) do
    # IO.inspect :ets.lookup(:user_dB, clientsCompleted), charlists: :as_lists

    if clientsCompleted == numClients do
      toc = System.system_time(:millisecond)
      [{_, tic}] = :ets.lookup(:time_printing, 'tic')

      IO.puts(
        "We have coded the logic such that, the starting client nodes (with ids 1, 2, 3, 4, etc...) have more followers"
      )

      IO.puts("So, the number of messages these client nodes send will be more.")

      IO.puts(
        "#{numClients} clients sent #{:ets.info(:tweet_dB, :size)} messages and performed #{
          extra_activities
        } activities."
      )

      IO.puts("It took #{toc - tic} millisecond (or #{(toc - tic) / 1000} seconds).")

      IO.puts(
        "Total actions per second = #{
          (:ets.info(:tweet_dB, :size) + extra_activities) / ((toc - tic) / 1000)
        }"
      )

      System.halt(1)
    end

    {:noreply, {extra_activities, clientsCompleted + 1, numClients}}
  end

  def send_if_alive(follower, sender, msg, tweetid, extra_activities, retweet_testing) do
    status = :ets.lookup_element(:user_dB, follower, 4)

    if status == "connected" do
      if retweet_testing == 0 do
        GenServer.cast(
          String.to_atom("client_" <> Integer.to_string(follower)),
          {:on_the_feed, sender, msg, 0}
        )
      else
        GenServer.cast(
          String.to_atom("client_" <> Integer.to_string(follower)),
          {:on_the_feed, sender, msg, 1}
        )
      end
    else
      old_msgq = :ets.lookup_element(:msgQueue_dB, follower, 2)
      new_msgq = old_msgq ++ [tweetid]
      :ets.update_element(:msgQueue_dB, follower, {2, new_msgq})
    end
  end

  def updateHashTagDB(tweetid, msg) do
    hashregex = ~r/\#\w*/
    tags = List.flatten(Regex.scan(hashregex, msg))

    Enum.map(tags, fn x ->
      if :ets.insert_new(:hashtag_dB, {x, [tweetid]}) == false do
        :ets.update_element(
          :hashtag_dB,
          x,
          {2, [tweetid] ++ List.flatten(:ets.match(:hashtag_dB, {x, :"$1"}))}
        )
      end
    end)
  end

  def updateMentionsDB(tweetid, msg) do
    hashregex = ~r/\@\w*/
    tags = List.flatten(Regex.scan(hashregex, msg))

    Enum.map(tags, fn x ->
      if :ets.insert_new(:mentions_dB, {x, [tweetid]}) == false do
        :ets.update_element(
          :mentions_dB,
          x,
          {2, [tweetid] ++ List.flatten(:ets.match(:mentions_dB, {x, :"$1"}))}
        )
      end
    end)
  end

  def analyze(msg) do
    if Veritaserum.analyze(msg) >= 0 do
        true
    else
        false
    end
  end

end
