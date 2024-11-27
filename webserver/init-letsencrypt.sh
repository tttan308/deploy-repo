  #!/bin/bash
  set -e

  # Cấu hình cơ bản
  domains=(192.168.208.1)
  rsa_key_size=4096
  data_path="./webserver/certbot"
  email="contact@ticketplus.app"
  staging=0

  # Tạo cấu hình TLS nếu chưa có
  if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
    echo "### Downloading TLS parameters ..."
    mkdir -p "$data_path/conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
  fi

  # Yêu cầu chứng chỉ Let’s Encrypt
  echo "### Requesting Let’s Encrypt certificate for $domains ..."
  domain_args=$(printf -- "-d %s " "${domains[@]}")
  email_arg="--email $email"
  [ "$staging" != "0" ] && staging_arg="--staging"

  docker compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
      $staging_arg \
      $email_arg \
      $domain_args \
      --rsa-key-size $rsa_key_size \
      --agree-tos \
      --force-renewal" ssl

  # Reload Nginx
  echo "### Reloading nginx ..."
  docker compose exec webserver nginx -s reload
