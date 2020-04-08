#include <arpa/inet.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <netinet/in.h>
#include <string>
#include <sys/socket.h>
#include <unistd.h>
#include <vector>

#define STDIN                       0

#define MAXIMUM_COMMAND_LENGTH      512
#define MAXIMUM_ANSWER_LENGTH       8192

#define FLUSH                       fflush(stdout);
#define MEMSET(buffer)              memset(buffer, 0, sizeof(buffer));

#define EXITED                      "Exited"

#define CHECK(result, error_message, error_code) \
    if (result < 0) \
    { \
        perror(error_message); \
        return error_code; \
    }

#define SEND_MESSAGE(descriptor, message, bytes_error, message_error) \
    bytes = strlen(message); \
    CHECK(write(descriptor, &bytes, sizeof(bytes)), bytes_error, WRITE); \
    CHECK(write(descriptor, message, bytes), message_error, WRITE);
#define RECEIVE_MESSAGE(descriptor, message, bytes_error, message_error) \
    bytes = 0; \
    CHECK(read(descriptor, &bytes, sizeof(bytes)), bytes_error, READ); \
    CHECK(read(descriptor, *message, bytes), message_error, READ);

#define CLOSE(descriptor, error_message) \
    if (close(descriptor) != 0) \
    { \
        perror(error_message); \
        return CLOSE; \
    }

using namespace std;

enum errors
{
    SOCKET,
    CONNECT,
    READ,
    WRITE,
    CLOSE
};

void show_commands()
{
    printf("Commands:\n");
    printf("\t%-20s%-12s%-12s\n", "register", "<username>", "<password>");
    printf("\t%-20s%-12s%-12s\n", "login", "<username>", "<password>");
    printf("\tall\n");
    printf("\t%-20s%-12s%-12s\n", "all-between", "<station>", "<station>");
    printf("\t%-20s%-12s\n", "departures-from", "<station>");
    printf("\t%-20s%-12s\n", "departures-after", "<hour>");
    printf("\t%-20s%-12s%-12s\n", "departures-between", "<hour>", "<hour>");
    printf("\t%-20s%-12s\n", "arrivals-to", "<station>");
    printf("\t%-20s%-12s\n", "arrivals-after", "<hour>");
    printf("\t%-20s%-12s%-12s\n", "arrivals-between", "<hour>", "<hour>");
    printf("\t%-20s%-12s\n", "route", "<train>");
    printf("\t%-20s%-12s%-12s\n", "delay", "<train>", "<minutes>");
    printf("\texit\n");
    FLUSH;
}

int main(int argc, char** argv)
{
    if (argc < 4)
    {
        printf("syntax: %s <address> <port> <type>\n", argv[0]);
        FLUSH;
        return -1;
    }
    int port = atoi(argv[2]);
    int socket_descriptor = socket(AF_INET, SOCK_STREAM, 0);
    CHECK(socket_descriptor, "[client] create socket", SOCKET);
    sockaddr_in server{};
    memset(&server, 0, sizeof(server));
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = inet_addr(argv[1]);
    server.sin_port = htons(port);
    CHECK(connect(socket_descriptor, (sockaddr*)&server, sizeof(sockaddr)), "[client] connect", CONNECT);
    printf("[client] connected to port %d\n", port);
    FLUSH;
    unsigned int bytes;
    char answer[MAXIMUM_ANSWER_LENGTH];
    int type = atoi(argv[3]);
    if (type == 1)
    {
        show_commands();
        char command[MAXIMUM_COMMAND_LENGTH];
        while (true)
        {
            printf("command> ");
            FLUSH;
            MEMSET(command);
            CHECK(read(STDIN, command, MAXIMUM_COMMAND_LENGTH), "[client] read command", READ);
            command[strlen(command) - 1] = '\0';
            SEND_MESSAGE(socket_descriptor, command, "[client] write command bytes", "[client] write command message");
            MEMSET(answer);
            RECEIVE_MESSAGE(socket_descriptor, &answer, "[client] read answer bytes", "[client] read answer message");
            printf("%s\n", answer);
            FLUSH;
            if (strcmp(answer, EXITED) == 0)
            {
                break;
            }
        }
    }
    else if (type == 2)
    {
        vector<string> commands;
        commands.emplace_back("register georgiana_ojoc 3007");
        commands.emplace_back("login administrator ?Kv8H");
        commands.emplace_back("all");
        commands.emplace_back("all-between Iasi Tecuci");
        commands.emplace_back("departures-from Crasna");
        commands.emplace_back("departures-after 15");
        commands.emplace_back("departures-between 12 21");
        commands.emplace_back("arrivals-to Buzau");
        commands.emplace_back("arrivals-after 17");
        commands.emplace_back("arrivals-between 6 11");
        commands.emplace_back("route 1662");
        commands.emplace_back("delay 1838 5");
        commands.emplace_back("exit");
        for (auto command : commands)
        {
            SEND_MESSAGE(socket_descriptor, command.c_str(), "[client] write command bytes", "[client] write command message");
            MEMSET(answer);
            RECEIVE_MESSAGE(socket_descriptor, &answer, "[client] read answer bytes", "[client] read answer message");
            printf("%s\n", answer);
            FLUSH;
            if (strcmp(answer, EXITED) == 0)
            {
                break;
            }
        }
    }
    CLOSE(socket_descriptor, "[client] close socket");
    return 0;
}