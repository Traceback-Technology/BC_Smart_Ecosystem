# Roles & Permissions

## User Roles

### Student

Permissions:

- Login
- Navigate campus
- Order food
- Track orders
- View own profile

---

### Visitor

Permissions:

- QR access only
- Limited campus navigation

Restrictions:

- No ordering
- No private services

---

### Staff

Permissions:

- Manage tuckshop orders
- Update order status
- View reports

---

### Admin

Permissions:

- Full system access
- User management
- Analytics access
- Security monitoring
- Infrastructure configuration

---

## Access Matrix

| Feature | Student | Visitor | Staff | Admin |
|----------|----------|----------|--------|--------|
| Navigation | ✓ | ✓ | ✓ | ✓ |
| Order Food | ✓ | ✗ | ✗ | ✓ |
| Manage Orders | ✗ | ✗ | ✓ | ✓ |
| Analytics | ✗ | ✗ | ✓ | ✓ |
| System Config | ✗ | ✗ | ✗ | ✓ |