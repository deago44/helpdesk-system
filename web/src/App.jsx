import { Routes, Route, Link, Navigate } from 'react-router-dom'
import { useAuth } from './AuthContext'
import Login from './pages/Login'
import Tickets from './pages/Tickets'
import NewTicket from './pages/NewTicket'
import RequestReset from './pages/RequestReset'
import ResetPassword from './pages/ResetPassword'
import Admin from './pages/Admin'
import { useState } from 'react'
import Toast from './Toast'

function Protected({ children }) {
  const { user, ready } = useAuth();
  if (!ready) return null;
  if (!user) return <Navigate to="/login" replace />;
  return children;
}

export default function App() {
  const { user, logout } = useAuth();
  const [toast, setToast] = useState('');
  return (
    <div className="container">
      <nav className="topbar">
        <div className="brand">Helpdesk</div>
        <div className="spacer" />
        {user && (user.role === 'admin' || user.role === 'tech') && (
          <Link to="/admin" className="btn" style={{marginRight:8}}>Admin</Link>
        )}
        {user ? (
          <div className="userbox">
            <span>{user.username} ({user.role})</span>
            <button onClick={logout}>Logout</button>
          </div>
        ) : (
          <Link to="/login" className="btn">Login</Link>
        )}
      </nav>

      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<Protected><Tickets /></Protected>} />
        <Route path="/new" element={<Protected><NewTicket /></Protected>} />
        <Route path="/forgot" element={<RequestReset />} />
        <Route path="/reset" element={<ResetPassword />} />
        <Route path="/admin" element={<Protected><Admin /></Protected>} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
      <Toast msg={toast} onDone={()=>setToast('')} />
    </div>
  )
}
