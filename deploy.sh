#!/bin/bash
set -e

web_server_name=webserver # service_name of webserver
service_name=backend      # service_name deploy

reload_nginx() {
  nginx_id=$(docker ps -f name=$web_server_name -q | tail -n1)
  docker exec $nginx_id nginx -s reload
}

deploy() {

  if [ -z "$1" ]; then
    # Get version
    read -r -p "Enter version you want to deploy: " version
  else
    version=$1
  fi

  # Check if the input is empty
  if [ -z "$version" ]; then
    echo "You did not enter a version."
    exit 1
  fi

  export VERSION=$version

  echo "Start deploy backend...."
  old_container_id=$(docker ps -f name=$service_name -q | tail -n1)

  # bring a new container online, running new code
  # (nginx continues routing to the old container only)
  echo "Create new container"
 
  docker compose up -d --no-deps --scale $service_name=2 --no-recreate $service_name 
 
  # wait for new container to be available
  echo "Health check new container"
  new_container_id=$(docker ps -f name=$service_name -q | head -n1)
  new_container_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $new_container_id)
  curl --silent --include --retry-connrefused --retry 30 --retry-delay 1 --fail http://$new_container_ip:3000/v1/health ||
    (echo "Deploy fail. Cannot start container!!!" && 
      docker stop $new_container_id &&
      docker rm $new_container_id &&
      docker compose up -d --no-deps --scale $service_name=1 --no-recreate $service_name &&
      exit 111)

  echo -e "\nStart routing requests to the new container (as well as the old)"
  reload_nginx

  echo "Removing old contaner"
  docker stop $old_container_id
  docker rm $old_container_id
  echo "Removed old container"

  echo "Change scale set to 1"
  docker compose up -d --no-deps --scale $service_name=1 --no-recreate $service_name
  
  echo "Stop routing requests to the old container"
  reload_nginx
  echo "Deploy backend successfully!!!"

  echo "Clean up image"
  docker image prune -a -f 
}

deploy $1
