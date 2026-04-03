# E-Commerce — MySQL (Coming Soon)

This directory is a placeholder for the MySQL variant of the e-commerce schema.

The schema will be functionally equivalent to the [PostgreSQL version](../postgresql/README.md) but adapted for MySQL 8.0+ syntax and features:

- `AUTO_INCREMENT` or `UUID()` primary keys
- `ENUM` column type instead of custom PostgreSQL enum types
- `JSON` columns (supported since MySQL 5.7.8) for variant attributes
- `DATETIME` / `TIMESTAMP` for time columns
- MySQL-compatible index and constraint syntax

## Planned file structure

```
mysql/
├── schema.sql
├── sample_data.sql
├── README.md
└── erd.mmd
```

Want to contribute this schema? See [CONTRIBUTING.md](../../../../CONTRIBUTING.md).
