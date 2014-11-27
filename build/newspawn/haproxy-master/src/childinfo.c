/* childinfo.c
 *
 * This file contains the watchdog functions. The code spawns a child for each
 * item in a directory. On SIGUSR1, or any call to childinfo_sync(), it
 * re-examines the directory, noting processes that need to be updated, and
 * killing processes that no longer have a corresponding file.
 *
 */

#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <wait.h>
#include "childinfo.h"

// a double linked list (not circular)

struct childinfo {
	pid_t pid;
	char *file;
	int mark;
	time_t mtime;
	struct childinfo *next;
	struct childinfo *last;
};

static struct childinfo *childinfo_head=NULL;
static char *confdir=NULL;
static childinfo_spawn_cb *spawnfn=NULL;
static childinfo_hup_cb *hupfn=NULL;

static struct childinfo * find(const char *file){
	struct childinfo *cur=childinfo_head;
	while (cur!=NULL){
		if (strcmp(file, cur->file)==0){
			return cur;
		}
		cur=cur->next;
	}
	return NULL;
}

// look for file, and add if missing
static pid_t add(char *file, time_t mtime){
	struct childinfo *ci = find(file);
	if (ci){
		ci->mark=1;
		if (ci->mtime < mtime){
			ci->mtime = mtime;
			return ci->pid;
		}
		return 0;
	}
	ci = (struct childinfo *)malloc(sizeof(struct childinfo));
	ci->file=strdup(file);
	ci->mtime=mtime;
	ci->mark=1;
	ci->pid=-1;
	ci->last=NULL;
	ci->next=childinfo_head;
	if (ci->next) ci->next->last = ci;
	childinfo_head=ci;
	return 0;
}

// look for file, and delete if exists. Returns its pid.
static pid_t del(struct childinfo *ci){
	pid_t ret;
	if (!ci) return -1;
	if (ci->next){
		ci->next->last=ci->last;
	}
	if (ci->last){
		ci->last->next=ci->next;
	} else {
		childinfo_head=ci->next;
	}
	free(ci->file);
	ret=ci->pid;
	free(ci);
	return ret;
}

void sigchild(int num, siginfo_t *sip, void *extra){
	struct childinfo *cur=childinfo_head;
    pid_t child_pid = sip->si_pid;
        
	child_pid = waitpid(child_pid, NULL, WNOHANG);
    if (child_pid <= 0) return;
	while (cur!=NULL){
		if (cur->pid == child_pid) {
			cur->pid=-1;
			return;
		}
		cur=cur->next;
	}
}

void sigusr1(int num){
    childinfo_sync();
}

void sigterm(int num){
	struct childinfo *tmp, *cur=childinfo_head;
	while (cur!=NULL){
		if (cur->pid > 0){
			kill(cur->pid, SIGTERM);
		}
        tmp=cur->next;
        del(cur);
		cur=tmp;
	}
	_exit(0);
}

int childinfo_init(char *dir, childinfo_spawn_cb *spawn, childinfo_hup_cb *hup){
	struct sigaction sa;

	sa.sa_sigaction = sigchild;
	sigemptyset(&sa.sa_mask);
	sa.sa_flags = SA_SIGINFO;
	sigaction(SIGCHLD, &sa, 0);

    signal(SIGUSR1, &sigusr1);
    signal(SIGTERM, &sigterm);
    signal(SIGINT, &sigterm);
    signal(SIGQUIT, &sigterm);
    signal(SIGABRT, &sigterm);
    signal(SIGKILL, &sigterm);

	confdir=dir;
	printf("the word is:%s\n",confdir);
	spawnfn=spawn;
	hupfn=hup;
	return 0;
}

int childinfo_sync(){
	printf("Entering %s.\n", __func__);
	DIR *d;
	struct dirent *de;
	struct stat s;
	char *buf;
	pid_t pid;
	struct childinfo *ci, *cur=childinfo_head;

        //fprintf (stderr,"Childinfo: calling sync\n");
    
	d = opendir(confdir);
	if (!d) return 1;

	// clear the mark
	while (cur!=NULL){
		cur->mark=0;
		cur=cur->next;
	}

	// add, mark, and HUP, as needed
	buf = (char *) calloc(512, sizeof(char));
	while ((de=readdir(d))){
		//printf("Checking directory '%s'.\n", de->d_name);
		if (de->d_name[0] == '.') continue;
		if (strstr(de->d_name, "loadbalance.cfg") == NULL) continue;
		snprintf(buf, 512, "%s/%s", confdir, de->d_name);
		stat(buf, &s);
                //fprintf (stderr,"checking %s with %u mod time\n",buf,(unsigned int) s.st_mtime);
		if ((pid=add(de->d_name, s.st_mtime)) && pid > 0){
                        fprintf (stderr,"sending TERM to %d\n",(int)pid);
			hupfn(pid);
		}
	}
	free(buf);

	// kill the ones we didn't find
	cur=childinfo_head;
	while (cur!=NULL){
		if (cur->mark == 0){
            if (cur->pid > 0) {
                fprintf (stderr,"sending SIGTERM to %d\n",(int)cur->pid);
                kill(cur->pid, SIGTERM);
            }
			ci=cur->next;
			del(cur);
			cur=ci;
		} else {
			cur=cur->next;
		}
	}
	return 0;
}

int childinfo_spawn(){
	fprintf(stderr,"Entering %s.\n", __func__);
	pid_t child;
	int ret=0;
	struct childinfo *cur=childinfo_head;
	while (cur!=NULL){
		if (cur->pid < 0) {
                        fprintf (stderr,"spawning child process for: %s\n",cur->file);
			child = fork();
			if (child == -1){
				fprintf(stderr, "Error during fork call.\n");
				ret++;
			} else if (child){
				cur->pid=child;
			} else {
				char *buf = (char *) calloc(512,sizeof (char));
				snprintf(buf, 512, "%s/%s", confdir, cur->file);
				spawnfn(buf);
                sleep (5);      /* when spawn fails for some reason, we need to give it a break */
				exit(1); // exit with error if spawn fails!
			}
		}
		cur=cur->next;
	}
	
//	system("sudo touch /config/openvpn/on && rm /config/openvpn/off >/dev/null 2&1");
//	fprintf(stderr,"Exiting childinfo_spawn\n");
        //if(sysret == -1)
//	{
	//it is ok . do nothing
//	}
	return ret;
}
