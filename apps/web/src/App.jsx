import { useState } from 'react'
import './App.css'

const API_URL = import.meta.env.VITE_API_URL || '';

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [user, setUser] = useState(null);
  const [workouts, setWorkouts] = useState([]);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [status, setStatus] = useState('');

  // 1. Auth Service Interactionn
  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch(`${API_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });
      const data = await res.json();
      if (res.ok) {
        setToken(data.access);
        localStorage.setItem('token', data.access);
        setStatus('Login Success');
      } else {
        // Handle both "detail" errors and validation errors (e.g. { email: [...] })
        setStatus(`Login Failed: ${JSON.stringify(data)}`);
      }
    } catch (err) {
      setStatus(`Network Error: ${err.message}`);
    }
  };

  // 2. User Profile Service (Group: Access)
  const fetchProfile = async () => {
    try {
      const res = await fetch(`${API_URL}/api/users/me`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      setUser(data);
    } catch (err) {
      console.error(err);
    }
  };

  // 3. Workout Query Service (Group: Core)
  const fetchWorkouts = async () => {
    try {
      const res = await fetch(`${API_URL}/api/workouts/query/history`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      setWorkouts(data);
    } catch (err) {
      console.error(err);
    }
  };

  // 4. Analytics Service (Group: Heavy)
  const [stats, setStats] = useState(null);
  const fetchStats = async () => {
      try {
        const res = await fetch(`${API_URL}/api/analytics/summary`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        setStats(data);
      } catch (err) { console.error(err); }
  }

  return (
    <div className="container">
      <h1>Gym Tracker Distributed System</h1>
      
      {!token ? (
        <div className="card">
          <h2>Login (Auth Service)</h2>
          <form onSubmit={handleLogin}>
            <input 
              placeholder="Email" 
              value={email} 
              onChange={e => setEmail(e.target.value)} 
            />
            <input 
              type="password" 
              placeholder="Password" 
              value={password} 
              onChange={e => setPassword(e.target.value)} 
            />
            <button type="submit">Login</button>
          </form>
          <p>{status}</p>
        </div>
      ) : (
        <div className="dashboard">
          <div className="card">
            <h2>User Profile</h2>
            <button onClick={fetchProfile}>Load Profile</button>
            {user && <pre>{JSON.stringify(user, null, 2)}</pre>}
          </div>

          <div className="card">
            <h2>Workouts</h2>
            <button onClick={fetchWorkouts}>Load Workouts</button>
            {workouts.length > 0 ? (
              <ul>{workouts.map(w => <li key={w.id}>{w.name}</li>)}</ul>
            ) : <p>No workouts found</p>}
          </div>
          
          <div className="card">
            <h2>Analytics</h2>
            <button onClick={fetchStats}>Load Stats</button>
            {stats && <pre>{JSON.stringify(stats, null, 2)}</pre>}
          </div>
          
          <button onClick={() => {
              setToken(null); 
              localStorage.removeItem('token');
          }}>Logout</button>
        </div>
      )}
    </div>
  )
}

export default App
