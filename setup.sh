initialised_pak=false
restart_default=false
script_dir='/usr/local/bin'
callsign='mto'
default_editor='vim'




#'''======Change code only below this point======='''
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
TEMPFILE='_mto_cnt.tmp'

#for tagging without input, a counter file is used.
if [ ! -f '_mto_cnt.tmp' ]; then
	echo 0 > $TEMPFILE
else
	tag_count=$[$(cat $TEMPFILE) + 1]
fi

# -e needed for bash colour output
if [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ]
then 
  colr=""
else
  colr="-e"
	read_assist="-p"
fi

#make an alias
append_src () {
	if [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ]
	then
		alname=$1
		alcomm=$2
		printf "alias %s='%s' #alias made by $package\n" "$alname" "$alcomm" >> ~/.zshrc
	elif [ $usedshell = "/bin/bash" ] || [ $usedshell = "bash" ]
	then
		alname=$1
		alcomm=$2
		printf "alias %s='%s' #alias made by $package\n" "$alname" "$alcomm" >> ~/.bashrc
	else 
		_list_rc
	fi
}

#make a script globally exc
make_global() {
	if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ] || [ $usedshell = "zsh" ]
	then
		#rename script for find function
		new_scriptname="$extention$1"
		mv $1 "${new_scriptname}"
		#move scripts to bin
		mv $PWD/"${new_scriptname}" $script_dir/
		chmod +x $script_dir/"${new_scriptname}"
		# add alias for script
		echo "alias $2='${new_scriptname}' #alias made by $package" >> ~/.zshrc
	elif  [ $usedshell = "/bin/bash" ] || [ $usedshell = "bash" ]
	then
		#rename script for find function
		new_scriptname="$extention$1"
		mv $1 "${new_scriptname}"
		#move scripts to bin
		mv $PWD/"${new_scriptname}" $script_dir/
		chmod +x $script_dir/"${new_scriptname}"
		# add alias for script
		echo "alias $2='${new_scriptname}' #alias made by $package" >> ~/.bashrc
	else 
		_list_rc
	fi
}

edit_script() {
	if [ -f "$1" ]; then
		$default_editor $1
	else 
		echo $colr "${red}Script${reset} $1 ${red}not found${reset}"
	fi
}

list_aliases() {
	if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ]
	then
		grep "alias made by $package" ~/.zshrc
	elif [ $usedshell = "/bin/bash" ] || [ $usedshell = "bash" ]
	then
		grep "alias made by $package" ~/.bashrc 
	else 
		_list_rc
	fi
}

list_scripts() {
	find $script_dir -name "$extention*"
}

list_tags() {
	if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ]
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
  if  [ $usedshell = "/bin/zsh" ] || [ $usedshell == "sh" ]
	then
    sed "/tag/d" ~/.zshrc > temp
		echo "" > ~/.zshrc
		cat temp > ~/.zshrc
		rm temp
		rm $TEMPFILE
	elif  [ $usedshell = "/bin/bash" ] || [ $usedshell == "bash" ]
	then
		sed "/tag/d" ~/.bashrc > temp
		echo "" > ~/.bashrc
		cat temp > ~/.bashrc
		rm temp
		rm $TEMPFILE
	else 
		_list_rc
	fi
}

remove_script() {
	if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ]
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
	if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ]
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
    if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ]
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
	if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ]
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
  tagn=$(pwd)
  if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ]
	then
		if [ $# -eq 0 ]
		then
		if [ ! -f "$TEMPFILE" ]; then
			echo 0 > $TEMPFILE
		fi
			echo $tag_count > $TEMPFILE
			alname="t$(cat $TEMPFILE)" 
			echo 'alname'
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
		if [ ! -f "$TEMPFILE" ]; then
			echo 0 > $TEMPFILE
		fi
			echo $tag_count > $TEMPFILE
			alname="t$(cat $TEMPFILE)" 
			echo 'alname'
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

print_help() {
    echo " "
    echo $colr "${cyan}$package${cyan} [options] [arguments]"
		echo "- handles tags, aliases, scripts"
    echo " "
    echo "options:"
    echo "-h, --help                show brief help"
    echo $colr "-a|--alias, ${green}ALIAS${reset} ${cyan}COMMAND${reset}       make a new alias"
    echo $colr "    Usage: ${package} -a ${green}hello${reset} ${cyan}'echo hello' ${reset}"
    echo $colr "-s|--script, ${green}SCRIPT${reset} ${cyan}NAME${reset} make a script globally excecutable"
    echo $colr "    Usage: ${package} -s ${green}hello.sh${reset} ${cyan}'hello' ${reset}"
	echo $colr "-es|--edit-script, ${green}SCRIPTFILE${reset} edit a script"
		echo $colr "-t|--tag, ${green}NAME${reset} create a tag in the current directory"
		echo $colr "    Usage:${package}-a ${green} projectag (optional)${reset} create a tag in the current directory"
		echo $colr "-rta|--remove-all-allias, remove all tags"
    echo $colr "-ra|--remove-alias, ${green}ALIAS${reset} remove a alias"
		echo $colr "-rma|--remove-alias, remove all aliases"
    echo $colr "-rs|--remove-script, ${green}SCRIPT${reset} remove a script"
    echo $colr "-ls|--list,  list scripts and aliases"
		echo $colr "-e|--exec,  restart the shell"
		echo $colr "-i|--init,  configure ${package}"
    exit 0
}

# random script generator, to be used for tests
_gen() {
	num=$(( ( RANDOM % 10 )  + 1 ))
	num2=$(( ( RANDOM % 10 )  + 1 ))
	ran=$num$num2"_script"
	# TODO: change to default shell
	echo "#!/bin/zsh" >> $ran.sh
	echo "echo $ran testing command" >> $ran.sh
	echo " " >> $ran.sh
	echo $ran.sh
}

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
		echo $colr "${cyan}The default settings are:${reset}"
		echo $colr "${cyan}default shell is:${reset} $usedshell."
		echo $colr "${cyan}The default script directory is:${reset} $script_dir"
		echo $colr "${cyan}Shell restart is:${reset} $restart_default"
		echo $colr "${cyan}Remove${reset} $filename${cyan} after setup: ${reset}False"
		echo $colr "${cyan}The default editor is${reset} $default_editor${reset}."
		echo $colr "${cyan}The default command name for ${reset}${package} ${cyan}is${reset} ${callsign}."
		printf '%s ' "${cyan}Do you want to change any of these settings? ${reset}(y/n)"
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
	echo "restart_default=true" >> $exp_file
	echo "initialised_pak=true" >> $exp_file
	echo "callsign='mto'" >> $exp_file
	echo "default_editor=vim" >> $exp_file
	tail -n +10 $filename >> $exp_file
    make_global $exp_file mto
	echo $colr "${green}${package} is initialised. use ${reset}'$callsign'${green} to call it.${reset}"
	restart_shell
}

_change_config() {
		# Change the settings
		echo "#!/bin/$usedshell" >> $exp_file
		if  [ $usedshell = "/bin/zsh" ] || [ $usedshell = "sh" ]
		then
			shellname="zsh"
			echo $colr "${green}${package} configuration${reset}"
		else
			shellname=$usedshell
    		echo $colr "${green}${package} configuration${reset}"
		fi
		# Change Shell
		printf '%s ' "${cyan}default shell is:${reset} $shellname. ${cyan}change?${reset} (y/n)"
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
		# Change script dir
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
		# Restart default
		echo $colr "${cyan}Do you want to restart the shell (exec shell) after each command?${reset}"
		printf '%s ' "${cyan}this is required for aliases to take direct effect.${reset} (y/n)"
		read answer
		if [ $answer = 'y' ]
		then
			echo "restart_default=true" >> $exp_file
		else 
			echo "restart_default=false" >> $exp_file
		fi
		

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
		# remove the setup.sh contents
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
		# initiliasisation check 
		echo "initialised_pak=true" >> $exp_file
		#change command name
		echo $colr "${cyan}The default command name for ${reset}${package} ${cyan}is${reset} ${callsign}."
		printf '%s ' "${cyan}change? ${reset}(y/n)"
		read answer
    	if [ $answer = 'y' ]
		then 
			printf '%s ' "${cyan}Enter a new name: ${reset}"
			read answer
			echo "callsign='$answer'" >> $exp_file
			tail -n +10 $filename >> $exp_file
			make_global memento.sh $answer
			echo $colr "${green}${package} is initialised. use ${reset}'$answer'${green} to call it.${reset}"
		else 
			echo "callsign='mto'" >> $exp_file
			tail -n +10 $filename >> $exp_file
			make_global $exp_file mto
			echo $colr "${green}${package} is initialised. use ${reset}'$callsign'${green} to call it.${reset}"
		fi
		restart_shell
		exit 0
}

_change_shell() {
	printf '%s ' "${cyan}new default shell: ${reset}"
	read answer
	if [ $answer = "zsh" ]
	then
		chsh -s '/bin/zsh'
		echo "${green}zsh${reset} is the new default shell"
	elif [ $answer = "bash" ]
	then
		chsh -s /bin/bash
		echo -n $colr "${green}bash${reset} is the new default shell"
	else 
		echo $colr "${red}shell not supported, supported shells are: bash, zsh ${reset}"
	fi
}

_list_rc () {
		echo "shellrc file not found. current shell: $usedshell"
		echo "rc files found:"
		find ~/ -maxdepth 1 -name '*rc'
		exit 1
}

_remove_memento() {
	remove_script _mto_memento.sh
	find $script_dir  -maxdepth 1 -name '_mto_memento.sh' #~/
	remove_alias '_mto_memento.sh'
	echo $colr "${cyan} ${package} is removed${reset}"
	restart_shell
}

#first run from the setup script
if [[ $# -eq 0 ]] ; then
    if [ $initialised_pak = false ]
		then 
			echo $colr "${cyan}${package} is not yet initialised, want to do that now?${reset} ?" 
			printf '%s ' '(y/n)'
			read answer
			if [ $answer = 'y' ]
				then 
					chmod +x setup.sh 
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

while test $# -gt 0; do
  case "$1" in
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
			if [ $initialised_pak = false ]
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
