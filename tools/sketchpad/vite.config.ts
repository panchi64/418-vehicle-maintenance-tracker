import { defineConfig } from 'vite'
import solid from 'vite-plugin-solid'
import { fileURLToPath } from 'node:url'

// The repo root, four levels up from tools/sketchpad/.
const repoRoot = fileURLToPath(new URL('../../', import.meta.url))

export default defineConfig({
  plugins: [solid()],
  resolve: {
    alias: {
      // The sketchpad reads Checkpoint's real token sources rather than keeping
      // its own copies. If Themes.json gains a theme or changes a hue, the
      // sketchpad picks it up on next reload — there is nothing to sync.
      '@checkpoint': `${repoRoot}apps/checkpoint/ios/checkpoint`,
      '@designkit': `${repoRoot}packages/DesignKit/Sources/DesignKit/Resources`,
    },
  },
  server: {
    port: 5273,
    // Required so Vite may serve the font files and Themes.json that live
    // outside this package.
    fs: { allow: [repoRoot] },
  },
})
