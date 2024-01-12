#/bin/sh

on_terminate(){
	echo "script terminated"
	exit
}

healthcheck(){
	MOUNT="$2"
	echo "check mount directory: $MOUNT"
	while ! test -d "$MOUNT"
	do
		echo "mount directory '$MOUNT' does not exist"
		sleep 2s
	done	
	echo "healthcheck complete"
}

main(){
	# listen to signals so the script can exit as soon as possible
	trap on_terminate INT TERM

	echo "hello, time to spin..."

	while true
	do
		echo "tick.spin"
		sleep 4s
	done
}

# call provided function
echo "calling $@"
$1 $@
