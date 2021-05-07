
I_PATH=~/i
I_SOURCE_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

complete -W "amend list mentioned tagged find occurrences git upgrade today yesterday" i

# TODO add completion for names and tags

since=""

# default entrypoint
function i {

	# select command name, if none are recognised then we're writing a journal entry. 
	case "${1}" in

		"amend") # overwrite the last message - useful in case of missing info or typo's
			shift
			__i_amend "$@"; return;;

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

			__i_find "$*"
			return;;

		"occurrences") # count occurrences of anything
			shift

			__i_count_occurrences "$@"
			return;;

		"git" ) # run arbitrary git commands on the i repo
			shift

			git -C $I_PATH/ "$@"; return;;

		"today") # view todays journal entries with a special date format, paginated
			shift

			git -C $I_PATH/ log --since "1am"  --pretty=format:"%Cblue%cd (%cr): %Creset%B" --date=format:"%H:%M" | fmt | less
			return;;

		"yesterday") # view yesterdays journal entries with a special date format, paginated
	
			# i'm using this until i've implemented 'until'
			git -C $I_PATH/ log --since "2 days ago" --until midnight  --pretty=format:"%Cblue%cd: %Creset%B" --date=format:"%H:%M" | fmt | less
			return;;

		"upgrade") # upgrade the 'i' client
			git -C $I_SOURCE_DIR pull
			source $I_SOURCE_DIR/i.sh
			return;;
	esac

	# add a journal entry
	__i_write "$@"
}

# write a (potentially empty) commit with a message
function __i_write {
	git  -C $I_PATH/ commit --allow-empty -qam "$*"
}

# amend the previous message
function __i_amend {
	git  -C $I_PATH/ commit --allow-empty --amend -qam "$*"
}

# list the entries in readable format
function __i_list {
	git -C $I_PATH/ log --since "${since:-1970}" --pretty=format:"%Cblue%cr: %Creset%B";
}

function __i_count_occurrences {
	__i_list | sed 's/\ /\n/g' | grep ${1} --color=never | sed 's/,//g; s/\.//g' | sort | uniq -c | sort -rh
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
	__i_list | grep "${1}"
}

# do an init of the i repo if we detect it isn't there
if [ ! -e "$I_PATH" ]; then
	mkdir -p $I_PATH
	git -C $I_PATH/ init -q
	__i_write 'created a journal'
fi
