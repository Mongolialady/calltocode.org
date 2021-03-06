#!/usr/bin/env bash

set +x -eu -o pipefail

DB=mongo
NAME=c4sg
ID_FROM_DB=$(docker ps -aq -f ancestor=$DB)
ID_FROM_NAME=$(docker ps -aq -f name=$NAME)

start () {
  # Make sure a container isn't already running
  if [[ -z "$ID_FROM_DB" && -z "$ID_FROM_NAME" ]] ; then
    echo "Starting new docker container with MongoDB.."
    docker run --name $NAME -d -p 27017:27017 -p 28017:28017 $DB | xargs echo "Started container"

    echo "Copying seed data to docker container.."
    docker cp ./db/seedData/users.json $NAME:users.json
    docker cp ./db/seedData/projects.json $NAME:projects.json

    echo "Adding seed data to MongoDB.."
    docker exec $NAME mongoimport --db admin --collection users --file users.json --type json --jsonArray
    docker exec $NAME mongoimport --db admin --collection projects --file projects.json --type json --jsonArray
  else
    echo "Skipping start, container already running"
    exit 0
  fi
}

stop () {
  # Make sure there's a container to stop
  if [[ ! -z "$ID_FROM_DB" ]] ; then
    ID=$ID_FROM_DB
  elif [[ ! -z "$ID_FROM_NAME" ]] ; then
    ID=$ID_FROM_NAME
  else
    echo "Skipping stop and remove, no container found"
    exit 0
  fi

  echo "Stopping and removing docker container.."
  docker stop $ID | xargs echo "Stopped container"
  docker rm $ID | xargs echo "Removed container"
}

info () {
cat <<EOF
  Usage: ./db/run.sh <target>
  Targets:
    start - start a docker container with seeded MongoDB
    stop - stop and remove the docker container
EOF
}

case $1 in
  start)    start    ;;
  stop)     stop     ;;
  *)        info     ;;
esac
