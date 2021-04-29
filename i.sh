
I_PATH=~/i

complete -W "list mentioned tagged find occurrences git" i

# TODO add completion for names and tags

# default entrypoint
function i {

	# select command name, if none are recognised then we're writing a journal entry. 
	case "${1}" in
		"list" ) # list out the journal
			__i_list; return;;

		"mentioned") # list out names mentioned
			shift

			if [ "${1}" == "" ]; then
				__i_mentioned;
			else
				__i_mentioned_someone "${1}";
			fi

			return;;

		"tagged") # list out tags tagged
			shift

			if [ "${1}" == "" ]; then
				__i_tagged;
			else
				__i_tagged_something "${1}";
			fi
			return;;

		"find") # generic find for anything
			shift

			__i_find "${1}"
			return;;

		"occurrences") # count occurrences of anything
			shift

			__i_count_occurrences "${1}"
			return;;

		"git" ) # run arbitrary git commands on the i repo
			git -C $I_PATH/ ${@:2}; return;;
	esac

	# add a journal entry
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

function __i_count_occurrences {
	__i_list | sed 's/\ /\n/g' | grep ${1} --color=never | sed s/,//g | sort | uniq -c | sort -rh
}

# list the names mentioned
function __i_mentioned {
	__i_count_occurrences @
}

# lists entries where a specific person is mentioned
function __i_mentioned_someone {
	__i_find @${1}
}

# list the tags mentioned
function __i_tagged {
	__i_count_occurrences %
}

# lists entries where a specific tag is mentioned
function __i_tagged_something {
	__i_find %${1}
}

# basic search across the results
function __i_find {
	__i_list | grep ${1}
}

# do an init of the i repo if we detect it isn't there
if [ ! -e "$I_PATH" ]; then
	mkdir -p $I_PATH
	git -qC $I_PATH/ init
	__i_write 'created a journal'
fi
