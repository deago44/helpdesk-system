import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { api } from '../api'

export default function NewTicket() {
  const nav = useNavigate();
  const [title, setTitle] = useState('');
  const [description, setDesc] = useState('');
  const [priority, setPriority] = useState('Normal');
  const [err, setErr] = useState('');

  const submit = async (e) => {
    e.preventDefault();
    setErr('');
    try {
      await api('/api/tickets', {
        method: 'POST',
        body: JSON.stringify({ title, description, priority })
      });
      nav('/');
    } catch (e) {
      setErr(e.message);
    }
  };

  return (
    <div className="card narrow">
      <h2>New Ticket</h2>
      {err && <div className="error">{err}</div>}
      <form onSubmit={submit}>
        <label>Title</label>
        <input value={title} onChange={e=>setTitle(e.target.value)} required />
        <label>Description</label>
        <textarea rows="6" value={description} onChange={e=>setDesc(e.target.value)} required />
        <label>Priority</label>
        <select value={priority} onChange={e=>setPriority(e.target.value)}>
          <option>Low</option><option>Normal</option><option>High</option>
        </select>
        <button type="submit">Create</button>
      </form>
    </div>
  )
}
