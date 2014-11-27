
all:    
	@echo -e "\nWelcome to the NFVO Build Utility"
	@echo -e "\nUsage:-   "
	@echo "   make basetoolchain"
	@echo "   make lfstoolchain"
	@echo "   make kernel"
	@echo "   make initrd"
	@echo "   make packages"
	@echo "   make image"
	
	@echo -e "\n   make services"
	@echo -e "\nNote:- Run the commands as root"

basetoolchain    :
	@echo "Making LFS base tool chain"
	@sh build_scripts/build_main.sh base

lfstoolchain    :
	@echo "Making LFS  tool chain"
	@sh build_scripts/build_main.sh lfs

packages    :
	@echo "Making LFS  tool chain"
	@sh build_scripts/build_main.sh pkg

kernel   :
	@echo "Making LFS  Kernel"
	@sh build_scripts/build_main.sh kernel

initrd   :
	@echo "Making Ramdisk Image"
	@sh build_scripts/build_main.sh	initrd 

image   :
	@echo "Making Disk Image"
	@sh build_scripts/build_main.sh	image

services   :
	@echo "------ Services ----------"
	@sh build_scripts/build_main.sh	services
