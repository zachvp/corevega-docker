#/bin/sh

on_terminate(){
	echo "script terminated"
	exit
}

healthcheck(){
	MOUNT=$2
	while ! test -d $MOUNT
	do
		echo "mount directory '$MOUNT' does not exist"
		sleep 3s
	done	
	echo "healthcheck complete"
}

main(){
	# TODO: narrow these down, ideally to a single one
	trap 'on_terminate' TERM ABRT KILL QUIT HUP INT

	echo "hello, time to spin as slow as the earth..."

	while true
	do
		echo "tick.spin"
		sleep 4s
	done
}

# call provided function
echo "calling $1 $@"
$1 $@
