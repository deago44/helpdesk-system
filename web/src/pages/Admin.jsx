import { useEffect, useState } from 'react'
import { useAuth } from '../AuthContext'
import { api } from '../api'

export default function Admin() {
  const { user } = useAuth();
  const [tab, setTab] = useState('users');

  if (!user || user.role !== 'admin') {
    return <div className="card"><h3>Admin only</h3></div>
  }

  return (
    <div className="stack">
      <div className="row">
        <h2>Admin</h2>
        <div className="spacer" />
        <div className="row" style={{gap:8}}>
          <button onClick={()=>setTab('users')}>Users</button>
          <button onClick={()=>setTab('audit')}>Audit</button>
        </div>
      </div>
      {tab === 'users' ? <UsersTab /> : <AuditTab />}
    </div>
  )
}

function UsersTab() {
  const [users, setUsers] = useState([]);
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(true);

  async function load() {
    setErr('');
    setLoading(true);
    try { 
      console.log('Loading users...');
      const userData = await api('/api/users');
      console.log('Users loaded:', userData);
      setUsers(userData); 
    }
    catch(e){ 
      console.error('Error loading users:', e);
      setErr(e.message); 
    }
    finally {
      setLoading(false);
    }
  }
  useEffect(()=>{ load(); }, []);

  const changeRole = async (id, role) => {
    try {
      console.log('Changing role for user', id, 'to', role);
      await api(`/api/users/${id}/role`, { method:'PUT', body: JSON.stringify({ role }) });
      load();
    } catch(e){ 
      console.error('Error changing role:', e);
      alert(e.message); 
    }
  };

  if (loading) {
    return <div className="card"><h3>Users</h3><div>Loading users...</div></div>;
  }

  return (
    <div className="card">
      <h3>Users</h3>
      {err && <div className="error">{err}</div>}
      {users.length === 0 ? (
        <div>No users found. This might be an authentication issue.</div>
      ) : (
        <table style={{width:'100%', borderCollapse:'collapse'}}>
          <thead><tr><th align="left">ID</th><th align="left">Username</th><th align="left">Role</th><th /></tr></thead>
          <tbody>
          {users.map(u=>(
            <tr key={u.id} style={{borderTop:'1px solid #eee'}}>
              <td>{u.id}</td>
              <td>{u.username}</td>
              <td>{u.role}</td>
              <td>
                <select value={u.role} onChange={e=>changeRole(u.id, e.target.value)}>
                  <option>user</option><option>tech</option><option>admin</option>
                </select>
              </td>
            </tr>
          ))}
          </tbody>
        </table>
      )}
    </div>
  )
}

function AuditTab() {
  const [page, setPage] = useState(1);
  const [data, setData] = useState({ items: [], page:1, size:20, total:0 });
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(true);

  async function load(p = page) {
    setErr('');
    setLoading(true);
    try {
      console.log('Loading audit log, page:', p);
      const r = await api(`/api/audit?page=${p}&size=20`);
      console.log('Audit data loaded:', r);
      setData(r);
    } catch(e){ 
      console.error('Error loading audit log:', e);
      setErr(e.message); 
    }
    finally {
      setLoading(false);
    }
  }
  useEffect(()=>{ load(page); }, [page]);

  const totalPages = Math.max(1, Math.ceil((data.total || 0) / (data.size || 20)));

  if (loading) {
    return <div className="card"><h3>Audit Log</h3><div>Loading audit log...</div></div>;
  }

  return (
    <div className="card">
      <h3>Audit Log</h3>
      {err && <div className="error">{err}</div>}
      {data.items.length === 0 ? (
        <div>No audit log entries found. This might be an authentication issue.</div>
      ) : (
        <>
          <table style={{width:'100%', borderCollapse:'collapse'}}>
            <thead><tr><th align="left">Time</th><th align="left">Actor</th><th align="left">Action</th><th align="left">Entity</th><th align="left">ID</th><th align="left">Details</th></tr></thead>
            <tbody>
              {data.items.map(i=>(
                <tr key={i.id} style={{borderTop:'1px solid #eee'}}>
                  <td>{i.ts}</td>
                  <td>{i.actor_id}</td>
                  <td>{i.action}</td>
                  <td>{i.entity}</td>
                  <td>{i.entity_id}</td>
                  <td>{i.details}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="row" style={{justifyContent:'center', gap:8, marginTop:12}}>
            <button disabled={page<=1} onClick={()=>setPage(p=>p-1)}>Prev</button>
            <span>Page {page} / {totalPages}</span>
            <button disabled={page>=totalPages} onClick={()=>setPage(p=>p+1)}>Next</button>
          </div>
        </>
      )}
    </div>
  )
}
