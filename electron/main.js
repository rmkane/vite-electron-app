import { app, BrowserWindow } from 'electron'
import path from 'path'
import { fileURLToPath } from 'url'

// Required to support __dirname with ESM
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

// Create the main application window
function createWindow() {
  console.log('Creating Electron window...')

  const isDev = !app.isPackaged

  const win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      // Preload script runs in isolated context, safe for exposing APIs
      preload: path.join(__dirname, 'preload.js'),
    },
  })

  if (isDev) {
    console.log('Running in development mode — loading Vite server...')
    win.loadURL('http://localhost:5173')

    // Automatically open DevTools in development
    win.webContents.openDevTools({ mode: 'detach' })
  } else {
    console.log('Running in production mode — loading built index.html...')
    win.loadFile(path.join(__dirname, '../dist/index.html'))
  }

  // Log when content has finished loading
  win.webContents.on('did-finish-load', () => {
    console.log('Window finished loading.')
  })

  // Log detailed error if loading fails
  win.webContents.on('did-fail-load', (event, code, desc) => {
    console.error(`❌ Failed to load window content [${code}]: ${desc}`)
  })
}

// App lifecycle: create window when ready
app.whenReady().then(() => {
  console.log('Electron app ready.')
  createWindow()

  // On macOS: re-create a window when the dock icon is clicked
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

// Quit app when all windows are closed (except on macOS)
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    console.log('All windows closed — quitting app.')
    app.quit()
  }
})
