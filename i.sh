
I_PATH=~/i
I_SOURCE_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

complete -W "amend list mentioned tagged find occurrences git upgrade today yesterday digest" i

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

		"digest") # use gpt to summarise the weeks activity into a digest
			__i_summary
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

# use gpt to summarise the weeks activity into a digest
function __i_summary {
	OUT=$(git -C $I_PATH/ log --since "last monday" --pretty=format:"%Cblue%cr: %Creset%B" | tr -d '\n')

	curl -X POST -s --http2 --no-buffer \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $GPT_ACCESS_TOKEN" \
	-d '{
		"model": "gpt-4",
		"stream": true,
		"temperature": 0,
		"messages": [
			{
				"role": "user", 
				"content": "summarise the notes below into MARKDOWN sections about distinct subjects in order for me to give a weekly update. double check there are the minimum possible number of subjects. the format should be TITLE OF SUBJECT followed by BULLET LIST OF SUBJECT ENTRIES. remove any @ symbols at the start of names. always make names bold text. if a word starts with a % then use that word as the subject title. \n\n\n'"$OUT"'"
			}
		]
	}' \
	https://api.openai.com/v1/chat/completions | awk -F "data: " '/^data: /{print $2; fflush()}'| \
	python3 -c "
import sys
import json

for line in sys.stdin:
    try:
        data = json.loads(line).get('choices')[0].get('delta').get('content')
        if data is not None:
            print(data, end='', flush=True)
    except json.JSONDecodeError:
        pass  # ignore lines that are not valid JSON
"
}

# do an init of the i repo if we detect it isn't there
if [ ! -e "$I_PATH" ]; then
	mkdir -p $I_PATH
	git -C $I_PATH/ init -q
	__i_write 'created a journal'
fi
