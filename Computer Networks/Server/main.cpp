#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <driver.h>
#include <exception.h>
#include <memory>
#include <mutex>
#include <netinet/in.h>
#include <prepared_statement.h>
#include <pthread.h>
#include <queue>
#include <resultset.h>
#include <statement.h>
#include <string>
#include <sys/socket.h>
#include <unistd.h>

#define DATABASE                    "train_schedule"
#define ADMIN                       "administrator"
#define PASSWORD                    "?Kv8H"

#define BACKLOG                     5
#define THREADS                     100

#define MAXIMUM_REQUEST_LENGTH      512
#define MAXIMUM_LINE_LENGTH         512

#define REGISTER                    "register"
#define LOGIN                       "login"
#define ALL                         "all"
#define ALL_BETWEEN                 "all-between"
#define DEPARTURES_FROM             "departures-from"
#define DEPARTURES_AFTER            "departures-after"
#define DEPARTURES_BETWEEN          "departures-between"
#define ARRIVALS_TO                 "arrivals-to"
#define ARRIVALS_AFTER              "arrivals-after"
#define ARRIVALS_BETWEEN            "arrivals-between"
#define ROUTE                       "route"
#define DELAY                       "delay"
#define EXIT                        "exit"
#define EXITED                      "Exited"
#define UNKNOWN                     "Unknown command"

#define FLUSH                       fflush(stdout);
#define MEMSET(buffer)              memset(buffer, 0, sizeof(buffer));

#define CHECK_CONTINUE(result, error_message) \
    if ((result) < 0) \
    { \
        perror(error_message); \
        continue; \
    }

#define CHECK_RETURN(result, error_message, error_code) \
    if ((result) < 0) \
    { \
        perror(error_message); \
        return error_code; \
    }

#define CHECK_RETURN_THREAD(result, ID, error_message, error_code) \
    if ((result) < 0) \
    { \
        printf("[server thread %d] ", ID); \
        FLUSH; \
        perror(error_message); \
        return error_code; \
    }

#define CHECK_THREAD(result, ID, error_message) \
    if ((result) != 0) \
    { \
        printf("[server thread %d] ", ID); \
        FLUSH; \
        perror(error_message); \
    }

#define CLOSE_THREAD(descriptor, ID, error_message) \
    CHECK_RETURN_THREAD(close(descriptor), ID, error_message, CLOSE);

#define SEND_MESSAGE(descriptor, message, ID, bytes_error, message_error) \
    bytes = strlen(message); \
    CHECK_RETURN_THREAD(write(descriptor, &bytes, sizeof(bytes)), ID, bytes_error, WRITE); \
    CHECK_RETURN_THREAD(write(descriptor, message, bytes), ID, message_error, WRITE);

#define RECEIVE_MESSAGE(descriptor, message, ID, bytes_error, message_error) \
    bytes = 0; \
    CHECK_RETURN_THREAD(read(descriptor, &bytes, sizeof(bytes)), ID, bytes_error, READ); \
    CHECK_RETURN_THREAD(read(descriptor, *(message), bytes), ID, message_error, READ);

#define PARSE_SPACES(buffer) \
    if (parse_spaces(&(buffer)) != SUCCESS) \
    { \
        return UNKNOWN_COMMAND; \
    }

using namespace std;
using namespace sql;

struct _thread_data
{
    int thread_ID;
    int client_descriptor;
};

struct status
{
    bool isLoggedIn = false;
    bool isAdministrator = false;
};

struct _arguments
{
    string username;
    string password;
    string station1;
    string station2;
    int hour1;
    int hour2;
    string train;
    int minutes;
};

enum errors
{
    SUCCESS,
    SOCKET,
    SOCKET_OPTION,
    BIND,
    LISTEN,
    READ,
    WRITE,
    UNKNOWN_COMMAND,
    SPRINTF,
    SQL,
    CLOSE
};

enum _type
{
    _REGISTER,
    _LOGIN,
    _ALL,
    _ALL_BETWEEN,
    _DEPARTURES_FROM,
    _DEPARTURES_AFTER,
    _DEPARTURES_BETWEEN,
    _ARRIVALS_TO,
    _ARRIVALS_AFTER,
    _ARRIVALS_BETWEEN,
    _ROUTE,
    _DELAY,
    _EXIT,
    _UNKNOWN
};

string get_exception(SQLException exception)
{
    string message;
    message += exception.what();
    message += '\n';
    message += "(Error code: ";
    message += to_string(exception.getErrorCode());
    message += ", SQLState: ";
    message += exception.getSQLState();
    message += ')';
    return message;
}

void print_exception(SQLException exception)
{
    cout << "SQLException in file " << __FILE__;
    cout << ", in function " << __FUNCTION__ << ", on line " << __LINE__ << ": " << endl;
    cout << exception.what() << endl;
    cout << "(Error code: " << exception.getErrorCode();
    cout << ", SQLState: " << exception.getSQLState() << ')' << endl;
}

void initialize_users()
{
    try {
        Driver* driver;
        Connection* connection;
        Statement *statement;
        PreparedStatement* preparedStatement;
        driver = get_driver_instance();
        connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
        connection->setSchema(DATABASE); // connect to database
        statement = connection->createStatement();
        //statement->execute("DROP TABLE IF EXISTS users");
        statement->execute("CREATE TABLE IF NOT EXISTS users (username VARCHAR(32) PRIMARY KEY, password CHAR(40))");
        delete statement;
        preparedStatement = connection->prepareStatement("INSERT IGNORE INTO users VALUES ('administrator', SHA1(?))"); // placeholder
        preparedStatement->setString(1, PASSWORD);
        preparedStatement->executeUpdate();
        delete preparedStatement;
        delete connection;
    }
    catch (SQLException& exception)
    {
        print_exception(exception);
    }
}

void initialize_trains()
{
    try {
        Driver* driver;
        Connection* connection;
        Statement *statement;
        driver = get_driver_instance();
        connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
        connection->setSchema(DATABASE); // connect to database
        statement = connection->createStatement();
        statement->execute("DROP TABLE IF EXISTS departures");
        statement->execute("CREATE TABLE IF NOT EXISTS departures (id INTEGER AUTO_INCREMENT PRIMARY KEY, number CHAR(4), "
                           "departure_station VARCHAR(40) NOT NULL DEFAULT '', "
                           "first_station INTEGER NOT NULL DEFAULT 0, line CHAR(2) NOT NULL DEFAULT '1A', "
                           "departure_time TIME NOT NULL DEFAULT '00:00:00', "
                           "delay INTEGER NOT NULL DEFAULT 0, ETD TIME NOT NULL DEFAULT '00:00:00')");
        statement->execute("INSERT IGNORE INTO departures (number, departure_station, first_station, line, departure_time, delay, ETD)  SELECT number, departure_station, first_station, line, departure_time, delay, departure_time FROM departures_imports");
        statement->execute("DROP TABLE IF EXISTS arrivals");
        statement->execute("CREATE TABLE IF NOT EXISTS arrivals (id INTEGER AUTO_INCREMENT PRIMARY KEY, number CHAR(4), "
                           "arrival_station VARCHAR(40) NOT NULL DEFAULT '', "
                           "last_station INTEGER NOT NULL DEFAULT 0, line CHAR(2) NOT NULL DEFAULT '1A', "
                           "arrival_time TIME NOT NULL DEFAULT '00:00:00', "
                           "delay INTEGER NOT NULL DEFAULT 0, ETA TIME NOT NULL DEFAULT '00:00:00')");
        statement->execute("INSERT IGNORE INTO arrivals (number, arrival_station, last_station, line, arrival_time, delay, ETA)  SELECT number, arrival_station, last_station, line, arrival_time, delay, arrival_time FROM arrivals_imports");
        delete statement;
        delete connection;
    }
    catch (SQLException& exception)
    {
        print_exception(exception);
    }
}

status clients[THREADS];

class Command
{
public:
    virtual errors execute() = 0;
    virtual int getThreadID() = 0;
};

class Register : public Command
{
    _thread_data    threadData;
    string          username;
    string          password;
public:
    Register(_thread_data newThreadData, string newUsername, string newPassword)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        username = newUsername;
        password = newPassword;
    }
    errors execute() override
    {
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("INSERT INTO users VALUES (?, SHA1(?))"); // placeholder
            preparedStatement->setString(1, username.c_str());
            preparedStatement->setString(2, password.c_str());
            preparedStatement->executeUpdate();
            delete preparedStatement;
            delete connection;
            string message;
            message += "Registered ";
            message += username;
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "Register ";
            message += username;
            message += ":\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Username already registered", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class Login : public Command
{
    _thread_data    threadData;
    string          username;
    string          password;
public:
    Login(_thread_data newThreadData, string newUsername, string newPassword)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        username = newUsername;
        password = newPassword;
    }
    errors execute() override
    {
        if (clients[threadData.thread_ID].isLoggedIn)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Already logged in", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Already logged in\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("SELECT '' FROM users WHERE username=? AND password=SHA1(?)"); // placeholder
            preparedStatement->setString(1, username.c_str());
            preparedStatement->setString(2, password.c_str());
            resultSet = preparedStatement->executeQuery();
            if (!resultSet->next())
            {
                delete resultSet;
                delete preparedStatement;
                delete connection;
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "Username or password not found", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Username or password not found\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                delete resultSet;
                delete preparedStatement;
                delete connection;
                clients[threadData.thread_ID].isLoggedIn = true;
                if (username == ADMIN)
                {
                    clients[threadData.thread_ID].isAdministrator = true;
                }
                string message;
                message += "Logged in ";
                message += username;
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "Login ";
            message += username;
            message += ":\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class All : public Command
{
    _thread_data threadData;
public:
    All(_thread_data newThreadData)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
    }
    errors execute() override
    {
        if (!clients[threadData.thread_ID].isLoggedIn)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Not logged in", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Not logged in\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            Statement* statement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            statement = connection->createStatement();
            resultSet = statement->executeQuery("SELECT * FROM departures, arrivals WHERE departures.number=arrivals.number AND first_station+last_station=2 ORDER BY ETD, ETA");
            string answer;
            char line[MAXIMUM_LINE_LENGTH];
            CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10s%-10s%-10s\n", "Number", "Departure station", "Arrival station",
                    "Line", "Departure time", "Arrival time", "Delay", "ETD", "ETA"), threadData.thread_ID, "sprintf", SPRINTF);
            answer += line;
            bool found = false;
            while (resultSet->next())
            {
                CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10d%-10s%-10s\n", resultSet->getString("number").c_str(), resultSet->getString("departure_station")->c_str(),
                        resultSet->getString("arrival_station")->c_str(), resultSet->getString("line").c_str(), resultSet->getString("departure_time").c_str(), resultSet->getString("arrival_time").c_str(),
                        resultSet->getInt("delay"), resultSet->getString("ETD").c_str(), resultSet->getString("ETA").c_str()), threadData.thread_ID, "sprintf", SPRINTF);
                answer += line;
                found = true;
            }
            delete resultSet;
            delete statement;
            delete connection;
            if (!found)
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "No entries found", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] No entries found\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, answer.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Selected all\n", threadData.thread_ID);
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "All:\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class AllBetween : public Command
{
    _thread_data    threadData;
    string          station1;
    string          station2;
public:
    AllBetween(_thread_data newThreadData, string newStation1, string newStation2)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        station1 = newStation1;
        station2 = newStation2;
    }
    errors execute() override
    {
        if (!clients[threadData.thread_ID].isLoggedIn)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Not logged in", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Not logged in\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("SELECT * FROM departures, arrivals WHERE departures.number=arrivals.number AND departure_station=? AND arrival_station=? ORDER BY ETD, ETA");
            preparedStatement->setString(1, station1.c_str());
            preparedStatement->setString(2, station2.c_str());
            resultSet = preparedStatement->executeQuery();
            string answer;
            char line[MAXIMUM_LINE_LENGTH];
            CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10s%-10s%-10s\n", "Number", "Departure station", "Arrival station",
                                        "Line", "Departure time", "Arrival time", "Delay", "ETD", "ETA"), threadData.thread_ID, "sprintf", SPRINTF);
            answer += line;
            bool found = false;
            while (resultSet->next())
            {
                CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10d%-10s%-10s\n", resultSet->getString("number").c_str(), resultSet->getString("departure_station")->c_str(),
                                            resultSet->getString("arrival_station")->c_str(), resultSet->getString("line").c_str(), resultSet->getString("departure_time").c_str(), resultSet->getString("arrival_time").c_str(),
                                            resultSet->getInt("delay"), resultSet->getString("ETD").c_str(), resultSet->getString("ETA").c_str()), threadData.thread_ID, "sprintf", SPRINTF);
                answer += line;
                found = true;
            }
            delete resultSet;
            delete preparedStatement;
            delete connection;
            if (!found)
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "No entries found", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] No entries found\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, answer.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Selected all between %s and %s\n", threadData.thread_ID, station1.c_str(), station2.c_str());
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "All between ";
            message += station1;
            message += " and ";
            message += station2;
            message += ":\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class DeparturesFrom : public Command
{
    _thread_data    threadData;
    string          station1;
public:
    DeparturesFrom(_thread_data newThreadData, string newStation1)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        station1 = newStation1;
    }
    errors execute() override
    {
        if (!clients[threadData.thread_ID].isLoggedIn)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Not logged in", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Not logged in\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("SELECT * FROM departures, arrivals WHERE departures.number=arrivals.number AND departure_station=? AND last_station=1 ORDER BY ETD, ETA");
            preparedStatement->setString(1, station1.c_str());
            resultSet = preparedStatement->executeQuery();
            string answer;
            char line[MAXIMUM_LINE_LENGTH];
            CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10s%-10s%-10s\n", "Number", "Departure station", "Arrival station",
                                        "Line", "Departure time", "Arrival time", "Delay", "ETD", "ETA"), threadData.thread_ID, "sprintf", SPRINTF);
            answer += line;
            bool found = false;
            while (resultSet->next())
            {
                CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10d%-10s%-10s\n", resultSet->getString("number").c_str(), resultSet->getString("departure_station")->c_str(),
                                            resultSet->getString("arrival_station")->c_str(), resultSet->getString("line").c_str(), resultSet->getString("departure_time").c_str(), resultSet->getString("arrival_time").c_str(),
                                            resultSet->getInt("delay"), resultSet->getString("ETD").c_str(), resultSet->getString("ETA").c_str()), threadData.thread_ID, "sprintf", SPRINTF);
                answer += line;
                found = true;
            }
            delete resultSet;
            delete preparedStatement;
            delete connection;
            if (!found)
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "No entries found", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] No entries found\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, answer.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Selected departures from %s\n", threadData.thread_ID, station1.c_str());
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "Departures from ";
            message += station1;
            message += ":\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class DeparturesAfter : public Command
{
    _thread_data    threadData;
    int             hour1;
public:
    DeparturesAfter(_thread_data newThreadData, int newHour1)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        hour1 = newHour1;
    }
    errors execute() override
    {
        if (!clients[threadData.thread_ID].isLoggedIn)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Not logged in", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Not logged in\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("SELECT * FROM departures, arrivals WHERE departures.number=arrivals.number AND HOUR(ETD)>=? AND last_station=1 ORDER BY ETD, ETA");
            preparedStatement->setInt(1, hour1);
            resultSet = preparedStatement->executeQuery();
            string answer;
            char line[MAXIMUM_LINE_LENGTH];
            CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10s%-10s%-10s\n", "Number", "Departure station", "Arrival station",
                                        "Line", "Departure time", "Arrival time", "Delay", "ETD", "ETA"), threadData.thread_ID, "sprintf", SPRINTF);
            answer += line;
            bool found = false;
            while (resultSet->next())
            {
                CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10d%-10s%-10s\n", resultSet->getString("number").c_str(), resultSet->getString("departure_station")->c_str(),
                                            resultSet->getString("arrival_station")->c_str(), resultSet->getString("line").c_str(), resultSet->getString("departure_time").c_str(), resultSet->getString("arrival_time").c_str(),
                                            resultSet->getInt("delay"), resultSet->getString("ETD").c_str(), resultSet->getString("ETA").c_str()), threadData.thread_ID, "sprintf", SPRINTF);
                answer += line;
                found = true;
            }
            delete resultSet;
            delete preparedStatement;
            delete connection;
            if (!found)
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "No entries found", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] No entries found\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, answer.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Selected departures after %d\n", threadData.thread_ID, hour1);
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "Departures after ";
            message += to_string(hour1);
            message += ":\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class DeparturesBetween : public Command
{
    _thread_data    threadData;
    int             hour1;
    int             hour2;
public:
    DeparturesBetween(_thread_data newThreadData, int newHour1, int newHour2)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        hour1 = newHour1;
        hour2 = newHour2;
    }
    errors execute() override
    {
        if (!clients[threadData.thread_ID].isLoggedIn)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Not logged in", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Not logged in\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("SELECT * FROM departures, arrivals WHERE departures.number=arrivals.number AND HOUR(ETD)>=? AND HOUR(ETD)<=? AND last_station=1 ORDER BY ETD, ETA");
            preparedStatement->setInt(1, hour1);
            preparedStatement->setInt(2, hour2);
            resultSet = preparedStatement->executeQuery();
            string answer;
            char line[MAXIMUM_LINE_LENGTH];
            CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10s%-10s%-10s\n", "Number", "Departure station", "Arrival station",
                                        "Line", "Departure time", "Arrival time", "Delay", "ETD", "ETA"), threadData.thread_ID, "sprintf", SPRINTF);
            answer += line;
            bool found = false;
            while (resultSet->next())
            {
                CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10d%-10s%-10s\n", resultSet->getString("number").c_str(), resultSet->getString("departure_station")->c_str(),
                                            resultSet->getString("arrival_station")->c_str(), resultSet->getString("line").c_str(), resultSet->getString("departure_time").c_str(), resultSet->getString("arrival_time").c_str(),
                                            resultSet->getInt("delay"), resultSet->getString("ETD").c_str(), resultSet->getString("ETA").c_str()), threadData.thread_ID, "sprintf", SPRINTF);
                answer += line;
                found = true;
            }
            delete resultSet;
            delete preparedStatement;
            delete connection;
            if (!found)
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "No entries found", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] No entries found\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, answer.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Selected departures between %d and %d\n", threadData.thread_ID, hour1, hour2);
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "Departures between ";
            message += to_string(hour1);
            message += " and ";
            message += to_string(hour2);
            message += ":\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class ArrivalsTo : public Command
{
    _thread_data    threadData;
    string          station1;
public:
    ArrivalsTo(_thread_data newThreadData, string newStation1)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        station1 = newStation1;
    }
    errors execute() override
    {
        if (!clients[threadData.thread_ID].isLoggedIn)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Not logged in", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Not logged in\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("SELECT * FROM departures, arrivals WHERE departures.number=arrivals.number AND arrival_station=? AND first_station=1 ORDER BY ETA, ETD");
            preparedStatement->setString(1, station1.c_str());
            resultSet = preparedStatement->executeQuery();
            string answer;
            char line[MAXIMUM_LINE_LENGTH];
            CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10s%-10s%-10s\n", "Number", "Departure station", "Arrival station",
                                        "Line", "Departure time", "Arrival time", "Delay", "ETD", "ETA"), threadData.thread_ID, "sprintf", SPRINTF);
            answer += line;
            bool found = false;
            while (resultSet->next())
            {
                CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10d%-10s%-10s\n", resultSet->getString("number").c_str(), resultSet->getString("departure_station")->c_str(),
                                            resultSet->getString("arrival_station")->c_str(), resultSet->getString("line").c_str(), resultSet->getString("departure_time").c_str(), resultSet->getString("arrival_time").c_str(),
                                            resultSet->getInt("delay"), resultSet->getString("ETD").c_str(), resultSet->getString("ETA").c_str()), threadData.thread_ID, "sprintf", SPRINTF);
                answer += line;
                found = true;
            }
            delete resultSet;
            delete preparedStatement;
            delete connection;
            if (!found)
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "No entries found", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] No entries found\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, answer.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Selected arrivals to %s\n", threadData.thread_ID, station1.c_str());
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "Arrivals to ";
            message += station1;
            message += ":\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class ArrivalsAfter : public Command
{
    _thread_data    threadData;
    int             hour1;
public:
    ArrivalsAfter(_thread_data newThreadData, int newHour1)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        hour1 = newHour1;
    }
    errors execute() override
    {
        if (!clients[threadData.thread_ID].isLoggedIn)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Not logged in", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Not logged in\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("SELECT * FROM departures, arrivals WHERE departures.number=arrivals.number AND HOUR(ETA)>=? AND first_station=1 ORDER BY ETA, ETD");
            preparedStatement->setInt(1, hour1);
            resultSet = preparedStatement->executeQuery();
            string answer;
            char line[MAXIMUM_LINE_LENGTH];
            CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10s%-10s%-10s\n", "Number", "Departure station", "Arrival station",
                                        "Line", "Departure time", "Arrival time", "Delay", "ETD", "ETA"), threadData.thread_ID, "sprintf", SPRINTF);
            answer += line;
            bool found = false;
            while (resultSet->next())
            {
                CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10d%-10s%-10s\n", resultSet->getString("number").c_str(), resultSet->getString("departure_station")->c_str(),
                                            resultSet->getString("arrival_station")->c_str(), resultSet->getString("line").c_str(), resultSet->getString("departure_time").c_str(), resultSet->getString("arrival_time").c_str(),
                                            resultSet->getInt("delay"), resultSet->getString("ETD").c_str(), resultSet->getString("ETA").c_str()), threadData.thread_ID, "sprintf", SPRINTF);
                answer += line;
                found = true;
            }
            delete resultSet;
            delete preparedStatement;
            delete connection;
            if (!found)
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "No entries found", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] No entries found\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, answer.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Selected arrivals after %d\n", threadData.thread_ID, hour1);
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "Arrivals after ";
            message += to_string(hour1);
            message += ":\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class ArrivalsBetween : public Command
{
    _thread_data    threadData;
    int             hour1;
    int             hour2;
public:
    ArrivalsBetween(_thread_data newThreadData, int newHour1, int newHour2)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        hour1 = newHour1;
        hour2 = newHour2;
    }
    errors execute() override
    {
        if (!clients[threadData.thread_ID].isLoggedIn)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Not logged in", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Not logged in\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("SELECT * FROM departures, arrivals WHERE departures.number=arrivals.number AND HOUR(ETA)>=? AND HOUR(ETA)<=? AND first_station=1 ORDER BY ETA, ETD");
            preparedStatement->setInt(1, hour1);
            preparedStatement->setInt(2, hour2);
            resultSet = preparedStatement->executeQuery();
            string answer;
            char line[MAXIMUM_LINE_LENGTH];
            CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10s%-10s%-10s\n", "Number", "Departure station", "Arrival station",
                                        "Line", "Departure time", "Arrival time", "Delay", "ETD", "ETA"), threadData.thread_ID, "sprintf", SPRINTF);
            answer += line;
            bool found = false;
            while (resultSet->next())
            {
                CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10d%-10s%-10s\n", resultSet->getString("number").c_str(), resultSet->getString("departure_station")->c_str(),
                                            resultSet->getString("arrival_station")->c_str(), resultSet->getString("line").c_str(), resultSet->getString("departure_time").c_str(), resultSet->getString("arrival_time").c_str(),
                                            resultSet->getInt("delay"), resultSet->getString("ETD").c_str(), resultSet->getString("ETA").c_str()), threadData.thread_ID, "sprintf", SPRINTF);
                answer += line;
                found = true;
            }
            delete resultSet;
            delete preparedStatement;
            delete connection;
            if (!found)
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "No entries found", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] No entries found\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, answer.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Selected arrivals between %d and %d\n", threadData.thread_ID, hour1, hour2);
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "Arrivals between ";
            message += to_string(hour1);
            message += " and ";
            message += to_string(hour2);
            message += ":\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class Route : public Command
{
    _thread_data    threadData;
    string          train;
public:
    Route(_thread_data newThreadData, string newTrain)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        train = newTrain;
    }
    errors execute() override
    {
        if (!clients[threadData.thread_ID].isLoggedIn)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Not logged in", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Not logged in\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("SELECT * FROM departures NATURAL JOIN arrivals WHERE number=? ORDER BY ETD, ETA");
            preparedStatement->setString(1, train.c_str());
            resultSet = preparedStatement->executeQuery();
            string answer;
            char line[MAXIMUM_LINE_LENGTH];
            CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10s%-10s%-10s\n", "Number", "Departure station", "Arrival station",
                                        "Line", "Departure time", "Arrival time", "Delay", "ETD", "ETA"), threadData.thread_ID, "sprintf", SPRINTF);
            answer += line;
            bool found = false;
            while (resultSet->next())
            {
                CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10d%-10s%-10s\n", resultSet->getString("number").c_str(), resultSet->getString("departure_station")->c_str(),
                                            resultSet->getString("arrival_station")->c_str(), resultSet->getString("line").c_str(), resultSet->getString("departure_time").c_str(), resultSet->getString("arrival_time").c_str(),
                                            resultSet->getInt("delay"), resultSet->getString("ETD").c_str(), resultSet->getString("ETA").c_str()), threadData.thread_ID, "sprintf", SPRINTF);
                answer += line;
                found = true;
            }
            delete resultSet;
            delete preparedStatement;
            delete connection;
            if (!found)
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "No entries found", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] No entries found\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, answer.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Route for train %s\n", threadData.thread_ID, train.c_str());
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "Route for train ";
            message += train;
            message += ":\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

class Delay : public Command
{
    _thread_data    threadData;
    string          train;
    int             minutes;
public:
    Delay(_thread_data newThreadData, string newTrain, int newMinutes)
    {
        threadData.thread_ID = newThreadData.thread_ID;
        threadData.client_descriptor = newThreadData.client_descriptor;
        train = newTrain;
        minutes = newMinutes;
    }
    errors execute() override
    {
        if (!clients[threadData.thread_ID].isAdministrator)
        {
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, "Not logged in as administrator", threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] Not logged in as administrator\n", threadData.thread_ID);
            FLUSH;
            return SUCCESS;
        }
        try {
            Driver* driver;
            Connection* connection;
            PreparedStatement* preparedStatement;
            ResultSet* resultSet;
            driver = get_driver_instance();
            connection = driver->connect("tcp://127.0.0.1:3306", "root", ""); // create connection
            connection->setSchema(DATABASE); // connect to database
            preparedStatement = connection->prepareStatement("UPDATE departures SET delay=delay+?, ETD=ADDTIME(ETD, ?) WHERE number=? AND ETD>=CURRENT_TIME");
            preparedStatement->setInt(1, minutes);
            string minutes_format;
            minutes_format += to_string(minutes * 100);
            preparedStatement->setString(2, minutes_format.c_str());
            preparedStatement->setString(3, train.c_str());
            preparedStatement->executeUpdate();
            preparedStatement = connection->prepareStatement("UPDATE arrivals SET delay=delay+?, ETA=ADDTIME(ETA, ?) WHERE number=? AND ETA>=CURRENT_TIME");
            preparedStatement->setInt(1, minutes);
            preparedStatement->setString(2, minutes_format.c_str());
            preparedStatement->setString(3, train.c_str());
            preparedStatement->executeUpdate();
            preparedStatement = connection->prepareStatement("SELECT * FROM departures NATURAL JOIN arrivals WHERE number=? AND ETA > CURRENT_TIME ORDER BY ETD, ETA");
            preparedStatement->setString(1, train.c_str());
            resultSet = preparedStatement->executeQuery();
            string answer;
            char line[MAXIMUM_LINE_LENGTH];
            CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10s%-10s%-10s\n", "Number", "Departure station", "Arrival station",
                                        "Line", "Departure time", "Arrival time", "Delay", "ETD", "ETA"), threadData.thread_ID, "sprintf", SPRINTF);
            answer += line;
            bool found = false;
            while (resultSet->next())
            {
                CHECK_RETURN_THREAD(sprintf(line, "%-9s%-29s%-29s%-5s%-19s%-19s%-10d%-10s%-10s\n", resultSet->getString("number").c_str(), resultSet->getString("departure_station")->c_str(),
                                            resultSet->getString("arrival_station")->c_str(), resultSet->getString("line").c_str(), resultSet->getString("departure_time").c_str(), resultSet->getString("arrival_time").c_str(),
                                            resultSet->getInt("delay"), resultSet->getString("ETD").c_str(), resultSet->getString("ETA").c_str()), threadData.thread_ID, "sprintf", SPRINTF);
                answer += line;
                found = true;
            }
            delete resultSet;
            delete preparedStatement;
            delete connection;
            if (!found)
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, "No entries modified", threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] No entries modified\n", threadData.thread_ID);
                FLUSH;
            }
            else
            {
                unsigned int bytes;
                SEND_MESSAGE(threadData.client_descriptor, answer.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
                printf("[server thread %d] Modified delay for train %s with %d minutes\n", threadData.thread_ID, train.c_str(), minutes);
                FLUSH;
            }
            return SUCCESS;
        }
        catch (SQLException& exception)
        {
            string message;
            message += "Delay for train ";
            message += train;
            message += " with ";
            message += to_string(minutes);
            message += " minutes:\n";
            message += get_exception(exception);
            unsigned int bytes;
            SEND_MESSAGE(threadData.client_descriptor, message.c_str(), threadData.thread_ID, "write answer bytes", "write answer message");
            printf("[server thread %d] %s\n", threadData.thread_ID, message.c_str());
            FLUSH;
            return SQL;
        }
    }

    int getThreadID() override
    {
        return threadData.thread_ID;
    }
};

errors parse_spaces(char** string)
{
    while ((**string) == ' ')
    {
        ++(*string);
    }
    if ((**string) == '\0')
    {
        return UNKNOWN_COMMAND;
    }
    return SUCCESS;
}

errors set(char* command, _type& type, _arguments& arguments)
{
    PARSE_SPACES(command);
    if (strstr(command, REGISTER) == command)
    {
        type = _REGISTER;
        command += strlen(REGISTER);
        PARSE_SPACES(command);
        while (*command != ' ' && *command != '\0')
        {
            arguments.username += *(command++);
        }
        PARSE_SPACES(command);
        while (*command != ' ' && *command != '\0')
        {
            arguments.password += *(command++);
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, LOGIN) == command)
    {
        type = _LOGIN;
        command += strlen(LOGIN);
        PARSE_SPACES(command);
        while (*command != ' ' && *command != '\0')
        {
            arguments.username += *(command++);
        }
        PARSE_SPACES(command);
        while (*command != ' ' && *command != '\0')
        {
            arguments.password += *(command++);
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, EXIT) == command)
    {
        type = _EXIT;
        command += strlen(EXIT);
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, ALL_BETWEEN) == command)
    {
        type = _ALL_BETWEEN;
        command += strlen(ALL_BETWEEN);
        PARSE_SPACES(command);
        while (*command != ' ' && *command != '\0')
        {
            arguments.station1 += *(command++);
        }
        PARSE_SPACES(command);
        while (*command != ' ' && *command != '\0')
        {
            arguments.station2 += *(command++);
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, ALL) == command)
    {
        type = _ALL;
        command += strlen(ALL);
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, DEPARTURES_FROM) == command)
    {
        type = _DEPARTURES_FROM;
        command += strlen(DEPARTURES_FROM);
        PARSE_SPACES(command);
        while (*command != ' ' && *command != '\0')
        {
            arguments.station1 += *(command++);
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, DEPARTURES_AFTER) == command)
    {
        type = _DEPARTURES_AFTER;
        command += strlen(DEPARTURES_AFTER);
        PARSE_SPACES(command);
        string hour1;
        while (*command != ' ' && *command != '\0')
        {
            hour1 += *(command++);
        }
        try
        {
            arguments.hour1 = stoi(hour1);
        }
        catch (invalid_argument& exception)
        {
            return UNKNOWN_COMMAND;
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, DEPARTURES_BETWEEN) == command)
    {
        type = _DEPARTURES_BETWEEN;
        command += strlen(DEPARTURES_BETWEEN);
        PARSE_SPACES(command);
        string hour1;
        while (*command != ' ' && *command != '\0')
        {
            hour1 += *(command++);
        }
        try
        {
            arguments.hour1 = stoi(hour1);
        }
        catch (invalid_argument& exception)
        {
            return UNKNOWN_COMMAND;
        }
        PARSE_SPACES(command);
        string hour2;
        while (*command != ' ' && *command != '\0')
        {
            hour2 += *(command++);
        }
        try
        {
            arguments.hour2 = stoi(hour2);
        }
        catch (invalid_argument& exception)
        {
            return UNKNOWN_COMMAND;
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, ARRIVALS_TO) == command)
    {
        type = _ARRIVALS_TO;
        command += strlen(ARRIVALS_TO);
        PARSE_SPACES(command);
        while (*command != ' ' && *command != '\0')
        {
            arguments.station1 += *(command++);
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, ARRIVALS_AFTER) == command)
    {
        type = _ARRIVALS_AFTER;
        command += strlen(ARRIVALS_AFTER);
        PARSE_SPACES(command);
        string hour1;
        while (*command != ' ' && *command != '\0')
        {
            hour1 += *(command++);
        }
        try
        {
            arguments.hour1 = stoi(hour1);
        }
        catch (invalid_argument& exception)
        {
            return UNKNOWN_COMMAND;
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, ARRIVALS_BETWEEN) == command)
    {
        type = _ARRIVALS_BETWEEN;
        command += strlen(ARRIVALS_BETWEEN);
        PARSE_SPACES(command);
        string hour1;
        while (*command != ' ' && *command != '\0')
        {
            hour1 += *(command++);
        }
        try
        {
            arguments.hour1 = stoi(hour1);
        }
        catch (invalid_argument& exception)
        {
            return UNKNOWN_COMMAND;
        }
        PARSE_SPACES(command);
        string hour2;
        while (*command != ' ' && *command != '\0')
        {
            hour2 += *(command++);
        }
        try
        {
            arguments.hour2 = stoi(hour2);
        }
        catch (invalid_argument& exception)
        {
            return UNKNOWN_COMMAND;
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, ROUTE) == command)
    {
        type = _ROUTE;
        command += strlen(ROUTE);
        PARSE_SPACES(command);
        while (*command != ' ' && *command != '\0')
        {
            arguments.train += *(command++);
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    if (strstr(command, DELAY) == command)
    {
        type = _DELAY;
        command += strlen(DELAY);
        PARSE_SPACES(command);
        while (*command != ' ' && *command != '\0')
        {
            arguments.train += *(command++);
        }
        PARSE_SPACES(command);
        string minutes;
        while (*command != ' ' && *command != '\0')
        {
            minutes += *(command++);
        }
        try
        {
            arguments.minutes = stoi(minutes);
        }
        catch (invalid_argument& exception)
        {
            return UNKNOWN_COMMAND;
        }
        while (*command == ' ')
        {
            ++command;
        }
        if (*command != '\0')
        {
            return UNKNOWN_COMMAND;
        }
        return SUCCESS;
    }
    return UNKNOWN_COMMAND;
}

queue<Command*> commands;
mutex queue_mutex;

enum errors treat(_thread_data* thread_data)
{
    while (true)
    {
        unsigned int bytes;
        char request[MAXIMUM_REQUEST_LENGTH];
        MEMSET(request);
        RECEIVE_MESSAGE(thread_data->client_descriptor, &request, thread_data->thread_ID, "read request bytes", "read answer message");
        _type type;
        _arguments arguments;
        if (set(request, type, arguments) != SUCCESS)
        {
            SEND_MESSAGE(thread_data->client_descriptor, UNKNOWN, thread_data->thread_ID, "write answer bytes", "write answer message");
            continue;
        }
        switch (type)
        {
            case _REGISTER:
            {
                unique_ptr<Command> _register = make_unique<Register>(*thread_data, arguments.username, arguments.password);
                queue_mutex.lock();
                commands.push(_register.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _LOGIN:
            {
                unique_ptr<Command> login = make_unique<Login>(*thread_data, arguments.username, arguments.password);
                queue_mutex.lock();
                commands.push(login.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _EXIT:
            {
                SEND_MESSAGE(thread_data->client_descriptor, EXITED, thread_data->thread_ID, "write answer bytes", "write answer message");
                CLOSE_THREAD(thread_data->client_descriptor, thread_data->thread_ID, "client close");
                return SUCCESS;
            }
            case _ALL:
            {
                unique_ptr<Command> all = make_unique<All>(*thread_data);
                queue_mutex.lock();
                commands.push(all.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _ALL_BETWEEN:
            {
                unique_ptr<Command> all_between = make_unique<AllBetween>(*thread_data, arguments.station1, arguments.station2);
                queue_mutex.lock();
                commands.push(all_between.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _DEPARTURES_FROM:
            {
                unique_ptr<Command> departures_from = make_unique<DeparturesFrom>(*thread_data, arguments.station1);
                queue_mutex.lock();
                commands.push(departures_from.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _DEPARTURES_AFTER:
            {
                unique_ptr<Command> departures_after = make_unique<DeparturesAfter>(*thread_data, arguments.hour1);
                queue_mutex.lock();
                commands.push(departures_after.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _DEPARTURES_BETWEEN:
            {
                unique_ptr<Command> departures_between = make_unique<DeparturesBetween>(*thread_data, arguments.hour1, arguments.hour2);
                queue_mutex.lock();
                commands.push(departures_between.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _ARRIVALS_TO:
            {
                unique_ptr<Command> arrivals_to = make_unique<ArrivalsTo>(*thread_data, arguments.station1);
                queue_mutex.lock();
                commands.push(arrivals_to.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _ARRIVALS_AFTER:
            {
                unique_ptr<Command> arrivals_after = make_unique<ArrivalsAfter>(*thread_data, arguments.hour1);
                queue_mutex.lock();
                commands.push(arrivals_after.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _ARRIVALS_BETWEEN:
            {
                unique_ptr<Command> arrivals_between = make_unique<ArrivalsBetween>(*thread_data, arguments.hour1, arguments.hour2);
                queue_mutex.lock();
                commands.push(arrivals_between.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _ROUTE:
            {
                unique_ptr<Command> route = make_unique<Route>(*thread_data, arguments.train);
                queue_mutex.lock();
                commands.push(route.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            case _DELAY:
            {
                unique_ptr<Command> delay = make_unique<Delay>(*thread_data, arguments.train, arguments.minutes);
                queue_mutex.lock();
                commands.push(delay.get());
                Command* command = commands.front();
                commands.pop();
                queue_mutex.unlock();
                command->execute();
                break;
            }
            default:
                SEND_MESSAGE(thread_data->client_descriptor, UNKNOWN, thread_data->thread_ID, "write answer bytes", "write answer message");
        }
    }
}

void* execute(void* thread_ID)
{
    auto new_thread_ID = (int*)thread_ID;
    while (true)
    {
        if (!commands.empty())
        {
            queue_mutex.lock();
            Command* command = commands.front();
            commands.pop();
            queue_mutex.unlock();
            command->execute();
            printf("[server thread %d] Executed command for server thread %d\n", *new_thread_ID, command->getThreadID());
            FLUSH;

        }
    }
    return nullptr;
}

void* routine(void* thread_data)
{
    auto new_thread_data = (_thread_data*)thread_data;
    printf("[server thread %d] Accepted client\n", new_thread_data->thread_ID);
    FLUSH;
    CHECK_THREAD(pthread_detach(pthread_self()), new_thread_data->thread_ID, "thread detach"); // free resources
    if (treat(new_thread_data) != SUCCESS)
    {
        printf("[server thread %d] Unsolved client\n", new_thread_data->thread_ID);
    }
    else
    {
        printf("[server thread %d] Solved client\n", new_thread_data->thread_ID);
    }
    FLUSH;
    return nullptr;
}

int main(int argc, char** argv)
{
    if (argc < 2)
    {
        printf("syntax: %s <port>\n", argv[0]);
        FLUSH;
        return -1;
    }
    initialize_users();
    initialize_trains();
    int port = atoi(argv[1]);
    int socket_descriptor = socket(AF_INET, SOCK_STREAM, 0); // TCP, bidirectional bytes streaming
    CHECK_RETURN(socket_descriptor, "[server] socket create", SOCKET);
    int option = 1;
    CHECK_RETURN(setsockopt(socket_descriptor, SOL_SOCKET, SO_REUSEADDR, &option, sizeof(option)), "[server] socket option", SOCKET_OPTION); // socket layer
    sockaddr_in server{};
    memset(&server, 0, sizeof(server));
    server.sin_family = AF_INET; // IPv4,
    server.sin_addr.s_addr = htonl(INADDR_ANY); // localhost
    server.sin_port = htons(port);
    CHECK_RETURN(bind(socket_descriptor, (sockaddr*)&server, sizeof(sockaddr)), "[server] socket bind", BIND); // assign address to socket
    CHECK_RETURN(listen(socket_descriptor, BACKLOG), "[server] socket listen", LISTEN); // pending connections
    printf("[server] Waiting at port %d\n", port);
    FLUSH;
    sockaddr_in client{};
    memset(&client, 0, sizeof(client));
    int client_descriptor;
    socklen_t client_length = sizeof(client);
    //pthread_t execution;
    //int execution_ID = 0;
    //CHECK_THREAD(pthread_create(&execution, nullptr, &execute, (void*)&execution_ID), execution_ID, "thread create");
    pthread_t threads[THREADS];
    _thread_data threads_data[THREADS];
    int index = -1;
    while (true)
    {
        client_descriptor = accept(socket_descriptor, (sockaddr*)&client, &client_length); // connection
        CHECK_CONTINUE(client_descriptor, "[server] socket accept");
        ++index;
        threads_data[index].thread_ID = index + 1;
        threads_data[index].client_descriptor = client_descriptor;
        CHECK_THREAD(pthread_create(&threads[index], nullptr, &routine, (void*)&threads_data[index]), threads_data[index].thread_ID, "thread create");
    }
}