# Contributing to TBDSP

Thank you for your interest in contributing to **The Big DataBase Standards Project**! 🎉  
This guide explains how to add new schemas, improve existing ones, or contribute to the web application.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How to Contribute](#how-to-contribute)
3. [Adding a New Schema](#adding-a-new-schema)
4. [Schema Quality Checklist](#schema-quality-checklist)
5. [Commit Message Convention](#commit-message-convention)
6. [Pull Request Process](#pull-request-process)
7. [Contact](#contact)

---

## Code of Conduct

By participating in this project you agree to be respectful and constructive in all interactions. We follow the [Contributor Covenant v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

---

## How to Contribute

```bash
# 1. Fork and clone
git clone https://github.com/<your-username>/tbdsp.git
cd tbdsp

# 2. Create a feature branch
git checkout -b feat/ecommerce-mysql

# 3. Make your changes (see sections below)

# 4. Commit with a conventional message
git commit -m "feat(schemas): add e-commerce MySQL schema"

# 5. Push and open a PR
git push origin feat/ecommerce-mysql
```

---

## Adding a New Schema

Follow the existing directory convention:

```
schemas/
└── <domain>/           # e.g. healthcare, finance, logistics
    └── <database>/     # e.g. postgresql, mysql, sqlite
        ├── schema.sql
        ├── sample_data.sql
        ├── README.md
        └── erd.mmd     # Mermaid ERD (optional but encouraged)
```

### `schema.sql` requirements

- Use `CREATE TABLE IF NOT EXISTS` (idempotent).
- Include `PRIMARY KEY`, `NOT NULL`, `UNIQUE`, and `FOREIGN KEY` constraints where appropriate.
- Add `CHECK` constraints for business rules (e.g., `price > 0`).
- Create indexes for common query patterns (foreign keys, search columns).
- Add SQL comments (`--` or `COMMENT ON`) explaining non-obvious design choices.
- Use lowercase `snake_case` for all identifiers.
- Include a header comment block with domain, DB system, version, and description.

### `sample_data.sql` requirements

- Insert at least 5–10 rows per table.
- Use realistic, diverse values (avoid `foo`, `bar`, `test`).
- Maintain referential integrity across tables.
- Wrap inserts in a transaction (`BEGIN` / `COMMIT`).

### `README.md` requirements

- **Overview**: one-paragraph description of the domain.
- **Schema diagram**: embed a Mermaid ERD using a fenced code block (` ```mermaid `).
- **Tables**: for each table list its purpose, key columns, and relationships.
- **Design decisions**: explain non-obvious choices (normalization level, indexes, etc.).
- **Setup instructions**: copy-paste `psql` / `mysql` commands.
- **Sample queries**: 3–5 illustrative SELECT statements.

### `erd.mmd`

A standalone [Mermaid](https://mermaid.js.org/) `.mmd` file with the `erDiagram` definition. This makes it easy for tooling (and the future web app) to render the diagram without parsing the README.

---

## Schema Quality Checklist

Before opening a PR, confirm:

- [ ] All table and column names are `snake_case`.
- [ ] Every table has a primary key.
- [ ] Foreign keys are declared and reference existing tables.
- [ ] Appropriate `NOT NULL` constraints are set.
- [ ] At least one index beyond the primary key is present.
- [ ] `sample_data.sql` is wrapped in a transaction.
- [ ] The domain README contains a Mermaid ERD.
- [ ] Setup instructions work on a clean database.
- [ ] No hard-coded passwords or secrets.

---

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short description>

[optional body]
[optional footer]
```

Common types:

| Type | Use when |
|------|----------|
| `feat` | Adding a new schema or domain |
| `fix` | Correcting a schema error |
| `docs` | README or documentation changes |
| `refactor` | Restructuring files without functional change |
| `chore` | Tooling, CI, repo maintenance |

Examples:

```
feat(schemas): add healthcare/postgresql schema
fix(ecommerce): correct FK constraint on order_items
docs(ecommerce): add Mermaid ERD to README
```

---

## Pull Request Process

1. Ensure your branch is up-to-date with `main` before opening a PR.
2. Fill in the PR template (title, description, checklist).
3. Link any relevant issues with `Closes #<issue>`.
4. At least one maintainer review is required before merging.
5. Squash-merge is preferred to keep the history clean.

---

## Contact

Open a [GitHub Issue](https://github.com/Mark-Enet/tbdsp/issues) for questions, ideas, or bug reports.  
We appreciate every contribution, no matter how small. Happy coding! 🚀
