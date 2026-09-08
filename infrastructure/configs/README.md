
# Infrastructure Configuration

This directory contains application configuration files.

## Environments

### Development

Local developer environment.

### Production

Production deployment environment.

---

## Files

| File                    | Purpose                          |
| ----------------------- | -------------------------------- |
| development.env.example | Local development variables      |
| production.env.example  | Production environment variables |
| docker-compose.yml      | Local service orchestration      |

---

## Security Notice

Never commit:

* `.env`
* Secrets
* API keys
* JWT secrets
* Database passwords
