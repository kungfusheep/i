
I_PATH=~/i
I_SOURCE_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
I_GPT_VERSION="${I_GPT_VERSION:=gpt-4}"

complete -W "amend list mentioned tagged find occurrences git upgrade today yesterday digest remember analyse" i

# TODO add completion for names and tags

since=""

# default entrypoint for the i command
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
			__i_digest
			return;;

		"remember") # use gpt to generate a todo list of tasks that sound like they are outstanding from the previous week
			__i_remember
			return;;

		"analyse")
			shift

			__i_analyse "$@"
			return;;


		"upgrade") # upgrade the 'i' client
			git -C $I_SOURCE_DIR pull
			source $I_SOURCE_DIR/i.sh
			return;;

		
		"help") # Display help
			__i_help
			return;;
		
		"--help") # Display help
			__i_help
			return;;
		
		"-h") # Display help
			__i_help
			return;;

	esac

	if [ ! -n "${1}" ]; then
		__i_help
		return
	fi

	# add a journal entry
	__i_write "$@"
}

# basic help function
function __i_help {
  echo "Usage: i [COMMAND|MESSAGE]"
  echo ""
  echo "COMMANDS:"
  echo "  help(-h|--help)  Display this help for the 'i' command."
  echo "  amend            Overwrite the last message - useful in case of missing info or typos."
  echo "  list             List out the journal."
  echo "  mentioned        List out names mentioned or entries where a specific person is mentioned."
  echo "  tagged           List out tags mentioned or entries where a specific tag is mentioned."
  echo "  find             Generic find for anything."
  echo "  occurrences      Count occurrences of anything."
  echo "  git              Run arbitrary git commands on the 'i' repo."
  echo "  today            View today's journal entries with a special date format, paginated."
  echo "  yesterday        View yesterday's journal entries with a special date format, paginated."
  echo "  digest           Use GPT to summarize the week's activity into a digest."
  echo "  remember         Use GPT to generate a to-do list of tasks that sound outstanding from the previous week."
  echo "  analyse          Run arbitrary GPT analysis commands on a specific time window from the journal."
  echo "  upgrade          Upgrade the 'i' client."
  echo ""
  echo "By default, if none of the recognized commands are used, a new journal entry is created with the provided message."
  echo ""
  echo "For more detailed information on each command, look at the source of 'i.sh'."
}

# write a (potentially empty) commit with a message
function __i_write {
	HOOKS_PATH="$(git config core.hooksPath)"
	git config core.hooksPath .git/hooks
	git  -C $I_PATH/ commit --allow-empty -qam "$*"
	git config core.hooksPath "$HOOKS_PATH"

	# If we have a remote, push to it async
	if [ -n "$(git  -C $I_PATH/ remote show origin)" ]; then
		( git  -C $I_PATH/ push -u origin main -q > /dev/null 2>&1 & );
	fi
}

# amend the previous message
function __i_amend {
	HOOKS_PATH="$(git config core.hooksPath)"
	git config core.hooksPath .git/hooks
	git  -C $I_PATH/ commit --allow-empty --amend -qam "$*"
	git config core.hooksPath "$HOOKS_PATH"

	# If we have a remote, push to it async
	if [ -n "$(git  -C $I_PATH/ remote show origin)" ]; then
		( git  -C $I_PATH/ push -u origin main -q > /dev/null 2>&1 & );
	fi
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

# run arbitrary GPT analysis commands on a specific time window from the journal
# the syntax is `i analyse since "last monday" list all people i interacted with`
function __i_analyse { 
	item="${1}"
	shift

	if [ "$item" == "since" ]; then # allow user to type "since" as first argument
		item="${1}"
		shift
	fi

	# the journal
	OUT=$(git -C $I_PATH/ log --since "$item" --pretty=format:"%cr: %B" | tr -d '"\n')
	# the whole prompt
	PROMPT="$* \n\n\n "$OUT""

	curl -X POST -s --no-buffer \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $GPT_ACCESS_TOKEN" \
	-d '{
		"model": "'"$I_GPT_VERSION"'",
		"stream": true,
		"temperature": 0,
		"frequency_penalty": 1.0,
		"messages": [
			{
				"role": "user", 
				"content": "'"$PROMPT"'"
			}
		]
	}' \
	https://api.openai.com/v1/chat/completions | __i__server_push_to_stdout
}

# use gpt to summarise the weeks activity into a digest
function __i_digest {
	OUT=$(git -C $I_PATH/ log --since "7 days ago" --pretty=format:"%cr: %B" | tr -d '"\n')

	curl -X POST -s --no-buffer \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $GPT_ACCESS_TOKEN" \
	-d '{
		"model": "'"$I_GPT_VERSION"'",
		"stream": true,
		"temperature": 0,
		"frequency_penalty": 1.0,
		"messages": [
			{
				"role": "user", 
				"content": "summarise the notes below into MARKDOWN sections about distinct subjects in order for me to give a weekly update. double check there are the minimum possible number of subjects, for example, do not create a header called `RPC Tooling` if an `RPC` header also exists, and so on. the format should be TITLE OF SUBJECT followed by BULLET LIST OF SUBJECT ENTRIES. do not include entries that simply state a conversation took place with no other detail unless it is the only item within a section. remove any @ symbols at the start of names. always make names bold text. if a word starts with a % then use that word as the subject title. be as concise as possible with each bullet point without losing significant points of information and do not omit instances of work that took place.  after you have generated the full list, generate a footer section which outlines EVERY individual activity that took place that week.  after that section, please make note of EVERY person I spoke to along with the number of times I spoke to them AND a sentiment analysis of our interactions scoring 0-10. \n\n\n'"$OUT"'"
			}
		]
	}' \
	https://api.openai.com/v1/chat/completions | __i__server_push_to_stdout
}

# use gpt to generate a todo list of tasks that sound like they are outstanding from the previous week
function __i_remember {
	OUT=$(git -C $I_PATH/ log --since "7 days ago" --pretty=format:"%cr: %B" | tr -d '"\n')

	curl -X POST -s --no-buffer \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $GPT_ACCESS_TOKEN" \
	-d '{
		"model": "'"$I_GPT_VERSION"'",
		"stream": true,
		"temperature": 0,
		"frequency_penalty": 0.38,
		"presence_penalty": 0.38,
		"messages": [
			{
				"role": "user", 
				"content": "I want you to generate a todo list of tasks that sound like they are outstanding in the following journal entries from last week. I am not asking for a todo list based on every single item - it is ok for there to be no items at all. I specifically want to identify tasks which sound like they are not resolved, so I can pick them up after the report is generated. please take into account the date at the start of each entry  and figure out based on that whether tasks were being resolved throughout the week. Only raise tasks you KNOW are unresolved, do not guess - when you see language such as \"i need to\" for example.  do not include actions other people have taken. DO NOT output line numbers. DO NOT output a title, just a bullet list.  \n\n\n'"$OUT"'"
			}
		]
	}' \
	https://api.openai.com/v1/chat/completions | __i__server_push_to_stdout | fzf -m --header "Select using TAB >"
}

# used to parse the server push messages in the completions response and output them to stdout
function __i__server_push_to_stdout { 
	awk -F "data: " '/^data: /{print $2; fflush()}'| \
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

# Check if the script is being executed directly. If so, we run i directly
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    i "$@"
fi
