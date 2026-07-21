import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  resolve: {
    alias: { '@': path.resolve(__dirname, './app/frontend/src') },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    include: ['app/frontend/**/*.{test,spec}.?(c|m)[jt]s?(x)'],
    setupFiles: ['app/frontend/src/testing/setup.ts'],
    // Ignore console.error output in tests, comment out when writing tests as needed
    onConsoleLog(_log, type) {
      if (type === 'stderr') return false;
    },
  },
});
