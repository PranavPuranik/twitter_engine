#  Project 4  - Twitter Engine
-------

Simulation of Twitter Engine in Elixir.

#### Group Members
------------
Subham Agrawal | UFID - 79497379
Pranav Puranik | UFID - 72038540

#### What is working
-------------
- We implemented the complete project as described by the problem statement.
- Both Twitter Server and Client are Genserver nodes. 
- Initially, all Clients registers with the Twitter-Server. 
- Then they subscribe each other based on Zipf distribution. Zipf depends on num of clients. Number of messages sent by each user is proportional to number of subscriber. Please check the report for more information.
- Next, we start the simulation. Each client can send tweets with hashtags and mentions, query tweets with his mentions, quey tweets with different hashtags, connect and disconnect with the server, or retweet what he subscribed to. 
- Once a user completes sending his tweets, he stops tweeting. 

We have also implemented the bonus, which is working well.

#### Mention all Functionalities that you implemented
-----

- Register and Delete Account.
- Subsribe to users (Zipf)
- Send Tweets with hashtags and mentions.
- Re-tweet
- Deliver tweets to live users. (also delivers tweets he subscribed to but couldn't receive when he was online)
- Query tweets with hashtags and client's own mentions

#### Mention all the test cases that you created
-----

1. REGISTRATION TESTING
2. RE_REGISTRATION TESTING
3. DELETE ACCOUNT TESTING 
4. TWEET TESTING
5. SENTIMENTAL ANALYSIS
6. TWEET FROM USER WITHOUT ACCOUNT TESTING
7. HASHTAG TESTING
8. MY MENTIONS TESTING
9. FINDING HASHTAG NEVER TWEETED TESTING 
10. FINDING MENTIONS NEVER MENTIONED TESTING
11. HASHTAGS AND MENTIONS BOTH
12. QUERY TWEETS WITH HASHTAG 
13. QUERY TWEETS WITH MY MENTIONS
14. SUBSCRIBER TESTING
15. RETWEET AND SUBSCRIBED USER RECEIVING MESSAGE TESTING
16. QUERY TWEETS FROM USERS SUBSCRIBED TO
17. LIVE TWEETS TEST (if user is subscribed)
18. LIVE DISCONNECTION AND RECONNECTION (if user is subscribed)

#### Steps to run
-------------
From the project directory run...

>$ mix run proj4 num_user num_msg

num_user - number of clients
num_msg - minimum messages that each

#### References
-------------
- Zipf - https://www.youtube.com/watch?v=9NvxDAUF_kI

