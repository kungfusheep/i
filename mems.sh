
MEMS_PATH=~/mems/

function mems {

	case "${1}" in
		"list" )
			__mems_list; return;;
	esac

	__mems_write $*
}

function __mems_write {
	date > $MEMS_PATH/file
	git  --git-dir $MEMS_PATH/.git commit -am "$*"
}

function __mems_list {
	git --git-dir $MEMS_PATH/.git log --pretty=format:"%Cblue%cr: %Creset%B";
}


if [ ! -e "$MEMS_PATH" ]; then
	mkdir -p $MEMS_PATH
	cd $MEMS_PATH
	git init
	touch file
	git add file
	__mems_write init
	cd -
fi



# git log --pretty=format:"%Cblue%cr: %Creset%B"