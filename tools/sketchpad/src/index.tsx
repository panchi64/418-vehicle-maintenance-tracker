import { render } from 'solid-js/web'
import { App } from './App'
import { applyTheme, defaultTheme } from './theme/themes'

// Apply before first paint so the frame never flashes unthemed.
applyTheme(defaultTheme)

const root = document.getElementById('root')
if (!root) throw new Error('#root missing from index.html')

render(() => <App />, root)
