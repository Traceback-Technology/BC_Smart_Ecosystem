# Authorization Flow

## Authentication Process

```txt
User Login
    │
    ▼
Validate Credentials
    │
 ┌──┴───────┐
 ▼          ▼
Invalid    Valid
 ▼          ▼
Error      Generate JWT
                │
                ▼
          Assign Role
                │
                ▼
        Access Protected APIs