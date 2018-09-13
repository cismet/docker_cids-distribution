#!/bin/sh
# Reset all variables that might be set
verbose=0 # Variables to be evaluated as shell arithmetic should be initialized to a default or validated beforehand.

token=${SLACK_TOKEN}
hook=${SLACK_HOOK}
channel=${SLACK_CHANNEL}
username=${SLACK_USERNAME}
uploadUrl=${SLACK_UPLOAD_URL}

message="super testmessage :thumbsup:"
icon=":suspension_railway:"
command=""
file=""

while :; do
    case $1 in
		###help
        -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
			echo "slack is a CLI to send messages to the cismet slack chat"
			echo
			echo "Usage:"
			echo "  slack [Options]"
			echo "Options:"
			echo " -h, -?, --help				this message"
			echo " -m TEXT, --message=TEXT		what to post"
			echo " -c NAME, --channel=NAME		where to post"
			echo " -u USER, --username=USER		who is posting"
			echo " -i ICON, --icon=ICON			the icon for the user"
			echo " -p CMD, --command=CMD			add the output of CMD to your message"
			echo " -f FILES, --files=FILES			an additional upload (if multiple, put in quotes"
			echo " -v, --verbose				some additional info"      
			exit
            ;;
       	### message
        -m|--message)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                message=$2
                shift
            else
                printf 'ERROR: "--message" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --message=?*)
            message=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --message=)         # Handle the case of an empty message
            printf 'ERROR: "--message" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
        ### channel
        -c|--channel)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                channel=$2
                shift
            else
                printf 'ERROR: "--channel" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --channel=?*)
            channel=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --channel=)         # Handle the case of an empty --file=
            printf 'ERROR: "--channel" requires a non-empty option argument.\n' >&2
            exit 1
            ;;

        ### username
        -u|--username)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                username=$2
                shift
            else
                printf 'ERROR: "--username" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --username=?*)
            username=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --username=)         # Handle the case of an empty --file=
            printf 'ERROR: "--username" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
        ### usericon
        -i|--icon)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                icon=$2
                shift
            else
                printf 'ERROR: "--icon" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --icon=?*)
            icon=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --icon=)         # Handle the case of an empty --icon=
            printf 'ERROR: "--icon" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
        
        ### command
        -p|--command)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                command=$2
                shift
            else
                printf 'ERROR: "--command" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --command=?*)
            command=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --command=)         # Handle the case of an empty --command=
            printf 'ERROR: "--command" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
        
        ### files
         -f|--files)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                files=$2
                shift
            else
                printf 'ERROR: "--file" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --files=?*)
            files=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --files=)         # Handle the case of an empty --file=
            printf 'ERROR: "--file" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
		###verbose
        -v|--verbose)
            verbose=$((verbose + 1)) # Each -v argument adds 1 to verbosity.
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

# if --file was provided, open it for writing, else duplicate stdout
#if [ -n "$file" ]; then
 #   exec 3> "$file"
#else
 #   exec 3>&1
#fi

# Rest of the program here.
# If there are input files (for example) that follow the options, they
# will remain in the "$@" positional parameters.


if [ $verbose -gt 0 ]; then
	echo "##### Verbose"
	echo "channel=$channel"
	echo "username=$username"
	echo "message=$message"
	echo "icon=$icon"
	echo "command=$command"
	echo "files=$file"
fi


if [ -n "$command" ]; then
	output=`$command`
	injectableOutput="\n\n\`\`\`\n$output\n\`\`\`"
else
	injectableOutput=""
fi

PAYLOAD="payload={\"channel\": \"$channel\", \"username\": \"$username\", \"text\": \"$message$injectableOutput\", \"icon_emoji\": \"$icon\"}"

SLACKERMSG="/usr/bin/curl -X POST --data-urlencode '$PAYLOAD' $hook"

if [ $verbose -gt 0 ]; then
	echo "$SLACKERMSG"
fi

eval "$SLACKERMSG" > /dev/null 2> /dev/null

if [ -n "$files" ]; then
	for file in $files
	do
		echo $file
		SLACKERUPLD="/usr/bin/curl -F file=@$file -F channels=$channel -F token=$token $uploadUrl"
		if [ $verbose -gt 0 ]; then
			echo "$SLACKERUPLD"
		fi
		eval "$SLACKERUPLD" > /dev/null 2> /dev/null
	done
fi