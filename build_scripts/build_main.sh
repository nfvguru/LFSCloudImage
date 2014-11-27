#################################################
#
#################################################

export ROOT=`pwd`
export LFile=${ROOT}/Logs/`date +%s`.log
export DFile=${ROOT}/Logs/`date +%s`_detailed.log
export SBase=${ROOT}/build_scripts
. ${SBase}/build_utils.sh

mode=$1
case "$mode" in
	'base' )
	sh ${SBase}/build_base.sh $ROOT;;

	'lfs' )
	sh ${SBase}/build_lfs.sh $ROOT;;

	'pkg' )
	sh ${SBase}/build_pkg.sh $ROOT;;

	'kernel' )
	sh ${SBase}/build_kernel.sh $ROOT;;

	'initrd' )
	sh ${SBase}/build_initrd.sh $ROOT;;

	'image' )
	sh ${SBase}/build_image_qemu.sh $ROOT;;

	'services' )
	sh ${SBase}/build_services.sh $ROOT;;
esac

