import { createContext, useContext, useEffect, useState } from 'react';
import { api } from './api';

const AuthCtx = createContext(null);
export const useAuth = () => useContext(AuthCtx);

export default function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const r = await api('/api/me', { method: 'GET' });
        if (r?.user) setUser(r.user);
      } catch {}
      setReady(true);
    })();
  }, []);

  const login = async (username, password) => {
    const data = await api('/api/login', {
      method: 'POST',
      body: JSON.stringify({ username, password })
    });
    setUser(data.user);
    return data.user;
  };

  const logout = async () => {
    await api('/api/logout', { method: 'POST' });
    setUser(null);
  };

  const value = { user, setUser, login, logout, ready };
  return <AuthCtx.Provider value={value}>{children}</AuthCtx.Provider>;
}
