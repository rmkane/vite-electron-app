#!/usr/bin/env bash
set -e

# Start Vite in the background
npm run dev &

# Wait for the dev server to respond
echo "Waiting for Vite dev server..."
npx wait-on http-get://localhost:5173/index.html

# Launch Electron
echo "Starting Electron..."
npm run electron
