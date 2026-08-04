# API Reference — Matrimonial Admin API

Base URL: `http://178.212.35.171:3001`
Auth: `Authorization: Bearer <token>` (except login)

## Auth

### POST /auth/login
Public. Login with admin credentials.

```json
Request:  { "userName": "superadmin", "password": "admin123" }
Response: { "access_token": "eyJhbG..." }
```

## Admin endpoints (JWT required)

### Dashboard
| Method | Path | Description |
|--------|------|-------------|
| GET | /admin/dashboard | tenants count, active plans, recent payments |

### Tenants
| Method | Path | Description |
|--------|------|-------------|
| GET | /admin/tenants | List all tenants |
| GET | /admin/tenants/:id | Get one tenant |
| POST | /admin/tenants | Create tenant |
| PATCH | /admin/tenants/:id | Partial update |
| DELETE | /admin/tenants/:id | Delete tenant |

Create tenant payload:
```json
{
  "tenantCode": "shadi",
  "companyName": "Shadi Matrimony",
  "ownerName": "Rahul",
  "email": "rahul@shadi.com",
  "phone": "+919876543210",
  "city": "Mumbai",
  "state": "MH",
  "country": "India",
  "databaseServer": "localhost",        // optional
  "connectionSecretRef": "arn:aws:..."  // optional
}
```
`DatabaseName` is auto-generated: `tenantCode_companyname`.

### Subscription Plans
| Method | Path | Description |
|--------|------|-------------|
| GET | /admin/plans | List plans |
| POST | /admin/plans | Create plan |
| PATCH | /admin/plans/:id | Update plan |
| DELETE | /admin/plans/:id | Delete plan |

Plan payload: `{ "planName", "description", "price", "billingCycle": "monthly|yearly", "isActive" }`

### Email Templates
| Method | Path | Description |
|--------|------|-------------|
| GET | /admin/email-templates | List templates |
| POST | /admin/email-templates | Create template |
| PATCH | /admin/email-templates/:id | Update template |
| DELETE | /admin/email-templates/:id | Delete template |

Template payload: `{ "templateName", "subject", "body", "isActive" }`

### System Settings
| Method | Path | Description |
|--------|------|-------------|
| GET | /admin/settings | List settings |
| PATCH | /admin/settings/:id | Update value |

### Theme Configs
| Method | Path | Description |
|--------|------|-------------|
| GET | /admin/theme-configs/:tenantId | Get theme |
| PATCH | /admin/theme-configs/:tenantId | Update theme (primaryColor, secondaryColor, logoUrl, fontFamily, tagline, contactEmail, contactPhone) |

### Feature Flags
| Method | Path | Description |
|--------|------|-------------|
| GET | /admin/feature-flags/:tenantId | Get flags |
| PATCH | /admin/feature-flags/:tenantId | Update flags (matchingEnabled, videoCallEnabled, kundliMatchingEnabled, maxPhotosPerProfile, customFlags) |

### Provisioning Logs
| Method | Path | Description |
|--------|------|-------------|
| GET | /admin/provisioning/:tenantId | List provisioning steps for tenant |

## Error responses

```json
{ "statusCode": 401, "message": "Unauthorized" }
{ "statusCode": 500, "message": "Internal server error" }
```
