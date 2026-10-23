# IB/IGCSE Learning Platform

The project for the curriculum-aware IB and Cambridge learning platform described in [the master project brief](docs/PROJECT_MASTER_BRIEF.md).

**Criterion Lab is a placeholder working name.** The final brand and domain have not been decided.

## Current status

The repository now contains an initial React + TypeScript frontend preview scaffold. It introduces the planned English learning pathways and the platform's learning philosophy. It is not yet a complete learning product.

Not yet implemented: student accounts, database, lessons, question bank, diagnostic tests, saved attempts, grading workflows, payments, email, or live student data.

## Initial planned pathways

- IB MYP Language and Literature — Years 1–5
- Cambridge Lower Secondary English — Stages 7–9
- Cambridge IGCSE First Language English — grade 9–10 equivalent pathways

These programmes are distinct. The founder must finalise and verify the curriculum map and syllabus editions against official specifications before publishing learning content.

## Technology

- React
- TypeScript
- Vite

## Local development

Install Node.js 20.19+ (or 22.12+), then run:

```bash
npm install
npm run dev
```

Create a production build:

```bash
npm run build
npm run preview
```

## Deployment

Vercel can import this private repository and use the standard Vite build settings. Before commercial launch, re-check current hosting terms and choose a plan/provider appropriate for commercial use and the sensitivity of any student information.

## Security rules

- Keep this repository private.
- Never commit API keys, passwords, `.env` files, student submissions, or private customer information.
- Add secrets only through the hosting provider's environment settings when they are needed.
- Use `docs/PROJECT_MASTER_BRIEF.md` as the source of truth. Update it when a decision is explicitly approved.
