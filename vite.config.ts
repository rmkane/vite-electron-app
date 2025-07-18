import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  base: './', // Fix Electron asset loading
  server: {
    host: '0.0.0.0', // Allow external connections (Docker)
    port: 5173,
    strictPort: true, // Fail if port is in use
  },
})
