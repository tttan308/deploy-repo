# Deployment

## Getting started

```bash
# 1. Clone the repository.
git clone 

# 2. Enter your alia-professional-be folder.
cd 

# 3. Change Webserver & SSL config
- webserver/nginx/app.conf: Replace <domain> -> domain deployment
- webserver/init-letsencrypt.sh: Replace <domain> -> domain deployment

# 4. Run first time.
make bootstrap

# 5. Setup SSL
sudo bash webserver/init-letsencrypt.sh
```

## How to deploy

```bash
# 6. Deploy
make deploy

```
