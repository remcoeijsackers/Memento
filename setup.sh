initialised_pak=false
restart_default=false
script_dir='/usr/local/bin'
callsign='mto'
default_editor='vim'














#'''Change code only below this point============'''
#'''The first 20 lines are checked during setup=='''
# MEMENTO

red=`tput setaf 1`
cyan=`tput setaf 6`
green=`tput setaf 2`
reset=`tput sgr0`

package='Memento'
usedshell=$(ps -p $$ -ocomm=)
extention="_mto_"
filename=`basename "$0"`
exp_file="memento.sh"
count_of_tags=""
rc_file="~/.zshrc" #TODO: Replace during the init setup

# -e needed for bash colour output
if [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ] || [ $usedshell = "zsh" ] || [ $usedshell = "/bin/sh" ]
then 
  colr=""
else
  colr="-e"
	read_assist="-p"
fi

check_rc_file() {
	if [ -f "$1" ]; then
	    echo "1"
	else
	    echo "0"
	fi
}

#y="$(check_rc_file $rc_file)"
#
#if [ $y -eq 1 ];
#then
#    echo "yay $y"
#else 
#    echo "no $y"
#fi

#==INITIAL_RUN===

_initial_run_parser() {
	intial_run_optional_args=( "demo" "-ia" "-skipinstall" )
	intial_run_given_args=()

	for arg in $@
	do 
		case "$arg" in
			"demo")
				demo_mode=true
				intial_run_given_args+="$arg"
				;;
			"-ia")
				interactive_mode=true
				intial_run_given_args+="$arg"
				;;
			"-skipinstall")
				skip_install=true
				intial_run_given_args+="$arg"
				;;
		esac
	done

	B=${intial_run_optional_args[@]};

	__initial_unconfigured_remainder=(`echo $@ ${B[@]} | tr ' ' '\n' | sort | uniq -u `)

	auto_set_initial_args=()

	for arg in "${__initial_unconfigured_remainder[@]}"
	do 	
		case "$arg" in
			"demo")
				demo_mode=false
				auto_set_initial_args+="$arg"
				;;
			"-ia")
				interactive_mode=false
				auto_set_initial_args+="$arg"
				;;
			"-skipinstall")
				skip_install=false
				intial_run_given_args+="$arg"
				;;
		esac
	done

	C=${auto_set_initial_args[@]};
	D=${__initial_unconfigured_remainder[@]};

	__final_configured_remainder=(`echo ${C[@]} ${D[@]} | tr ' ' '\n' | sort | uniq -u `)
	if $demo_mode
	then
		echo "Demo mode started, config:"
		echo "demo mode: $demo_mode"
		echo "interactive mode: $interactive_mode"
		echo "skip install: $skip_install"
	fi
}

#TODO: Either write a main argument parser (that passes it through)
# Or mvoe the 'interactive mode' from this one.
if [ $initialised_pak = false ]
then
	_initial_run_parser $@
fi

#===FUNCTIONS===

# make an alias
append_src() {
	y="$(check_rc_file $rc_file)"
	if [ $y -eq 1 ]
	then 
		alname=$1
		alcomm=$2
		printf "alias %s='%s' #alias made by $package\n" "$alname" "$alcomm" >> $rc_file
	else
		_list_rc
	fi
}

#Make a script globally excecutable
make_global() {
	y="$(check_rc_file $rc_file)"
	if [ $y -eq 1 ]
	then 
		continue
	else
		_list_rc
	fi

	#rename script for find function
	new_scriptname="$extention$1"
	mv $1 "${new_scriptname}"
	#move scripts to bin
	mv $PWD/"${new_scriptname}" $script_dir/
	chmod +x $script_dir/"${new_scriptname}"
	# add alias for script
	echo "alias $2='${new_scriptname}' #alias made by $package" >> ~/.zshrc
}

edit_script() {
	if [ -f "$script_dir/$1" ]; then
		$default_editor $script_dir/$1
	else 
		echo $colr "${red}Script${reset} $1 ${red}not found${reset}"
	fi
}

list_aliases() {
	y="$(check_rc_file $rc_file)"
	if [ $y -eq 1 ]
	then 
		continue
	else
		_list_rc
	fi

	grep "alias made by $package" $rc_file

}

list_scripts() {
	find $script_dir -name "$extention*"
}

list_tags() {
	if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ] || [ $usedshell = "zsh" ] || [ $usedshell = "/bin/sh" ]
	then
		grep "tag" ~/.zshrc
	elif  [ $usedshell = "/bin/bash" ] ||  [ $usedshell = "bash" ]
	then
		grep "tag" ~/.bashrc 
	else 
		_list_rc
	fi
}

remove_all_tags() {
  if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ] || [ $usedshell = "zsh" ] || [ $usedshell = "/bin/sh" ]
	then
    sed "/tag/d" ~/.zshrc > temp
		echo "" > ~/.zshrc
		cat temp > ~/.zshrc
		rm temp
	elif  [ $usedshell = "/bin/bash" ] || [ $usedshell == "bash" ]
	then
		sed "/tag/d" ~/.bashrc > temp
		echo "" > ~/.bashrc
		cat temp > ~/.bashrc
		rm temp
	else 
		_list_rc
	fi
}

remove_script() {
	if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ] || [ $usedshell = "zsh" ] || [ $usedshell = "/bin/sh" ]
	then
		rm "$script_dir/$1"
		al=$(grep $1 ~/.zshrc)
		remove_alias $1
	elif  [ $usedshell = "/bin/bash" ] ||  [ $usedshell = "bash" ]
	then
		rm "$script_dir/$1"
		al=$(grep $1 ~/.bashrc)
		remove_alias $1
	else 
		_list_rc
	fi
	echo $colr "${green}Removed script${reset}: $1"
	echo $colr "${green}Removed bound alias${reset}: $al"
}

remove_alias() {
	#TODO add a check to see if the alias is already removed
	if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ] || [ $usedshell = "zsh" ] || [ $usedshell = "/bin/sh" ]
	then
		sed "/$1/d" ~/.zshrc > temp
		echo "" > ~/.zshrc
		cat temp > ~/.zshrc
		rm temp
	elif  [ $usedshell = "/bin/bash" ] || [ $usedshell = "bash" ]
	then
		sed "/alias $1/d" ~/.bashrc > temp
		echo "" > ~/.bashrc
		cat temp > ~/.bashrc
		rm temp
	else 
		_list_rc
	fi
}

remove_all_alias() {
	#TODO add a check to see if the alias is already removed
	printf '%s ' 'Are you sure you want to remove ALL aliases? (y/n) '
	read answer
	if [ $answer = "y" ]
	then
    if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ] || [ $usedshell = "zsh" ] || [ $usedshell = "/bin/sh" ]
		then
			sed "/#alias made by $package/d" ~/.zshrc > temp
			echo "" > ~/.zshrc
			#put the package alias back
			printf "alias %s='%s' #alias made by $package\n" "$callsign" "$script_dir/_mto_memento.sh" >> temp
			cat temp > ~/.zshrc
			rm temp
		elif  [ $usedshell = "/bin/bash" ] || [ $usedshell = "bash" ]
		then
			sed "/alias $1/d" ~/.bashrc > temp
			echo "" > ~/.bashrc
			#put the package alias back
			printf "alias %s='%s' #alias made by $package\n" "$callsign" "$script_dir/_mto_memento.sh" >> temp
			cat temp > ~/.bashrc
			rm temp
		else 
			_list_rc
		fi
    echo $colr "${green}All aliasses are removed.${reset}"
	elif [ $answer = "n" ]
	then
		exit 0
	else 
		echo "please answer with 'y' or 'n'"
		exit 1
	fi

}

restart_shell() {
	if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ] || [ $usedshell = "zsh" ] || [ $usedshell = "/bin/sh" ]
	then
		exec zsh
	elif  [ $usedshell = "/bin/bash" ] || [ $usedshell = "bash" ]
	then
		exec bash
	else 
		exec $usedshell
	fi
}

tag() {
  file_path=~/.zshrc  # Replace with the path to your file
  # Read the file contents into an array
  array=()
  while IFS= read -r line || [ -n "$line" ]; do
      if [ "${line%#tag made by Memento}" != "$line" ]; then
          alias_line=$(echo "$line" | sed -E "s/alias ([^=]+)='([^']+)' #tag made by Memento/\1='\2'/")
          array+=("$alias_line")
      fi
  done < "$file_path"
  count_of_tags="${#array[@]}"

  tagn=$(pwd)
  if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ] || [ $usedshell = "zsh" ] || [ $usedshell = "/bin/sh" ]
	then
		if [ $# -eq 0 ]
		then
			alname="t$count_of_tags" 
		else
			alname="$1"
		fi
		alcomm="cd $tagn"
		printf "alias %s='%s' #tag made by $package\n" "$alname" "$alcomm" >> ~/.zshrc
    printf "alias %s='%s'\n" "$alname" "$alcomm" 
	elif [ $usedshell = "/bin/bash" ] || [ $usedshell = "bash" ]
	then
		if [ $# -eq 0 ]
		then
			alname="t$count_of_tags" 
		else
			alname="$1"
		fi
		alcomm="cd $tagn"
		printf "alias %s='%s' #tag made by $package\n" "$alname" "$alcomm" >> ~/.bashrc
    printf "alias %s='%s'\n" "$alname" "$alcomm" 
	else 
		_list_rc
	fi
}

_remove_memento() {
	remove_script _mto_memento.sh
	find $script_dir/  -maxdepth 1 -name '_mto_memento.sh' 
	remove_alias '_mto_memento.sh'
	echo $colr "${cyan} ${package} is removed${reset}"
	restart_shell
}

print_help() {
	cyan=$(tput setaf 6)
	green=$(tput setaf 2)
	reset=$(tput sgr0)
	red=$(tput setaf 1)

	print_row() {
	  printf "| %-40s | %-60s \n" "$1" "$2"
	}

	phelp() {
	  printf "\n"
	  printf "%s\n" "$cyan$package$cyan [options] [arguments]"
	  printf "%s\n" "- handles tags, aliases, scripts"
	  printf "\n"
	  printf "options:\n"
	  print_row "-h, --help" "show brief help"
	  print_row "-a|--alias, $green<ALIAS>$reset $cyan<COMMAND>$reset" "make a new alias"
	  print_row "" "${red}Usage: $callsign -a $greenhello$reset $cyan'echo hello'$reset"
	  print_row "-s|--script, $green<SCRIPT>$reset $cyan<NAME>$reset" "make a script globally executable"
	  print_row "" "${red}Usage: $callsign -s $greenhello.sh$reset $cyan'hello'$reset"
	  print_row "-es|--edit-script, $green<FILE>$reset" "edit a script"
	  print_row "-t|--tag, $green<NAME>$reset" "create a tag in the current directory"
	  print_row "" "${red}Usage: $callsign -a $greenprojectag (optional)$reset" "create a tag in the current directory"
	  print_row "-rta|--remove-all-alias" "remove all aliases"
	  print_row "-ra|--remove-alias, $green<ALIAS>$reset" "remove an alias"
	  print_row "-rma|--remove-all-aliases" "remove all aliases"
	  print_row "-rs|--remove-script, $green<SCRIPT>$reset" "remove a script"
	  print_row "-ls|--list" "list scripts and aliases"
	  print_row "-e|--exec" "restart the shell"
	  print_row "-i|--init" "configure $callsign"
	  print_row "-ia" "interactive mode"
	  printf "\n"
	  exit 0
	}
	phelp
}

# random script generator, to be used for tests
_gen() {
	num=$(( ( RANDOM % 10 )  + 1 ))
	num2=$(( ( RANDOM % 10 )  + 1 ))
	ran=$num$num2"_script"

	echo "#!/bin/$usedshell" >> $ran.sh
	echo "echo $ran testing command" >> $ran.sh
	echo " " >> $ran.sh
	echo $ran.sh
}

#===SETUP===
_setup_package() {
	if [ $initialised_pak = true ]
	then 
		echo $colr "${green}${package} is already configured.${reset}"
		break
	else 
		_start_setup
	fi
	
}

#initialising the package
_start_setup() {
		print_row() {
		  printf "| %-30s | %-40s \n" "$1" "$2"
		}

		print_settings() {
		  printf "\n"
		  echo "${cyan}The default settings:${reset}"
		  printf "\n"
  		  print_row "${cyan}default shell is:${reset}        			" "$usedshell"
  		  print_row "${cyan}Script directory:${reset}        			" "$script_dir"
  		  print_row "${cyan}Shell restart is:${reset}		 		" "$restart_default"
  		  print_row "${cyan}Remove${reset} $filename${cyan} after setup:${reset}			" "False"
  		  print_row "${cyan}The editor is${reset}				    	" "$default_editor${reset}."
  		  print_row "${cyan}The command name for ${reset}${package} ${cyan}is${reset}		" "$callsign"
  		  printf "\n"
  		  echo "${cyan}Do you want to change any of these settings? ${reset}" ""
		  echo "(y/n)"
		}

		print_settings

		read answer
		if [ $answer = 'y' ]
		then
			_change_config
		else
			_initialise_package
		fi
}

_initialise_package() {
	echo "#!/bin/$usedshell" >> $exp_file
	echo "script_dir='$script_dir'" >> $exp_file
	echo "restart_default=$restart_default" >> $exp_file
	echo "initialised_pak=true" >> $exp_file
	echo "callsign='$callsign'" >> $exp_file
	echo "default_editor=$default_editor" >> $exp_file
	tail -n +20 $filename >> $exp_file

	_setup_complete $callsign
}


_change_config_shell() {
		__manual_config() {
			printf '%s ' "${cyan}default shell is:${reset} $usedshell. ${cyan}change?${reset} (y/n)"
			read answer
			if [ $answer = "n" ] || [ $answer = "N" ]
			then
				echo "#!/bin/$usedshell" >> $exp_file
			elif [ $answer = "y" ] || [ $answer = "Y" ]
			then
				_change_shell
			else 
				echo "please answer 'y' or 'n' "
				exit 0
			fi
		}
	  	arg1="$1"
  		if [ -z "$arg1" ]; then
  		  arg1=""
		  __manual_config
		else
			echo "#!/bin/$usedshell" >> $exp_file
  		fi

}

_change_config_script_dir() {
		__manual_config() {
			printf '%s ' "${cyan}The default script directory is:${reset} $script_dir${cyan}. change? ${reset}(y/n)"
			read answer
			if [ $answer = 'y' ]
			then 
				printf '%s ' "${cyan}Enter a new directory:${reset} make sure it is included in the PATH."
				read answer
				echo "script_dir='$answer'" >> $exp_file
			else
				echo "script_dir='$script_dir'" >> $exp_file
			fi
		}
		arg1="$1"
	  	if [ -z "$arg1" ]; then
  		  	arg1=""
		  	__manual_config
		else
			echo "script_dir='$script_dir'" >> $exp_file
  		fi
}

_change_config_restart_default() {
		__manual_config() {
			echo $colr "${cyan}Do you want to restart the shell (exec shell) after each command?${reset}"
			printf '%s ' "${cyan}this is required for aliases to take direct effect.${reset} (y/n)"
			read answer
			if [ $answer = 'y' ]
			then
				echo "restart_default=true" >> $exp_file
			else 
				echo "restart_default=false" >> $exp_file
			fi
		}
		arg1="$1"
		if [ -z "$arg1" ]; then
  		  	arg1=""
		  	__manual_config
		else
			echo "restart_default=false" >> $exp_file
  		fi
}

_change_config_default_editor() {
		__manual_config() {
			echo $colr "${cyan}The default editor is${reset} $default_editor${reset}. Change?"
			printf '%s ' "(y/n)"
			read answer
			if [ $answer = 'y' ]; then 
				printf '%s ' "${cyan}Enter name of the new editor: ${reset}"
				read answer
				echo "default_editor=$answer" >> $exp_file
			else
				echo "default_editor=vim" >> $exp_file
			fi
		}
		arg1="$1"
		if [ -z "$arg1" ]; then
  		  	arg1=""
		  	__manual_config
		else
			echo "default_editor=vim" >> $exp_file
  		fi

}

_change_config_command_name() {
		__manual_config() {
			echo $colr "${cyan}The default command name for ${reset}${package} ${cyan}is${reset} ${callsign}."
			printf '%s ' "${cyan}change? ${reset}(y/n)"

			read answer
    		if [ $answer = 'y' ]
			then 
				printf '%s ' "${cyan}Enter a new name: ${reset}"
				read command_name
				echo "callsign='$command_name'" >> $exp_file

			else 
				echo "callsign='mto'" >> $exp_file
			fi
		}
		arg1="$1"
		if [ -z "$arg1" ]; then
  		  	arg1=""
		  	__manual_config
		else
			echo "callsign='mto'" >> $exp_file
  		fi
}

_change_config_remove_setup_file(){
		__manual_config() {
			echo $colr "${cyan}Remove the setup file:${reset}($filename)${cyan}? the package file will be in ${reset}$script_dir/_mto_memento.sh"
			printf '%s ' "(y/n)"
			read answer
			if [ $answer = 'y' ]; then
				if [ ! -f "$filename" ]; then
					rm $filename
					echo $colr "${green}file:${reset}$filename${green} is removed. ${reset}"
				else 
					echo $colr "${red}File could not be found${reset}"
				fi
			fi 
		}
		arg1="$1"
		if [ -z "$arg1" ]; then
  		  	arg1=""
		  	__manual_config
		else
			echo ""
  		fi
}


_change_shell() {
	printf '%s ' "${cyan}new default shell: ${reset}"
	read answer
	if [ $answer = "zsh" ]
	then
		chsh -s '/bin/zsh'
		echo "${green}zsh${reset} is the new default shell"
		echo "rc_file='~/.zshrc'" >> $exp_file
	elif [ $answer = "bash" ]
	then
		chsh -s /bin/bash
		echo -n $colr "${green}bash${reset} is the new default shell"
		echo "rc_file='~/.bashrc'" >> $exp_file
	else 
		echo $colr "${red}shell not tested, supported shells are: bash, zsh ${reset}"
		echo "setting shell (chsh -s /bin/$answer)"		
		chsh -s /bin/$answer
		echo -n $colr "${green}$answer${reset} is the new default shell"
		echo "assuming rc file (~/.${answer}rc)"
		if [ -f "~/.${answer}rc" ]; then
        	echo "rc_file='~/.${answer}rc'" >> $exp_file
    	else
			printf '%s ' "${cyan}Please enter the rc file path (i.e. ~/.zshrc) for your shell: ${reset}"
			read custom_rc
			echo "rc_file='$custom_rc}'" >> $exp_file
		fi
	fi
}

_setup_complete() {
	command_named_param=$1
	if $demo_mode
	then 
		echo "demo mode, skipping move and permission adding of $exp_file"
	else
		make_global $exp_file $command_named_param
		echo $colr "${green}${package}${reset} is initialised. use ${green}'$command_named_param'${reset}  to call it."
		
		# Ending setup
		restart_shell
		exit 0
	fi
}

_change_config() {
		echo "Memento" >> $exp_file

		config_options=( "shell" "script_dir" "restart" "editor" "setup_file" "done" )
		configured_parts=("done")

		while true; do
			echo $colr "${cyan}${package} Configuration ${reset}" 
			echo $colr "${red}Configured: ${configured_parts[@]} ${reset}" 
			select_option "${config_options[@]}"
			choice=$?

			val=${config_options[$choice]}

			case "$val" in
            	"done") 
					break
					;;
            	"shell")
            	    _change_config_shell
					configured_parts+="shell"
					;;
            	"script_dir")
            	    _change_config_script_dir
					configured_parts+="script_dir"
					;;
            	"restart")
            	    _change_config_restart_default
					configured_parts+="restart"
					;;
            	"editor")
            	    _change_config_default_editor
					configured_parts+="editor"
					;;
            	"setup_file")
            	    _change_config_remove_setup_file
					configured_parts+="setup_file"
					;;
        	esac
		done

		A=${config_options[@]};
		B=${configured_parts[@]};
		# Check which options have not yet been configured
		unconfigured_remainder=(`echo ${A[@]} ${B[@]} | tr ' ' '\n' | sort | uniq -u `)

		autofill_default_config() {
			autofilled_options=()
			for i in "${unconfigured_remainder[@]}"
			do
			   	case "$i" in
            		"shell")
            		    _change_config_shell  "default"
						autofilled_options+="shell"
						;;
            		"script_dir")
            		    _change_config_script_dir "default"
						autofilled_options+="script_dir"
						;;
            		"restart")
            		    _change_config_restart_default "default"
						autofilled_options+="restart"
						;;
            		"editor")
            		    _change_config_default_editor "default"
						autofilled_options+="editor"
						;;
            		"setup_file")
            		    _change_config_remove_setup_file "default"
						autofilled_options+="setup_file"
						;;
        		esac
			done
		}


		if [ "$A" == "$B" ] ; then
			echo $colr "${green}${package}${reset} default configuration added." ;
		else
			echo "Not all parts are configured. $unconfigured_remainder \nThe default will be used." ;
			autofill_default_config ;
		fi;

		# initiliasisation check 
		echo "initialised_pak=true" >> $exp_file

		#change command name
		#_change_config_command_name

		# Add the script contents to the file
		tail -n +20 $filename >> $exp_file

		cmname=$(grep 'callsign' $exp_file)
		cmd_name=$(cut -d "=" -f2 <<< "$cmname" | sed 's/^.//;s/.$//')

		_setup_complete $cmd_name
}

#===HELPERS===

_list_rc () {
		echo "shellrc file not found. current shell: $usedshell"
		echo "rc files found:"
		find ~/ -maxdepth 1 -name '*rc'
		exit 1
}

function select_option {
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}


interactive_list_tags() {
	file_path=~/.zshrc  # Replace with the path to your file

	# Read the file contents into an array
	array=()
	while IFS= read -r line || [ -n "$line" ]; do
	    if [ "${line%#tag made by Memento}" != "$line" ]; then
	        alias_line=$(echo "$line" | sed -E "s/alias ([^=]+)='([^']+)' #tag made by Memento/\1='\2'/")
	        array+=("$alias_line")
	    fi
	done < "$file_path"
	
	count_of_tags="${#array[@]}"

	echo $colr "${cyan}${package} Tags ${reset}" 
	select_option "${array[@]}"
	choice=$?

	val=${array[$choice]}

	string_before_equal="${val%%=*}"

	get_part_after_equal() {
	  local input="$1"
	  IFS="=" read -ra parts <<< "$input"
	  if [ "${#parts[@]}" -lt 2 ]; then
	    echo "Invalid input. '=' not found."
	  else
	    echo "${parts[1]}"
	  fi
	}

	command=$(get_part_after_equal "$val")

	get_value_after_space() {
  		local input="$1"
  		IFS=" " read -ra parts <<< "$input"
  		if [ "${#parts[@]}" -lt 2 ]; then
  		  echo "Invalid input. Space not found."
  		else
  		  echo "${parts[1]}"
  		fi
	}

	result=$(get_value_after_space "${command%?}")
	#echo "result is $result"
	cd $result
	#echo $PWD
}


interactive_script_maker() {
	# Get all the files in the current working directory
	files=$(ls -1)

	# Store the files in an array
	file_array=($files)

	select_option "${file_array[@]}"
	choice=$?

	script="${file_array[$choice]}"

	echo $colr "${cyan}${package}Please enter script alias: ${reset}" 
	printf '%s '
	read alias
	make_global $script $alias
}


#===SETUP_RUN_CHECK===
if [[ $# -eq 0 ]] ; then
    if [ $initialised_pak = false ] && [ $skip_install = false ]
		then 
			echo $colr "${cyan}${package} is not yet initialised, want to do that now?${reset} ?" 
			printf '%s ' '(y/n)'
			read answer
			if [ $answer = 'y' ]
				then 
					chmod +x $filename
					_setup_package
					exit 0
				else
					exit 0
				fi
		else
			print_help
			break
		fi
    exit 0
fi

#===INTERACTIVE_MODE===

# Define menu options with corresponding values
options=("Help" "Tags" "Script" "Install" "Exit")
values=("value1" "value2" "submenu1" "install" "exit")

# Define submenu options with corresponding values
submenu=("Create" "List" "Back")
submenu_values=("create" "list" "Back")

# Set initial cursor position
cursor=0

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Array to store selected options
selected_options=()

if $demo_mode
then 
	demo_mode_text="demo"
else
	demo_mode_text=""
fi

# Function to display the menu
display_menu() {
  clear
  echo "${BLUE}*********************************************"
  echo "                 Memento $demo_mode_text"
  echo "*********************************************${NC}"

  for ((i=0; i<${#options[@]}; i++)); do
    if [ $i -eq $cursor ]; then
      echo "${YELLOW} ► ${options[$i]}${NC}"
    else
      echo "   ${options[$i]}"
    fi
  done
}

# Function to display submenu
display_submenu() {
  clear
  echo "${BLUE}*********************************************"
  echo "                Memento - "
  echo "*********************************************${NC}"

  for ((i=0; i<${#submenu[@]}; i++)); do
    if [ $i -eq $cursor ]; then
      echo "${YELLOW} ► ${submenu[$i]}${NC}"
    else
      echo "   ${submenu[$i]}"
    fi
  done
}

# Function to process selected option
process_option() {
  selected_option=$1
  echo "Processing option: $selected_option"

  # Example: Call another function based on the selected option
  case "$selected_option" in
    "Help")
      echo "${GREEN}Calling function for Option 1${NC}"
	  print_help
      # Call your function for Option 1 here
      ;;
    "Script")
      echo "${GREEN}Calling function for Option 2${NC}"
      # Call your function for Option 2 here
      ;;
    "List")
      echo "${GREEN}Calling function for $selected_option ${submenu_values[$cursor]} ${NC}"
      # Call your function for Suboption 1 here
      ;;
    "Create")
      echo "${GREEN}Calling function for $selected_option ${submenu_values[$cursor]} ${NC}"
	  interactive_script_maker
      ;;
	"Tags")
	  interactive_list_tags
      ;;
	"Exit")
		exit 0;;
	*)
	echo "Unkown option"
	exit 0
  esac

  # Store selected option-value pair in the array
  selected_options+=("$selected_option:${values[$cursor]}")
  exit 0
}

keep_loop=true

# Main menu loop
while $interactive_mode & $keep_loop; do
  display_menu

  # Read user input
  read -rsn1 key

  case "$key" in
    A) # Up arrow
      if [ $cursor -gt 0 ]; then
        cursor=$((cursor - 1))
      fi
      ;;
    B) # Down arrow
      if [ $cursor -lt $(( ${#options[@]} - 1 )) ]; then
        cursor=$((cursor + 1))
      fi
      ;;
    "") # Enter key
      case "$cursor" in
        0) # Help
          selected_option="${options[$cursor]}"
          process_option "$selected_option"
          ;;
        1) #Tags
          selected_option="${options[$cursor]}"
          process_option "$selected_option"
          ;;
        2) # Submenu 1
          while $interactive_mode & $keep_loop; do
            display_submenu

            # Read user input
            read -rsn1 key

            case "$key" in
              A) # Up arrow
                if [ $cursor -gt 0 ]; then
                  cursor=$((cursor - 1))
                fi
                ;;
              B) # Down arrow
                if [ $cursor -lt $(( ${#submenu[@]} - 1 )) ]; then
                  cursor=$((cursor + 1))
                fi
                ;;
              "") # Enter key
                case "$cursor" in
                  0) # Create
				  	#keep_loop=false
                    selected_option="${submenu[$cursor]}"
                    process_option "$selected_option"
                    ;;
                  1) # Suboption 2
				  	#keep_loop=false
                    selected_option="${submenu[$cursor]}"
                    process_option "$selected_option"
                    ;;
                  2) # Back
                    break
                    ;;
                esac
                ;;
            esac
          done
          ;;
        3) # Install
          echo "${RED}Install${NC}"
          selected_option="${options[$cursor]}"
          process_option "$selected_option"
          ;;
        4) # Exit
          echo "${RED}Exiting${NC}"
          exit 0
          ;;
        *)
          ;;
      esac
      ;;
  esac

  # Exit if a root-level option is selected
  if [ "$cursor" -ge "${#options[@]}" ]; then
    echo "${RED}Exiting...${NC}"
    exit 0
  fi
done

# Print out the selected options
echo "Selected Options:"
for option in "${selected_options[@]}"; do
  echo "$option"
done


#END_INTERACTIVE_MODE

while test $# -gt 0; do
  case "$1" in
	-o)
	interactive_list_tags
	exit 1;;

    -h|--help)
			print_help
      ;;
    -a|--alias)
      shift
      if test $# -gt 0; then
        append_src $1 "$2"
        echo $colr "${green}command: ${reset} $2 ${green}is now runnable as alias: ${reset} $1"
      else 
        echo $colr "${red}No alias specified${reset}"
        exit 1
      fi
      shift 
      shift
      ;;
    -e|--exec)
			shift
      restart_shell
      ;;
    -s|--script) 
      shift
      if test $# -gt 0; then
        make_global $1 $2
        echo $colr "${green}script: ${reset} $1 ${green}is now runnable as: ${reset} $2"
      else 
        echo $colr "${red}No alias specified${reset}"
        exit 1
      fi
      shift 
      shift 
      ;;
    -es|--edit-script)
      shift
	  if test $# -gt 0; then
      	edit_script $1
	  else 
	  	echo $colr "${red}No script specified${reset}"
	  	exit 1
	  fi
      shift 
      ;;
    -ra|--remove-alias)
      shift 
      if test $# -gt 0; then
        remove_alias $1
        echo $colr "${green}alias: ${reset} $1 ${green}is removed ${reset}"
      else 
        echo $colr "${red}No alias specified${reset}"
        exit 1
      fi
      shift
      ;;
    -rma|--remove-all-alias)
      shift
			remove_all_alias
      ;;
    -rs|--remove-script)
      shift
			#NOTE: Output is handled in the function itself.
      remove_script $1
      shift 
      ;;
    -rta|--remove-all-tags)
		  shift 
      remove_all_tags
      echo $colr "${green}All tags are removed${reset}"
      ;;
    -ls|--list)
      shift
      echo $colr "${green} Scripts:${reset}"
      list_scripts
      echo " "
      echo $colr "${green} Aliases:${reset}"
      list_aliases
      echo " "
      echo $colr "${green} Tags:${reset}"
      list_tags
      ;;
    -gen)
      shift
      _gen
      ;;
    -rmto)
      shift
			echo $colr "${red}are you sure you want to remove${reset} ${package}?" 
			printf '%s ' 'y/n:'
			read answer
			if [ $answer = 'y' ]
			then
      	_remove_memento
				exit 0
			else 
				echo $colr "${red}please answer with 'y' or 'n' ${reset}"
				exit 1
			fi
      ;;
    -t|--tag)
      shift
      tag $1
      shift 
      ;;
    -i|--init)
      shift
      _setup_package
      ;;
		*)
			if [ $initialised_pak = false ] && [ $skip_install = false ]
			then 
				printf '%s ' "${package}${cyan} is not yet initialised, want to do that now?${reset}(y/n)"
				read answer
				if [ $answer = 'y' ]
				then 
					_setup_package
					exit 0
				else
					break
				fi
			else
				print_help
				break
			fi
			;;
  esac
done

if [ $restart_default = true ]
then
	restart_shell
fi

exit 0