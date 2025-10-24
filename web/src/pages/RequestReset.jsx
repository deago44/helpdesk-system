import { useState } from 'react'
import { api } from '../api'

export default function RequestReset() {
  const [username, setU] = useState('');
  const [msg, setMsg] = useState('');
  const submit = async (e) => {
    e.preventDefault();
    const r = await api('/api/password/request', {
      method:'POST',
      body: JSON.stringify({ username })
    });
    setMsg('If the user exists, a token has been generated (dev mode: check response).');
    if (r?.token) console.log('DEV TOKEN:', r.token);
  };
  return (
    <div className="card narrow">
      <h2>Request Password Reset</h2>
      <form onSubmit={submit}>
        <label>Username</label>
        <input value={username} onChange={e=>setU(e.target.value)} required />
        <button type="submit">Request</button>
      </form>
      {msg && <p>{msg}</p>}
    </div>
  )
}
