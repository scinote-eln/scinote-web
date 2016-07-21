#!/bin/bash
set -e

###################################
# VARIABLES
###################################
IMAGE_NAME="railsdocker_web"
PG_IMAGE_NAME="postgres:9.4"
WEB_CONTAINER="web"
DB_CONTAINER="db"
DBDATA_CONTAINER="dbdata"
WIN_HOST_RAILS_WS=$PWD
WIN_HOST_DB_TEST="$PWD/db/test.dump"
WIN_HOST_DB_DEV="$PWD/db/development.dump"
CONTAINER_MOUNT_WS="//tmp//app"
CONTAINER_RAILS_WS_PARENT="//usr//src//"
CONTAINER_RAILS_WS="//usr//src//app"
PORT=3000
###################################


# Show help etc.
PROCEED=0
if [ $# -eq 0 ]; then
  echo "Invalid arguments. Call '$FILENAME help' for more info."
elif [ $1 == "help" ];  then
  echo "Usage: $FILENAME COMMAND/S"
  echo ""
  echo "Windows Boot2Docker helper script. If starting from scratch, the following order of commands should be used to get you started: docker, setup, build."
  echo ""
  echo "Commands:"
  echo "    $FILENAME help		Prints out the help contents"
  echo ""
  echo "    $FILENAME bash		Starts the bash console on host computer with Docker environment configured"
  echo ""
  echo "    $FILENAME docker		Creates the Docker image from the Dockerfile"
  echo ""
  echo "    $FILENAME data		Initializes the data persistent container"
  echo ""
  echo "    $FILENAME run   Starts the Rails server in the configured Docker container"
  echo ""
  echo "    $FILENAME cli   Starts the bash console in the configured Docker container"
  echo "        (with unison syncing which means a bit slower startup, but faster command execution)"
  echo ""
  echo "    $FILENAME cli active    Connects to the bash console in the already running Docker container"
  echo ""
  echo "    $FILENAME cli nosync    Starts the bash console in the configured Docker container"
  echo "        (without database container running)"
  echo "        (without Unison syncing, fast startup but horrendously slow command execution)"
  echo ""
  echo "    $FILENAME cli nodb    Starts the bash console in the configured Docker container"
  echo "        (without database container running)"
  echo "        (with unison syncing which means a bit slower startup, but faster command execution)"
  echo ""
  echo "    $FILENAME db-cli    Starts the bash console in the configured database Docker container"
  echo ""
  echo "    $FILENAME db-cli active Connects to the bash console in the already running database Docker container"
  echo ""
  echo "    $FILENAME psql    Connects to the database of the running database Docker container"
  echo ""
  echo "    $FILENAME pgdump    Dumps the database contents of the running database Docker container into dump files on the host"
  echo ""
  echo "    $FILENAME pgrestore   Restores the database contents of the dump files on host into the Docker container"
  echo ""
  echo "    $FILENAME clean		Removes the Docker image (this will also remove the downloaded packages)"
  echo ""
  echo "    $FILENAME cclean		Removes all the stopped Docker containers (cleans up some disk space)"
else
  PROCEED=1
fi

# Only continue if not help...
if [ $PROCEED -eq 1 ]; then
  cd "$B2D_HOME"

  # Copy of Boot2Docker start.sh from here on

  # clear the MSYS MOTD

  cd "$(dirname "$BASH_SOURCE")"

  ISO="$HOME/.boot2docker/boot2docker.iso"

  if [ ! -e "$ISO" ]; then
    echo 'copying initial boot2docker.iso (run "boot2docker.exe download" to update)'
    mkdir -p "$(dirname "$ISO")"
    cp ./boot2docker.iso "$ISO"
  fi

  echo 'initializing...'
  ./boot2docker.exe init
  echo

  echo 'starting...'
  ./boot2docker.exe start
  echo

  echo 'IP address of docker VM:'
  ./boot2docker.exe ip
  B2D_IP="$(./boot2docker.exe ip)"
  echo

  echo 'setting environment variables ...'
  ./boot2docker.exe shellinit | sed  's,\\,\\\\,g' # eval swallows single backslashes in windows style path
  eval "$(./boot2docker.exe shellinit 2>/dev/null | sed  's,\\,\\\\,g')"
  echo

  # Modification of original code
  cd "$VBOX_HOME"
  echo "$VBOX_HOME"
  set +e
  "$VBOX_HOME/"VBoxManage controlvm boot2docker-vm natpf1 delete "rails-server"
  set -e
  "$VBOX_HOME/"VBoxManage controlvm boot2docker-vm natpf1 "rails-server,tcp,127.0.0.1,$PORT,,$PORT"
  cd "$B2D_HOME"

  echo 'You can now use `docker` directly, or `boot2docker ssh` to log into the VM.'


  # End of copy Boot2Docker start.sh

  if [ $1 == "bash" ]; then
    exec "$BASH" --login -i
  elif [ $1 == "docker" ]; then
    exec "$BASH" --login -i -c "\
      cd $WIN_HOST_RAILS_WS\
      ;docker pull $PG_IMAGE_NAME\
      ;docker build -t $IMAGE_NAME .\
      ;docker rm $WEB_CONTAINER\
      ;docker rm $DB_CONTAINER"
  elif [ $1 == "data" ]; then
    exec "$BASH" --login -i -c "\
      docker create \
        -v //var//lib//postgres \
        --name $DBDATA_CONTAINER \
        $PG_IMAGE_NAME \
        //bin//true"
  elif [ $1 == "run" ]; then
    exec "$BASH" --login -i -c "\
      docker kill $WEB_CONTAINER\
      ;docker rm $WEB_CONTAINER\
      ;docker kill $DB_CONTAINER\
      ;docker rm $DB_CONTAINER\
      ;docker run \
        --rm \
        --name $DB_CONTAINER \
        --volumes-from $DBDATA_CONTAINER \
        -p 5432:5432 \
        $PG_IMAGE_NAME \
      & (sleep 10\
      ;docker run \
        --rm \
        --name $WEB_CONTAINER \
        --link $DB_CONTAINER:db \
        -ti \
        -v $WIN_HOST_RAILS_WS:$CONTAINER_MOUNT_WS \
        -w $CONTAINER_MOUNT_WS \
        -p $PORT:$PORT \
        -u 'root' \
        $IMAGE_NAME \
        //bin//bash -l -c '\
          rm -r tmp/pids/server.pid\
          ;export PATH=/usr/local/bundle/bin:\$PATH\
          ;cp -rf $CONTAINER_MOUNT_WS// $CONTAINER_RAILS_WS_PARENT\
          ;chmod -R 777 $CONTAINER_MOUNT_WS\
          ;chmod -R 777 $CONTAINER_RAILS_WS\
          ;unison \
            $CONTAINER_MOUNT_WS \
            $CONTAINER_RAILS_WS \
            -perms 0 \
            -ignorecase false \
            -links false \
            -ignoreinodenumbers \
            -auto \
            -silent \
            -ignore \"Path vendor/bundle\" \
            -ignore \"Path .git\" \
            -ignore \"Path .bundle\" \
            -repeat 1 \
          > /dev/null \
          & chmod -R 777 $CONTAINER_RAILS_WS\
          ;cd $CONTAINER_RAILS_WS\
          ;rails server -b 0.0.0.0 -p $PORT')"
  elif [[ ( $1 == "cli" ) && ( $2 == "active" ) ]]; then
    exec "$BASH" --login -i -c "\
      docker exec \
        -ti \
        $WEB_CONTAINER \
        //bin//bash -l"
  elif [[ ( $1 == "cli" ) && ( $2 == "nosync" ) ]]; then
    exec "$BASH" --login -i -c "\
      docker kill $WEB_CONTAINER\
      ;docker rm $WEB_CONTAINER\
      ;docker run \
        --rm \
        --name $WEB_CONTAINER \
        -ti \
        -v $WIN_HOST_RAILS_WS:$CONTAINER_RAILS_WS \
        -w $CONTAINER_RAILS_WS \
        -p $PORT:$PORT \
        $IMAGE_NAME \
        //bin//bash -l"
  elif [[ ( $1 == "cli" ) && ( $2 == "nodb" ) ]]; then
    exec "$BASH" --login -i -c "
      docker kill $WEB_CONTAINER\
      ;docker rm $WEB_CONTAINER\
      ;docker run \
        --rm \
        --name $WEB_CONTAINER \
        -ti \
        -v $WIN_HOST_RAILS_WS:$CONTAINER_MOUNT_WS \
        -w $CONTAINER_MOUNT_WS \
        -u 'root' \
        $IMAGE_NAME //bin//bash -l -c '\
          rm -r tmp/pids/server.pid\
          ;export PATH=/usr/local/bundle/bin:\$PATH\
          ;cp -rf $CONTAINER_MOUNT_WS// $CONTAINER_RAILS_WS_PARENT\
          ;chmod -R 777 $CONTAINER_MOUNT_WS\
          ;chmod -R 777 $CONTAINER_RAILS_WS\
          ;unison \
            $CONTAINER_MOUNT_WS \
            $CONTAINER_RAILS_WS \
            -perms 0 \
            -ignorecase false \
            -links false \
            -ignoreinodenumbers \
            -auto \
            -silent \
            -ignore \"Path vendor/bundle\" \
            -ignore \"Path .git\" \
            -ignore \"Path .bundle\" \
            -repeat 1 \
          > /dev/null \
          & chmod -R 777 $CONTAINER_RAILS_WS\
          ;cd $CONTAINER_RAILS_WS\
          ;//bin//bash'"
  elif [ $1 == "cli" ]; then
    exec "$BASH" --login -i -c "
      docker kill $WEB_CONTAINER\
      ;docker rm $WEB_CONTAINER\
      ;docker kill $DB_CONTAINER\
      ;docker rm $DB_CONTAINER\
      ;docker run \
        --rm \
        --name $DB_CONTAINER \
        --volumes-from $DBDATA_CONTAINER \
        -p 5432:5432 \
        $PG_IMAGE_NAME \
      > /dev/null \
      & (sleep 10\
      ;docker run \
        --rm \
        --name $WEB_CONTAINER \
        --link $DB_CONTAINER:db \
        -ti \
        -v $WIN_HOST_RAILS_WS:$CONTAINER_MOUNT_WS \
        -w $CONTAINER_MOUNT_WS \
        -u 'root' \
        $IMAGE_NAME //bin//bash -l -c '\
          rm -r tmp/pids/server.pid\
          ;export PATH=/usr/local/bundle/bin:\$PATH\
          ;cp -rf $CONTAINER_MOUNT_WS// $CONTAINER_RAILS_WS_PARENT\
          ;chmod -R 777 $CONTAINER_MOUNT_WS\
          ;chmod -R 777 $CONTAINER_RAILS_WS\
          ;unison \
            $CONTAINER_MOUNT_WS \
            $CONTAINER_RAILS_WS \
            -perms 0 \
            -ignorecase false \
            -links false \
            -ignoreinodenumbers \
            -auto \
            -silent \
            -ignore \"Path vendor/bundle\" \
            -ignore \"Path .git\" \
            -ignore \"Path .bundle\" \
            -repeat 1 \
          > /dev/null \
          & chmod -R 777 $CONTAINER_RAILS_WS\
          ;cd $CONTAINER_RAILS_WS\
          ;//bin//bash')"
  elif [[ ( $1 == "db-cli" ) && ( $2 == "active" ) ]]; then
    exec "$BASH" --login -i -c "\
      docker exec \
        -ti \
        $DB_CONTAINER \
        //bin//bash -l"
  elif [ $1 == "db-cli" ]; then
    exec "$BASH" --login -i -c "\
      docker kill $DB_CONTAINER\
      ;docker rm $DB_CONTAINER\
      ;docker run \
        --rm \
        --name $DB_CONTAINER \
        -ti \
        --volumes-from $DBDATA_CONTAINER \
        -p 5432:5432 \
        $PG_IMAGE_NAME \
        //bin//bash -l"
  elif [ $1 == "psql" ]; then
    eval "'$PSQL_BIN/psql' -h $B2D_IP -p 5432 -U postgres"
  elif [ $1 == "pgdump" ]; then
    eval "'$PSQL_BIN/pg_dump' -h $B2D_IP -p 5432 -U postgres -f '$WIN_HOST_DB_TEST' -O -c -C scinote_test"
    eval "'$PSQL_BIN/pg_dump' -h $B2D_IP -p 5432 -U postgres -f '$WIN_HOST_DB_DEV' -O -c -C scinote_development"
  elif [ $1 == "pgrestore" ]; then
    eval "'$PSQL_BIN/psql' -h $B2D_IP -p 5432 -U postgres -f '$WIN_HOST_DB_TEST' -d scinote_test"
    eval "'$PSQL_BIN/psql' -h $B2D_IP -p 5432 -U postgres -f '$WIN_HOST_DB_DEV' -d scinote_development"
  elif [ $1 == "clean" ]; then
    exec "$BASH" --login -i -c "\
      docker rmi -f $IMAGE_NAME\
      ;docker rmi -f $PG_IMAGE_NAME"
  elif [ $1 == "cclean" ]; then
    exec "$BASH" --login -i -c "\
      docker rm $(docker ps -a -q)"
  fi
fi
unset IMAGE_NAME
unset PG_IMAGE_NAME
unset WEB_CONTAINER
unset DB_CONTAINER
unset WIN_HOST_RAILS_WS
unset WIN_HOST_DB_TEST
unset WIN_HOST_DB_DEV
unset CONTAINER_RAILS_WS
unset PORT
unset B2D_IP
unset PROCEED