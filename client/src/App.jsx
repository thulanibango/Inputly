import React, { useState } from 'react'

export default function App() {
  const [out, setOut] = useState('No request yet.')
  const [ok, setOk] = useState(false)

  const callApi = async () => {
    setOut('Loading...')
    setOk(false)
    try {
      const res = await fetch('/api', { headers: { 'User-Agent': 'browser' }})
      const text = await res.text()
      setOut(text)
      setOk(res.ok)
    } catch (e) {
      setOut('Error: ' + e.message)
    }
  }

  return (
    <div className="container">
      <h1>Inputly Frontend</h1>
      <p className="muted">React (Vite) served by Nginx in Kubernetes</p>
      <div className="card">
        <h2>API Health Check</h2>
        <p>Click to fetch from <code>/api</code> in the cluster.</p>
        <button onClick={callApi}>Fetch /api</button>
        <pre className={ok ? 'ok' : 'muted'}>{out}</pre>
      </div>
      <div className="card">
        <h2>Endpoints</h2>
        <ul>
          <li><code>/</code> — this frontend</li>
          <li><code>/api</code> — API JSON</li>
          <li><code>/health</code> — API health</li>
        </ul>
      </div>
    </div>
  )
}
