# Train Scheduling System
Implemented an client-server application in C++ in Linux using a MySQL database in which the information is loaded from JSON files  
Works like a shell with the following commands:  
 - register [username] [password]  
 - login [username] [password]  
 - all  
 - all-between [station] [station]  
 - departures-from [station]  
 - departures-after [hour]  
 - departures-between [hour] [hour]  
 - arrivals-from [station]  
 - arrivals-after [hour]  
 - arrivals-between [hour] [hour]  
 - route [train]  
 - delay [train] [minutes]  
Compile the project with the following commands:  
 - server: g++ -Wdeprecated -pthread -I /usr/include -isystem /usr/include/cppconn main.cpp -o main -l mysqlcppconn  
 - client: g++ main.cpp -o main
