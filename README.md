# Memento

Makes it easier to navigate the terminal with 'tagged locations, manages all your scripts and aliases.

## Installation 

*Run Configuration*
```shell
chmod +x setup.sh && ./setup.sh
```

**Note:** The script uses its the same code (for setting up other scripts) to set itself up, 'setup.sh' will create and move the neccesary files. 

## Usage

*List all tags, aliases, scripts*

this will print an overview of all items managed within memento to stdout. 

```shell
mto -ls
```

*Help text*
```shell
mto -h
```

### Tags
Tags are callable aliases that move the user to the tagged directory, (no need to remember what lives where in your system)

*Create a tag of the current directory*
```shell
mto -t #will create 't1' (t++), as a callable alias
```
*Labelled tag*
```shell
mto -t project1 #will create 'project1' , as a callable alias
```
*moving to the directory with tagnumber or custom label*
```shell
t1
```
```shell
project1
```

*Remove all tags*
```shell
mto -rta
```

### Scripts
*Move script to scripts and make it excecutable*
```shell
mto -s scriptfile.sh scriptname
```
*Edit script*
```shell
mto -es scriptfile
```

**Note:** if you want to change some functionality within memento itself, you can use this memento edit it;
```shell
mto -es mto_memento.sh
```

*Remove script*
```shell
mto -rs scriptfile
```

### Aliases
*Create alias*
```shell
mto -a aliasname 'alias command'
```
*Remove Alias*
```shell
mto -ra aliasname
```
*Remove Memento*
```shell
mto -rmto
```


