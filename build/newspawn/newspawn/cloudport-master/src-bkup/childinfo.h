/* childinfo.h
 *
 * This file contains functions that manage the list of children.
 *
 */

typedef void childinfo_spawn_cb(char *);
typedef void childinfo_hup_cb(pid_t);

int childinfo_init(char *dir, childinfo_spawn_cb *spawn, childinfo_hup_cb *hup);
int childinfo_sync();
int childinfo_spawn();

