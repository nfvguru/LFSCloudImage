/* spawnvpn.c
*
 * This program will spawn '/usr/sbin/openvpn --config file' for each file
 * in /etc/openvpn. It will look for sigchld and respawn as needed. It will
 * also look for sighup and re-read the directory as needed.
 *
 */

#include <sys/types.h>
#include <signal.h>
#include <unistd.h>
#include "childinfo.h"
#include <stdio.h>
#include <string.h>

char config_path[128];
char program_path[128];

void usage() 
{
    printf("usage: spawnvpn --config config_path --path openvpn_binary_path\n");

}

void hupchild(pid_t child){
	kill(child, SIGTERM);
}

// This runs as the child process
void spawnchild(char *file){
	printf("file is %s\n",file);
        char program_path[128]="/opt/ssloffloader2.0/ssloffloader -f";
	char config_path[128]="/opt/ssloffloader2.0/ssloffload.cfg";
	char program[512];
	if (!strstr (file,"/opt/cloudport5.4/app.coffee")) {
		fprintf (stderr,"skipping %s, not a VPN configuration file!\n",file);
		return;
	}
	fprintf (stderr,"Starting a child VPN process with %s\n",file);
	printf("preogram path%s\n",program_path);
 	//system("/opt/ssloffloader2.0/ssloffloader -f /opt/ssloffloader2.0/ssloffload.cfg -d");
 	system("coffee /opt/cloudport5.4/app.coffee");
// 	system("/opt/haproxy2.0/haproxy -f /opt/haproxy2.0/sample.cfg -d");
	//execl(program_path,program_path,config_path, (char *)NULL);
//	execl(program_path,config_path, (char *)NULL);
	//execl("/opt/haproxy21.0/haproxy -f","/opt/haproxy21.0/haproxy -f","/opt/haproxy2.0/sample.cfg", (char *)NULL);
	//execl("/opt/haproxy2.0/haproxy -f","/opt/haproxy2.0/sample.cfg", (char *)NULL);
        //system("sudo touch /config/openvpn/on");
	//execl("/opt/openvpn2.0/openvpn","", "/opt/openvpn2.0/server.conf", (char *)NULL);
	close(0);
	close(1);
	close(2);

	printf("befor program path%d\n",program_path[0]);
        if (program_path[0]) {
	//	printf("inside program_path\n");
         //   sprintf(program, "%s%s", program_path, "/opt/loadbalancer2.0/"); 
         //   printf(program, "%s%s", program_path, "/opt/loadbalancer2.0/"); 
	    execl(program, "loadbalancer -f",  "--config", file, "--syslog", file, (char *)NULL);
        } else {
		printf("inside else\n");
	    execl("/opt/loadbalancer2.0/", "loadbalancer",  "--config", file, "--syslog", file, (char *)NULL);
        }
	//close(0);close(1);close(2);
}

/*
 **use the "pgrep spawnvpn" shell command to check there is  spawnvpn process or not !
 **if yes  return 1  ,
 **or not retrun  0 ;
 */
int check_spawnvpn_process( void )
{
	FILE   *stream = NULL ;
	char   buf[32];
	int len = 0 ;
	int enternum = 0 ;  
	unsigned int freadret;

	memset( buf, '\0', sizeof(buf) );
	stream = popen( "pgrep spawncp", "r" );

	freadret = fread( buf, sizeof(char), sizeof(buf), stream);   // read the stream to buf . 
	pclose( stream );
	
	//printf("the buf is %s\n",buf) ;
	len = strlen( buf ) ; 
	if( len != 0 )  //if there is spawnvpn process . 
	{	
		int i = 0 ; 
		for( i=0;i<len;i++)
		{
			if( isspace( buf[i]) )
			{
				enternum += 1 ; 
			}
		}
		//this becauce when run from main to here . the new process's pid  is allocated .
		//if enternum >= 2 , this is mean the spawnvpn is to run again . 
		if( enternum >= 2 )
		{
			return 1 ; 
		}
		else
		{
			return 0 ;
		}

	}

}


int main(int argc, char **argv){
	int loop_flag = -1 ;   //this is marked . 


        /* Check the optinal arguments. If the options has config file and path of openvpn binary, use it */
        if (argc >= 3) {
            if (!strcmp(argv[1], "--config_path")) {
                if (strlen(argv[2]) >= sizeof(config_path)) {
                    fprintf(stderr, "Error: Cannot accept config string size greater than %ld bytes\n", (unsigned long)(sizeof(config_path))); 
                    usage();
                    return(-1);
                }
                strncpy(config_path, argv[2], strlen(argv[2]));
                if (argc <= 5 && argc > 3) {
                    if (!strcmp(argv[3], "--binary_path")) {
                        if (strlen(argv[4]) >= sizeof(program_path)) { 
                            fprintf(stderr, "Error:cannot accept program path string size greater than %ld bytes\n",(unsigned long)(sizeof(program_path)));
                            usage();
                            return(-1);
                        }
                        strncpy(program_path, argv[4], strlen(argv[4]));
                        fprintf(stderr, "program path is %s config path is %s\n", program_path, config_path); 
                    }   
                }
            } else {
                fprintf(stderr, "Ignored: Currently spawnvpn does not support such a configuration");
            }
        }
             
                  
	loop_flag = check_spawnvpn_process() ;
	//if no spawnvpn process ,go  into the follow while(1) loop . 
	//if there is spawnvpn process  exit !
	if( !loop_flag )    
	{
		printf("config paht%c\n",config_path[128]);
		//childinfo_init((config_path[0])?config_path:"/config/openvpn", &spawnchild, &hupchild);
		childinfo_init((config_path[0])?config_path:"/opt/cloudport5.4", &spawnchild, &hupchild);
		while (1){
		        childinfo_sync();
			childinfo_spawn();
			sleep(1);
		}
	}
}
