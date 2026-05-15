# Eliminate es5-ext via pnpm Override

## Background

- **Problem:** `es5-ext@0.10.64` is a transitive dependency pulled in via `vue-reader` -> `epubjs@0.3.93` -> `event-emitter` -> `es5-ext`
- **CVE-2024-27088** (ReDoS, CVSS 0.0) is already patched in the installed version, but eliminating es5-ext entirely removes future risk

## Chosen Approach: pnpm Override with @likecoin/epub-ts

[@likecoin/epub-ts](https://github.com/likecoin/epub.ts) (v0.6.3, Apr 2026) is a TypeScript rewrite of epubjs v0.3.93 that:
- Has the **exact same API** (drop-in replacement, "change one import line")
- Has only **1 runtime dependency** (`jszip`) -- no es5-ext, no event-emitter, no d, no es6-iterator
- Is 56.7% smaller bundle, significantly faster
- Exports all the same classes: `Book`, `Rendition`, `Themes`, `Contents`, etc.
- Supports `requestCredentials`, `getRendition`, `themes.override` -- everything used in `frontend/src/views/files/Preview.vue`

## Implementation

Add to `frontend/package.json`:

```json
"pnpm": {
  "overrides": {
    "epubjs": "npm:@likecoin/epub-ts@^0.6.3"
  }
}
```

Then run `pnpm install` to regenerate the lockfile.

## What This Does

- When `vue-reader` (or any other package) imports `epubjs`, pnpm resolves it to `@likecoin/epub-ts` instead
- The existing `import type { Rendition } from "epubjs"` in Preview.vue continues to work (the alias covers type resolution too)
- No code changes needed in any `.vue` or `.ts` files
- The entire es5-ext dependency tree (`es5-ext`, `es6-iterator`, `es6-symbol`, `esniff`, `event-emitter`, `d`, `next-tick`) is removed from the lockfile

## Why Not vue-book-reader

After deeper research, `vue-book-reader` is **not viable** for this project:
- Does not support `requestCredentials` (needed for authenticated EPUB fetching)
- Does not expose `getRendition` (needed for theme/font-size control)
- Only 12 GitHub stars (low adoption for production use)
- Completely different rendering engine (foliate-js) requiring significant code rewrite
