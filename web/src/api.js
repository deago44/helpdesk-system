const API_BASE = import.meta.env.VITE_API_BASE || '';

export async function api(path, opts = {}) {
  const res = await fetch(
    path.startsWith('http') ? path : `${API_BASE}${path}`,
    {
      credentials: 'include',
      headers: { 'Content-Type': 'application/json', ...(opts.headers || {}) },
      ...opts,
    }
  );
  if (!res.ok) {
    let msg = 'Request failed';
    try { const data = await res.json(); msg = data.error || msg; } catch {}
    throw new Error(msg);
  }
  try { return await res.json(); } catch { return null; }
}
