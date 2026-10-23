# IB/IGCSE Learning Platform

The project for the curriculum-aware IB and Cambridge learning platform described in the master project brief (docs/PROJECT_MASTER_BRIEF.md). The agreed screen design is described in docs/DESIGN_SPEC.md.

**Criterion Lab is a placeholder working name.** The final brand and domain have not been decided.

## Current status

The repository contains a React + TypeScript frontend prototype with five clickable screens:
- Public homepage and pathway discovery.
- Student dashboard.
- Lesson and sample practice interaction.
- Searchable and filterable question-bank prototype.
- Human-assessment feedback concept screen.

**This is a static design prototype, not a live learning product.** Dashboard numbers, activity, questions, rubric criteria, marks and feedback are fictional demonstration data. The sample lesson has not been verified against a specific syllabus edition. The answer check and filters are local prototype interactions; they do not save real learner records.

Not yet implemented: authentication, database, persistent learner records, released syllabus-mapped content, diagnostics, server-side saved attempts, real grading/submission workflows, payments, transactional email or production analytics.

## Initial planned pathways

- IB MYP Language and Literature — Years 1–5
- Cambridge Lower Secondary English — Stages 7–9
- Cambridge IGCSE First Language English — grade 9–10 equivalent pathways

These programmes are distinct. Course and syllabus mapping must be verified against official specifications before content publication. Stage 1 is a starter pathway, not exhaustive coverage.

## Technology

- React
- TypeScript
- Vite

## Local development

Install Node.js 20.19+ (or 22.12+), run npm install, then npm run dev to start the development preview. Run npm run build to check TypeScript and generate a production build.

## Deployment

Vercel can import this private repository and use the standard Vite settings. Before commercial launch, re-check hosting terms and choose a plan/provider appropriate for commercial use and the sensitivity of any student information.

## Security rules

- Keep this repository private.
- Never commit API keys, passwords, .env files, student submissions or private customer information.
- Add secrets only through the hosting provider's environment settings when needed.
- Use docs/PROJECT_MASTER_BRIEF.md as the source of truth. Update it when a decision is explicitly approved.
