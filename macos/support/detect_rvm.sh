if [[ -e /usr/local/rvm/bin/rvm-exec ]]; then
	export RVM_EXEC=/usr/local/rvm/bin/rvm-exec
elif [[ -e $HOME/.rvm/bin/rvm-exec ]]; then
	export RVM_EXEC=$HOME/.rvm/bin/rvm-exec
else
	echo "*** ERROR: you must have RVM installed"
	exit 1
fi
