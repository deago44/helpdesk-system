import { useState } from 'react'
import { api } from '../api'
import { useSearchParams } from 'react-router-dom'

export default function ResetPassword() {
  const [sp] = useSearchParams();
  const preset = sp.get('token') || '';
  const [token, setT] = useState(preset);
  const [pw, setPw] = useState('');
  const [msg, setMsg] = useState('');
  const submit = async (e) => {
    e.preventDefault();
    await api('/api/password/reset', {
      method:'POST',
      body: JSON.stringify({ token, password: pw })
    });
    setMsg('Password reset.');
  };
  return (
    <div className="card narrow">
      <h2>Reset Password</h2>
      <form onSubmit={submit}>
        <label>Token</label>
        <input value={token} onChange={e=>setT(e.target.value)} required />
        <label>New Password</label>
        <input type="password" value={pw} onChange={e=>setPw(e.target.value)} required />
        <button type="submit">Reset</button>
      </form>
      {msg && <p>{msg}</p>}
    </div>
  )
}
