

#!/bin/bash

prepend ()
{
    PATH=${PATH//":$1"/}
    PATH=${PATH//"$1:"/} 
    export PATH="$1:$PATH"
}

prepend /sandbox/maps/maps_server/bin

if [ $OSTYPE = "darwin13" ]; then
    export DYLD_LIBRARY_PATH=
fi

