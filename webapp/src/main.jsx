import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
// Copy standalone Tailwind compilation asset from old front-end to public/js/ for fallback if needed,
// but since we compile statically via build step, standard Tailwind output will be bundled inside index.css.
