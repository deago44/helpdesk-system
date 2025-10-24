import { useAuth } from '../AuthContext'
import { useState, useEffect } from 'react'

export default function TicketCard({ ticket, onChange }) {
  const { user } = useAuth();
  const [busy, setBusy] = useState(false);
  const [file, setFile] = useState(null);
  const [attachments, setAttachments] = useState([]);
  const canManage = user && (user.role === 'admin' || user.role === 'tech');

  const assignToMe = async () => {
    setBusy(true);
    try {
      const res = await fetch(`/api/tickets/${ticket.id}/assign`, {
        method: 'PUT',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: user.id })
      });
      if (!res.ok) throw new Error('Assign failed');
      onChange();
    } catch (e) { alert(e.message); }
    finally { setBusy(false); }
  };

  const closeTicket = async () => {
    setBusy(true);
    try {
      const res = await fetch(`/api/tickets/${ticket.id}/close`, {
        method: 'PUT',
        credentials: 'include'
      });
      if (!res.ok) throw new Error('Close failed');
      onChange();
    } catch (e) { alert(e.message); }
    finally { setBusy(false); }
  };

  const upload = async () => {
    if (!file) return;
    setBusy(true);
    try {
      const fd = new FormData();
      fd.append('file', file);
      const res = await fetch(`/api/tickets/${ticket.id}/attachments`, {
        method: 'POST',
        credentials: 'include',
        body: fd
      });
      if (!res.ok) throw new Error('Upload failed');
      setFile(null);
      await loadAttachments();
    } catch (e) { alert(e.message); }
    finally { setBusy(false); }
  };

  const loadAttachments = async () => {
    try {
      const res = await fetch(`/api/tickets/${ticket.id}/attachments`, {
        credentials: 'include'
      });
      if (!res.ok) return;
      const data = await res.json();
      setAttachments(data);
    } catch {}
  };

  useEffect(()=>{ loadAttachments(); }, [ticket.id]);

  return (
    <div className="card">
      <div className="row">
        <h3 className="title">{ticket.title}</h3>
        <span className={`pill ${ticket.status === 'Closed' ? 'muted' : ''}`}>{ticket.status}</span>
      </div>
      <p className="desc">{ticket.description}</p>
      <div className="meta">
        <span>Priority: <b>{ticket.priority}</b></span>
        <span>Assigned: <b>{ticket.assigned_to ?? '—'}</b></span>
        <span>Created: {ticket.created_at}</span>
      </div>

      {attachments.length > 0 && (
        <div style={{marginTop:8}}>
          <b>Attachments:</b>
          <ul>
            {attachments.map(a => (
              <li key={a.id}>
                <a href={`/uploads/${a.path}`} target="_blank" rel="noreferrer">{a.filename}</a>
                <span style={{color:'#777', marginLeft:8}}>({a.size} bytes)</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className="row" style={{marginTop:8}}>
        <input type="file" onChange={e=>setFile(e.target.files[0])} />
        <button disabled={busy || !file} onClick={upload}>Upload</button>
      </div>

      {canManage && (
        <div className="row" style={{marginTop:8}}>
          <button disabled={busy} onClick={assignToMe}>Assign to me</button>
          {ticket.status !== 'Closed' && <button disabled={busy} onClick={closeTicket}>Close</button>}
        </div>
      )}
    </div>
  )
}
