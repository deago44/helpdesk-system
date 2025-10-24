import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useAuth } from '../AuthContext'

export default function Login() {
  const nav = useNavigate();
  const { login } = useAuth();
  const [username, setU] = useState('');
  const [password, setP] = useState('');
  const [err, setErr] = useState('');
  const [isRegistering, setIsRegistering] = useState(false);
  const [success, setSuccess] = useState('');

  const submit = async (e) => {
    e.preventDefault();
    setErr('');
    setSuccess('');
    try {
      await login(username, password);
      nav('/');
    } catch (e) {
      setErr(e.message || 'Login failed');
    }
  };

  const register = async (e) => {
    e.preventDefault();
    setErr('');
    setSuccess('');
    try {
      const response = await fetch('/api/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });
      const data = await response.json();
      if (data.ok) {
        setSuccess('Account created successfully! You can now login.');
        setIsRegistering(false);
        setUsername('');
        setPassword('');
      } else {
        setErr(data.error || 'Registration failed');
      }
    } catch (e) {
      setErr('Registration failed. Please try again.');
    }
  };

  return (
    <div className="card narrow">
      <h2>{isRegistering ? 'Create Account' : 'Login'}</h2>
      {err && <div className="error">{err}</div>}
      {success && <div className="success">{success}</div>}
      <form onSubmit={isRegistering ? register : submit}>
        <label>Username</label>
        <input value={username} onChange={e=>setU(e.target.value)} required />
        <label>Password</label>
        <input type="password" value={password} onChange={e=>setP(e.target.value)} required />
        <button type="submit">{isRegistering ? 'Create Account' : 'Sign in'}</button>
      </form>
      <div style={{ marginTop: '1rem', textAlign: 'center' }}>
        {isRegistering ? (
          <p>
            Already have an account?{' '}
            <button type="button" onClick={() => setIsRegistering(false)} style={{ background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', textDecoration: 'underline' }}>
              Login here
            </button>
          </p>
        ) : (
          <p>
            Don't have an account?{' '}
            <button type="button" onClick={() => setIsRegistering(true)} style={{ background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', textDecoration: 'underline' }}>
              Create one here
            </button>
          </p>
        )}
        <p><Link to="/forgot">Forgot password?</Link></p>
      </div>
    </div>
  )
}
