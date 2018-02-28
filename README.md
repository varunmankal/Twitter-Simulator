##################################
########## PROJECT 4 #############
### TWITTER SIMULATOR - PART I ###
##################################

########### Team Members ################
### Raheen Mazgaonkar, UFID: 47144316 ###
### Varun Mankal, UFID: 04827615 ########
#########################################

Since client simulator and server engine run on different nodes, the two processes have to be implemented on different terminals by passing appropriate parameters:

1) To start server engine run the following command:
./project4_1 server 
Example: ./project4_1 server

2) To start the client simulator run the following command:
./project4_1 client "no of clients" "No of tweets to be sent by most popular client".
Example: ./project4_1 client 1000 100

In order to maintain the zipf implementation, the no of clients parameter is rounded off to the nearest 100th value.
The program will run till all the clients send their required amount of tweets (calculated based on zipf distribution).

On completion it will return the following parameters:

1) On server side it will return the no of requests handled per second. 
Note: As no of tweets/sec sent by per type of client is constant, this parameter is dependant on no of clients.


2) On client side it will return the total number of requests sent and no of live tweets received (Not counting tweets received on querying). 
Note: This parameter is dependant on "no of clients" "No of tweets sent by most popular client". 
      Due to difference in periods of live connection in different runs, no of live tweets received may differ. 
       

Note: 
For running a node on a machine we need to know the IP address of the machine. This can be done using :inet.getif() function. 
However, even with this function the position where the local IP is returned might differ in different machines. 
The node at which the client and server is started is printed at the start of the program. If it is incorrect and an error is received please make changes in the following lines.
I) Server.ex: line 6 
Ii) Client.ex: line 6 & line 16

2) In order for a node to start the epmd daemon must be running. If it is not running, an error will be received
In order to avoid this, start the epmd daemon in ubuntu systems as follows:
epmd -deamon


For implementation details, please refer report.
