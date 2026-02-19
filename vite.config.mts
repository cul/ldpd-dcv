import { defineConfig } from 'vite';
import RubyPlugin from 'vite-plugin-ruby';
import basicSsl from '@vitejs/plugin-basic-ssl';

export default defineConfig({
  plugins: [
    // When the basicSsl plugin is active, Vite will automatically generate a self-signed
    // cert when the server is running under https.
    basicSsl({}),
    RubyPlugin(),
  ],
});
