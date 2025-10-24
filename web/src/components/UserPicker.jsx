import { useState, useEffect } from 'react'
import { api } from '../api'

export default function UserPicker({ value, onChange, placeholder = "Select user..." }) {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    loadUsers()
  }, [])

  const loadUsers = async () => {
    try {
      const data = await api('/api/users')
      setUsers(data)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  if (loading) return <select disabled><option>Loading users...</option></select>
  if (error) return <select disabled><option>Error loading users</option></select>

  return (
    <select 
      className="user-picker"
      value={value || ''} 
      onChange={(e) => onChange(e.target.value)}
    >
      <option value="">{placeholder}</option>
      {users.map(user => (
        <option key={user.id} value={user.id}>
          {user.username} ({user.role})
        </option>
      ))}
    </select>
  )
}
