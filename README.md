# Memento
handles tags, aliases, scripts

## Installation 

*Run Configuration*
```shell
chmod +x setup.sh && ./setup.sh
```
Note: The script uses its the same code (for setting up other scripts) to set itself up, 'setup.sh' will create and move the neccesary files. 

## Usage

*List all tags, aliases, scripts*
```shell
mto -ls
```

*Help text*
```shell
mto -h
```

### Tags
*Create a tag of the current directory*
```shell
mto -t #will create 't1' (t++), as a callable alias
```
*Labelled tag*
```shell
mto -t project1
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


