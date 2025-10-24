import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import TicketCard from '../components/TicketCard'
import { api } from '../api'
import { useAuth } from '../AuthContext'

export default function Tickets() {
  const { user } = useAuth();
  const [sp, setSp] = useSearchParams();
  const [data, setData] = useState({ items: [], page: 1, size: 12, total: 0 });
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState('all'); // 'all', 'open', 'closed'
  const priority = sp.get('priority') || 'All';
  const page = parseInt(sp.get('page') || '1', 10);

  async function load() {
    setLoading(true);
    const qs = new URLSearchParams();
    
    // Load all tickets regardless of status for sectioned view
    if (viewMode === 'all') {
      // Don't filter by status - we'll group them in the UI
    } else if (viewMode === 'open') {
      qs.set('status', 'Open');
    } else if (viewMode === 'closed') {
      qs.set('status', 'Closed');
    }
    
    if (priority !== 'All') qs.set('priority', priority);
    qs.set('page', String(page));
    qs.set('size', '50'); // Load more tickets for sectioned view
    const res = await api(`/api/tickets?${qs.toString()}`, { method: 'GET' });
    setData(res);
    setLoading(false);
  }
  useEffect(() => { load(); }, [viewMode, priority, page]);

  const setFilter = (k,v) => {
    const next = new URLSearchParams(sp);
    if (v === 'All') next.delete(k); else next.set(k, v);
    next.set('page','1');
    setSp(next);
  };
  const setPage = (p) => {
    const next = new URLSearchParams(sp);
    next.set('page', String(p));
    setSp(next);
  };

  // Group tickets by status
  const groupedTickets = data.items.reduce((acc, ticket) => {
    const status = ticket.status;
    if (!acc[status]) acc[status] = [];
    acc[status].push(ticket);
    return acc;
  }, {});

  const totalPages = Math.max(1, Math.ceil((data.total || 0) / (data.size || 12)));

  return (
    <div className="stack">
      <div className="row">
        <h2>Tickets</h2>
        <div className="spacer" />
        {user?.role === 'user' && <Link className="btn" to="/new">+ New Ticket</Link>}
      </div>

      <div className="filters">
        <div className="view-mode-selector">
          <button 
            className={viewMode === 'all' ? 'btn active' : 'btn'} 
            onClick={() => setViewMode('all')}
          >
            All Tickets
          </button>
          <button 
            className={viewMode === 'open' ? 'btn active' : 'btn'} 
            onClick={() => setViewMode('open')}
          >
            Open Only
          </button>
          <button 
            className={viewMode === 'closed' ? 'btn active' : 'btn'} 
            onClick={() => setViewMode('closed')}
          >
            Closed Only
          </button>
        </div>
        <select value={priority} onChange={e=>setFilter('priority', e.target.value)}>
          <option>All</option><option>Low</option><option>Normal</option><option>High</option>
        </select>
        <button className="btn" onClick={load}>Refresh</button>
      </div>

      {loading ? <div>Loading…</div> : (
        data.items.length ? (
          <>
            {viewMode === 'all' ? (
              // Sectioned view - show tickets grouped by status
              <div className="ticket-sections">
                {Object.entries(groupedTickets).map(([status, tickets]) => (
                  <div key={status} className="ticket-section">
                    <div className="section-header">
                      <h3 className="section-title">
                        {status === 'Open' ? '🟢 Open Tickets' : 
                         status === 'Closed' ? '🔴 Closed Tickets' : 
                         `📋 ${status} Tickets`}
                        <span className="ticket-count">({tickets.length})</span>
                      </h3>
                    </div>
                    <div className="grid">
                      {tickets.map(t => <TicketCard key={t.id} ticket={t} onChange={load} />)}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              // Single status view
              <div className="grid">
                {data.items.map(t => <TicketCard key={t.id} ticket={t} onChange={load} />)}
              </div>
            )}
            
            {viewMode !== 'all' && (
              <div className="row" style={{justifyContent:'center', gap:8}}>
                <button disabled={page<=1} onClick={()=>setPage(page-1)}>Prev</button>
                <span>Page {page} / {totalPages}</span>
                <button disabled={page>=totalPages} onClick={()=>setPage(page+1)}>Next</button>
              </div>
            )}
          </>
        ) : <div>No tickets found.</div>
      )}
    </div>
  )
}
