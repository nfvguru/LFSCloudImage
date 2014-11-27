#!/bin/bash

#cat > ~/.bash_profile << "EOF"
#exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
#EOF

cat > ~/dobasebuild << "EOF"
#!/bin/sh
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
exec env -i LFS=$LFS LC_ALL=$LC_ALL LFS_TGT=$LFS_TGT PATH=$PATH HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash -c "make basetoolchain"
exit
EOF

chmod +x ~/dobasebuild


cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF

exit
