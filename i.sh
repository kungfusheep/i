
I_PATH=~/i

# default entrypoint
function i {

	# select command name
	case "${1}" in
		"list" ) # list out the journal
			__i_list; return;;

		"git" ) # run arbitrary git commands on the i repo
			git -C $I_PATH/ ${@:2}; return;;
	esac

	__i_write $*
}

# write a (potentially empty) commit with a message
function __i_write {
	git  -C $I_PATH/ commit --allow-empty -qam "$*"
}

# list the entries in readable format
function __i_list {
	git -C $I_PATH/ log --pretty=format:"%Cblue%cr: %Creset%B";
}

# do an init of the i repo if we detect it isn't there
if [ ! -e "$I_PATH" ]; then
	mkdir -p $I_PATH
	git -C $I_PATH/ init
	__i_write init
fi
