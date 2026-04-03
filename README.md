# TBDSP — The Big DataBase Standards Project

> An open-source collection of standardized, reusable database schemas with sample data, documentation, and a future interactive web UI.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## 🎯 Vision

TBDSP provides production-ready, well-documented database schemas organized by **domain** (e.g., e-commerce, healthcare, finance) and **database system** (PostgreSQL, MySQL, …).  
Every schema comes with:

- ✅ Fully annotated DDL (`schema.sql`)
- ✅ Realistic sample data (`sample_data.sql`)
- ✅ Entity-Relationship Diagram (Mermaid)
- ✅ Design decisions & best-practice notes
- ✅ Copy-paste setup instructions

A **React + Flask** web application will later make all schemas searchable and browsable interactively.

---

## 📂 Repository Layout

```text
TBDSP/
├── README.md              ← you are here
├── LICENSE                ← MIT
├── CONTRIBUTING.md        ← how to add schemas / domains
├── .gitignore
├── docs/                  ← project-wide documentation (roadmap, ADRs, …)
├── backend/               ← future Flask/Node API
├── frontend/              ← future React web UI
└── schemas/
    └── ecommerce/
        ├── postgresql/
        │   ├── schema.sql
        │   ├── sample_data.sql
        │   ├── README.md
        │   └── erd.mmd
        └── mysql/         ← coming soon
```

---

## 🗂️ Schema Catalogue

| Domain | Database | Status |
|--------|----------|--------|
| [E-Commerce](schemas/ecommerce/postgresql/README.md) | PostgreSQL | ✅ Available |
| E-Commerce | MySQL | 🚧 Planned |
| Healthcare | PostgreSQL | 🔜 Roadmap |
| Finance | PostgreSQL | 🔜 Roadmap |

---

## 🚀 Quick Start

### Use a schema

```bash
# Clone the repo
git clone https://github.com/Mark-Enet/tbdsp.git
cd tbdsp

# Load the e-commerce PostgreSQL schema
psql -U <your_user> -d <your_db> -f schemas/ecommerce/postgresql/schema.sql

# Optionally load sample data
psql -U <your_user> -d <your_db> -f schemas/ecommerce/postgresql/sample_data.sql
```

### Browse schemas online

Visit the [GitHub repository](https://github.com/Mark-Enet/tbdsp) and navigate into the `schemas/` directory, or read the domain-specific README files for full context.

---

## 🗺️ Roadmap

1. **Phase 1 — Schema Library** *(current)*
   - [x] E-Commerce domain — PostgreSQL
   - [ ] E-Commerce domain — MySQL
   - [ ] Healthcare domain — PostgreSQL
   - [ ] Finance domain — PostgreSQL

2. **Phase 2 — Web Application**
   - [ ] Flask REST API serving schema metadata
   - [ ] React UI with schema browser & search
   - [ ] Mermaid ERD rendering in-browser

3. **Phase 3 — Community & CI**
   - [ ] Schema validation CI (SQL linting)
   - [ ] Community-contributed domains

---

## 🤝 Contributing

Contributions are warmly welcome!  
Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## Getting Started (legacy app setup)
