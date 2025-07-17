# Vite Electron App

A React app written in TypeScript, compiled using Vite, and distributed as an Electron app.

This project combines [Vite](https://vitejs.dev/) for fast frontend development and [Electron](https://www.electronjs.org/) for packaging as a cross-platform desktop app. It uses React + TypeScript for the UI and builds into a distributable AppImage for Linux.

## Getting started

```sh
npm run dist                                   # Build the app
chmod u+x dist/ViteElectronApp-0.1.0.AppImage  # Make it executable
./dist/ViteElectronApp-0.1.0.AppImage          # Run the image
```

## Project setup

This app was created by running the following:

```sh
npm create vite@latest vite-electron-app -- --template react-ts
cd vite-electron-app
```

## Node version compatibility

> **Note**: Vite 4+ requires Node 18 or newer.  
> This project uses **Node 16**, so Vite is pinned to the latest compatible 3.x version.

```json
{
  "@vitejs/plugin-react": "^2.2.0",
  "vite": "^3.2.11"
}
```

## Electron support

To enable Electron and package the app:

```sh
npm install -D electron electron-builder
```

## Scripts

The following scripts are used for development and packaging:

```json
{
  "scripts": {
    // Starts the Vite dev server
    "dev": "vite",
    // Compiles TypeScript and builds frontend
    "build": "tsc -b && vite build",
    // Runs Electron using the current project
    "electron": "electron .",
    // Start dev server and Electron together forl live reloading
    "start": "./scripts/start-dev.sh",
    // Build the Electron distribution
    "dist": "npm run build && electron-builder"
  }
}
```

The [`scripts/start-dev.sh`](scripts/start-dev.sh) script starts up the Vite dev server and an Electron instance.

## Electron files

The Electron app consists of two core files:

- [`electron/main.js`](electron/main.js) — Creates windows and manages the app lifecycle.
- [`electron/preload.js`](electron/preload.js) — Securely exposes APIs to the renderer via `contextBridge`.

## Vite configuration

Since Electron loads files with the `file://` protocol, Vite must use relative asset paths.  
This is set in [`vite.config.ts`](vite.config.ts):

```ts
export default defineConfig({
  base: './',
  plugins: [react()],
})
```

This ensures that references to `assets/index.[hash].css` and `index.[hash].js` resolve correctly in production.

## Electron builder configuration

In `package.json`, the following `build` section configures Electron Builder for cross-platform packaging and custom icons:

```json
{
  "type": "module",
  "main": "electron/main.js",
  "build": {
    "appId": "com.example.viteapp",
    "productName": "ViteElectronApp",
    "files": ["dist/**/*", "electron/**/*", "package.json"],
    "directories": {
      "buildResources": "assets"
    },
    "win": {
      "target": "nsis",
      "icon": "assets/icon.ico"
    },
    "linux": {
      "target": "AppImage",
      "icon": "assets/icon.png",
      "category": "Utility"
    }
  }
}
```

> The `icon` paths should point to valid platform-specific formats:  
> `.ico` for Windows, `.png` for Linux, and optionally `.icns` for macOS.

## Troubleshooting

- **White screen in production?**  
  Ensure `vite.config.ts` includes `base: './'`, and that the `dist/` folder is correctly included in the build.

- **Electron doesn’t launch during development?**  
  Double-check that the `start` script uses `wait-on http-get://... --` instead of a chained `&&`, and that the Vite server starts successfully.

- **AppImage shows a blank screen but DevTools says "Preload loaded"?**  
  This often means `index.html` is found, but Vite’s `index.[hash].js` or CSS wasn’t included.  
  Check that `dist/**/*` is in the `build.files` list, and inspect with `--appimage-extract`.

## License

MIT
