# AGENTS.md

## Cursor Cloud specific instructions

This is a Next.js 15 demo app (App Router, TypeScript, Tailwind CSS 4, Vitest).

### Quick reference

| Action | Command |
|--------|---------|
| Dev server | `npm run dev` (port 3000) |
| Build | `npm run build` |
| Lint | `npm run lint` |
| Tests | `npm test` |
| Tests (watch) | `npm run test:watch` |

### Non-obvious notes

- **Vitest cleanup**: `@testing-library/react` does not auto-cleanup between tests in Vitest. Explicit `cleanup()` is configured in `src/__tests__/setup.ts` via `afterEach`.
- **Tailwind v4**: Uses `@tailwindcss/postcss` plugin (not the legacy `tailwindcss` PostCSS plugin). No `tailwind.config.js` file is needed.
- **ESLint flat config**: Uses `eslint.config.mjs` (ESLint 9 flat config format) with `@eslint/eslintrc` FlatCompat for Next.js presets.
- **`next lint` deprecation**: `next lint` still works but shows a deprecation warning in Next.js 15. The `npm run lint` script uses it; migration to the ESLint CLI is optional.
