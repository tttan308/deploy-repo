#!/bin/bash
set -e

backend_service=backend   # Tên service backend
frontend_service=frontend # Tên service frontend
migration_command="npm run migrate:run:prod" # Lệnh chạy migration

deploy() {
  if [ -z "$1" ]; then
    # Yêu cầu nhập version
    read -r -p "Enter version you want to deploy: " version
  else
    version=$1
  fi

  # Kiểm tra version có hợp lệ không
  if [ -z "$version" ]; then
    echo "No version provided."
    exit 1
  fi

  export VERSION=$version
  echo "Deploying version $version..."

  # Chạy migration trước cho backend
  echo "Running backend migrations..."
  docker compose run --rm $backend_service $migration_command

  # Deploy backend
  echo "Deploying backend..."
  docker compose up -d --no-deps --scale $backend_service=1 --no-recreate $backend_service

  # Kiểm tra container backend đang chạy
  echo "Checking backend container..."
  backend_container_id=$(docker ps -f name=$backend_service -q | head -n1)
  if [ -z "$backend_container_id" ]; then
    echo "Backend container failed to start!"
    exit 1
  fi

  # Kiểm tra cổng dịch vụ backend (3030)
  echo "Checking backend on port 3030..."
  backend_container_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $backend_container_id)
  echo $backend_container_ip
  if ! nc -z $backend_container_ip 3030; then
    echo "Backend is not accepting connections on port 3030!"
    exit 1
  fi
  echo "Backend deployed successfully."

  # Deploy frontend
  echo "Deploying frontend..."
  docker compose up -d --no-deps --scale $frontend_service=1 --no-recreate $frontend_service

  # Kiểm tra container frontend đang chạy
  echo "Checking frontend container..."
  frontend_container_id=$(docker ps -f name=$frontend_service -q | head -n1)
  if [ -z "$frontend_container_id" ]; then
    echo "Frontend container failed to start!"
    exit 1
  fi

  # Kiểm tra cổng dịch vụ frontend (3000)
  echo "Checking frontend on port 3000..."
  frontend_container_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $frontend_container_id)
  if ! nc -z $frontend_container_ip 3000; then
    echo "Frontend is not accepting connections on port 3000!"
    exit 1
  fi
  echo "Frontend deployed successfully."
}

deploy $1
