#!/usr/bin/env bash
# Copyright (c) 2013 Dejan Noveski

# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Virtualenvwrapper Freeze - freeze the entire virtualenv collection
#
# Usage: ./virtualenvwrapper_freeze.sh
# The script generates another script, which, when ran, will recreate all frozen virtualenvs
# Requires virtualenvwrapper

export VIRTUALENVWRAPPER_PATH="/usr/bin/virtualenvwrapper.sh"

print_heading()
{
    echo $1
    echo $(echo "$1" | tr -c '\010' '=')
    echo
}

export DUMP_FILENAME="$(pwd)/virtualenvwrapper_freeze_$( date +%s ).sh"

# First check for virtualenvwrapper file. 
if [ ! -f $VIRTUALENVWRAPPER_PATH ];
then
    print_heading "virtualenvwrapper not found. You have to provide the path to virtualenvwrapper script."
    echo "Archlinux: /usr/bin/virtualenvwrapper.sh"
    echo "Ubuntu: /etc/bash_completion.d/virtualenvwrapper"
    read -e -p "Enter the full path to the script (Hint- Check .bashrc): " -i "/usr/bin/virtualenvwrapper.sh" pth;
    export VIRTUALENVWRAPPER_PATH=$pth;
    if [ ! -f $pth ];
    then
        echo "$pth is not a valid path. Exiting";
        exit 1;
    fi
fi

# Source virtualenvwrapper.sh
source $VIRTUALENVWRAPPER_PATH;
print_heading "Virtualenvwrapper sourced. $( virtualenvwrapper_show_workon_options|wc -l) virtual environments found. Starting freeze";


# Add a functionality to source virtualenvwrapper.sh and CTRL-C to the dump file
read -r -d '' SETUP_WRAP << 'EOF'
export VIRTUALENVWRAPPER_PATH="/usr/bin/virtualenvwrapper.sh"
# First check for virtualenvwrapper file. 
if [ ! -f $VIRTUALENVWRAPPER_PATH ];
then
    echo "virtualenvwrapper not found. You have to provide the path to virtualenvwrapper script."
    echo "Archlinux: /usr/bin/virtualenvwrapper.sh"
    echo "Ubuntu: /etc/bash_completion.d/virtualenvwrapper"
    read -e -p "virtualenvwrapper.sh not found. Enter the full path to the script (Hint- Check .bashrc): " -i "/usr/bin/virtualenvwrapper.sh" pth;
    export VIRTUALENVWRAPPER_PATH=$pth;
    if [ ! -f $pth ];
    then
        echo "$pth is not a valid path. Exiting";
        exit 1;
    fi
fi

source $VIRTUALENVWRAPPER_PATH;

# CTRL-C Trap
control_c()
# run if user hits control-c
{
  echo -en "\n*** Ouch! Exiting ***\n"
  exit $?
}
 
# trap keyboard interrupt (control-c)
trap control_c SIGINT

EOF

echo "$SETUP_WRAP" >> $DUMP_FILENAME

# Iterate thru the virtual environments
for venv in $(virtualenvwrapper_show_workon_options)
do
    workon $venv
    echo "#$venv" >> $DUMP_FILENAME

    # Check if the virtual environment is no-site-packages
    cd $(virtualenvwrapper_get_site_packages_dir)
    cd ..
    if [[ -f no-global-site-packages.txt ]];
    then
        echo "mkvirtualenv $venv -p python$(virtualenvwrapper_get_python_version) " >> $DUMP_FILENAME;
    else
        echo "mkvirtualenv $venv -p python$(virtualenvwrapper_get_python_version) --system-site-packages" >> $DUMP_FILENAME;
    fi
    cd ~
    echo "workon $venv" >> $DUMP_FILENAME

    # Freeze!
    while read -r package;
    do
        echo "pip install \"$package\"" >> $DUMP_FILENAME
    done <<< "$(pip freeze)"
    echo >> $DUMP_FILENAME
done
print_heading "Done. To unfreeze execute $DUMP_FILENAME"