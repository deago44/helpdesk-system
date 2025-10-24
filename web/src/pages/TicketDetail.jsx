import { useState, useEffect } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { api } from '../api'
import { useAuth } from '../AuthContext'

export default function TicketDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const [ticket, setTicket] = useState(null)
  const [comments, setComments] = useState([])
  const [newComment, setNewComment] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    loadTicket()
    loadComments()
  }, [id])

  const loadTicket = async () => {
    try {
      const data = await api(`/api/tickets/${id}`)
      setTicket(data)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  const loadComments = async () => {
    try {
      const data = await api(`/api/tickets/${id}/comments`)
      setComments(data)
    } catch (e) {
      // Comments might not be implemented yet
      console.log('Comments not available:', e.message)
    }
  }

  const addComment = async (e) => {
    e.preventDefault()
    if (!newComment.trim()) return

    try {
      await api(`/api/tickets/${id}/comments`, {
        method: 'POST',
        body: JSON.stringify({ content: newComment })
      })
      setNewComment('')
      loadComments()
    } catch (e) {
      setError(e.message)
    }
  }

  const updateTicket = async (updates) => {
    try {
      const data = await api(`/api/tickets/${id}`, {
        method: 'PUT',
        body: JSON.stringify(updates)
      })
      setTicket(data)
    } catch (e) {
      setError(e.message)
    }
  }

  const assignTicket = async (userId) => {
    try {
      await api(`/api/tickets/${id}/assign`, {
        method: 'PUT',
        body: JSON.stringify({ user_id: userId })
      })
      loadTicket()
    } catch (e) {
      setError(e.message)
    }
  }

  const closeTicket = async () => {
    if (window.confirm('Are you sure you want to close this ticket?')) {
      try {
        await api(`/api/tickets/${id}/close`, { method: 'PUT' })
        loadTicket()
      } catch (e) {
        setError(e.message)
      }
    }
  }

  if (loading) return <div>Loading...</div>
  if (error) return <div className="error">{error}</div>
  if (!ticket) return <div>Ticket not found</div>

  const canManage = user && (user.role === 'admin' || user.role === 'tech')
  const isOwner = user && user.id === ticket.user_id

  return (
    <div className="stack">
      <div className="row">
        <Link to="/" className="btn">← Back to Tickets</Link>
        <div className="spacer" />
        {canManage && (
          <div className="row" style={{ gap: 8 }}>
            <button onClick={() => assignTicket(user.id)}>Assign to Me</button>
            {ticket.status !== 'Closed' && (
              <button onClick={closeTicket}>Close Ticket</button>
            )}
          </div>
        )}
      </div>

      <div className="card">
        <div className="row">
          <h1 className="title">{ticket.title}</h1>
          <span className={`pill ${ticket.status === 'Closed' ? 'muted' : ''}`}>
            {ticket.status}
          </span>
        </div>

        <div className="meta">
          <span>Priority: <b>{ticket.priority}</b></span>
          <span>Assigned to: <b>{ticket.assigned_to || 'Unassigned'}</b></span>
          <span>Created: {new Date(ticket.created_at).toLocaleString()}</span>
          <span>Updated: {new Date(ticket.updated_at).toLocaleString()}</span>
        </div>

        <div className="desc">{ticket.description}</div>

        {/* Status and Priority Controls */}
        {(canManage || isOwner) && (
          <div className="row" style={{ marginTop: 16 }}>
            <div className="row">
              <label>Status:</label>
              <select 
                value={ticket.status} 
                onChange={(e) => updateTicket({ status: e.target.value })}
                disabled={!canManage && ticket.status === 'Closed'}
              >
                <option value="Open">Open</option>
                <option value="In Progress">In Progress</option>
                <option value="Closed">Closed</option>
              </select>
            </div>

            <div className="row">
              <label>Priority:</label>
              <select 
                value={ticket.priority} 
                onChange={(e) => updateTicket({ priority: e.target.value })}
              >
                <option value="Low">Low</option>
                <option value="Normal">Normal</option>
                <option value="High">High</option>
              </select>
            </div>
          </div>
        )}

        {/* SLA Badge */}
        <div style={{ marginTop: 16 }}>
          <span className={`pill ${getSLABadge(ticket.created_at, ticket.priority)}`}>
            {getSLAText(ticket.created_at, ticket.priority)}
          </span>
        </div>
      </div>

      {/* Comments Section */}
      <div className="card">
        <h3>Comments</h3>
        
        {comments.map(comment => (
          <div key={comment.id} className="comment">
            <div className="comment-meta">
              <strong>{comment.author}</strong>
              <span>{new Date(comment.created_at).toLocaleString()}</span>
            </div>
            <div className="comment-content">{comment.content}</div>
          </div>
        ))}

        <form onSubmit={addComment} style={{ marginTop: 16 }}>
          <label>Add Comment:</label>
          <textarea 
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
            rows="3"
            placeholder="Add a comment..."
          />
          <button type="submit" disabled={!newComment.trim()}>Add Comment</button>
        </form>
      </div>
    </div>
  )
}

function getSLABadge(createdAt, priority) {
  const hours = (Date.now() - new Date(createdAt)) / (1000 * 60 * 60)
  const priorityHours = { Low: 72, Normal: 24, High: 4, Critical: 1 }
  const threshold = priorityHours[priority] || 24
  
  if (hours > threshold * 1.5) return 'pill-danger'
  if (hours > threshold) return 'pill-warning'
  return 'pill-success'
}

function getSLAText(createdAt, priority) {
  const hours = (Date.now() - new Date(createdAt)) / (1000 * 60 * 60)
  const priorityHours = { Low: 72, Normal: 24, High: 4, Critical: 1 }
  const threshold = priorityHours[priority] || 24
  
  if (hours > threshold * 1.5) return `Overdue (${Math.round(hours)}h)`
  if (hours > threshold) return `At Risk (${Math.round(hours)}h)`
  return `On Time (${Math.round(hours)}h)`
}
