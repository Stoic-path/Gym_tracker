import { useState, useEffect } from 'react'
import './App.css'

const API_URL = import.meta.env.VITE_API_URL || '';

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [user, setUser] = useState(null);
  const [workouts, setWorkouts] = useState([]);
  const [stats, setStats] = useState(null);
  
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [status, setStatus] = useState('');

  // Auto-fetch data if logged in
  useEffect(() => {
    if (token) {
      fetchProfile();
      fetchWorkouts();
      fetchStats();
    }
  }, [token]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setStatus('Logging in...');
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
        setStatus('');
      } else {
        setStatus(`Error: ${data.detail || 'Login failed'}`);
      }
    } catch (err) {
      setStatus(`Network Error: ${err.message}`);
    }
  };

  const fetchProfile = async () => {
    try {
      const res = await fetch(`${API_URL}/api/users/me`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      if(res.ok) setUser(await res.json());
    } catch (err) { console.error(err); }
  };

  const fetchWorkouts = async () => {
    try {
      const res = await fetch(`${API_URL}/api/workouts/query/history`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      if(res.ok) setWorkouts(await res.json());
    } catch (err) { console.error(err); }
  };

  const fetchStats = async () => {
      try {
        const res = await fetch(`${API_URL}/api/analytics/summary`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        if(res.ok) setStats(await res.json());
      } catch (err) { console.error(err); }
  }

  const handleLogout = () => {
      setToken(null);
      localStorage.removeItem('token');
      setUser(null);
      setWorkouts([]);
      setStats(null);
  };

  return (
    <div className="container">
      <h1>Gym Tracker Pro</h1>
      
      {!token ? (
        <div className="login-card">
          <h2>Welcome Back</h2>
          <form onSubmit={handleLogin} style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
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
            <button type="submit">Sign In</button>
          </form>
          {status && <p style={{color: '#ff6b6b'}}>{status}</p>}
        </div>
      ) : (
        <>
          <div className="dashboard">
            {/* User Profile Card */}
            <div className="card">
              <h2>My Profile</h2>
              {user ? (
                <div>
                    <div className="data-row"><span>Username:</span> <strong>{user.username}</strong></div>
                    <div className="data-row"><span>Email:</span> <strong>{user.email}</strong></div>
                    <div className="data-row"><span>Bio:</span> <strong>{user.bio || 'No bio'}</strong></div>
                    <div style={{marginTop: '1rem', padding: '0.5rem', background: '#333', borderRadius: '4px', fontSize: '0.8rem'}}>
                        Source: {user.source}
                    </div>
                </div>
              ) : <p>Loading profile...</p>}
            </div>

            {/* Analytics Card */}
            <div className="card">
              <h2>Performance Analytics</h2>
              {stats ? (
                  <div className="stat-grid">
                      <div className="stat-item">
                          <div className="stat-value">{stats.total_workouts}</div>
                          <div>Workouts</div>
                      </div>
                      <div className="stat-item">
                          <div className="stat-value">{stats.calories_burned}</div>
                          <div>Calories</div>
                      </div>
                      <div className="stat-item" style={{gridColumn: '1 / -1'}}>
                         <div>Fav Muscle: <strong>{stats.favorite_muscle}</strong></div>
                      </div>
                  </div>
              ) : <p>Loading stats...</p>}
            </div>

            {/* Workouts Card */}
            <div className="card" style={{gridColumn: '1 / -1'}}>
              <h2>Recent Workouts</h2>
              {workouts.length > 0 ? (
                <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: '1rem'}}>
                    {workouts.map(w => (
                        <div key={w.id} className="workout-item">
                            <h3>{w.name}</h3>
                            <p style={{color: '#aaa', fontSize: '0.9rem'}}>Date: {new Date(w.date).toLocaleDateString()}</p>
                            <p>{w.exercises ? `${w.exercises.length} Exercises` : 'No exercises'}</p>
                        </div>
                    ))}
                </div>
              ) : <p>No workouts found.</p>}
            </div>
          </div>
          
          <button className="logout-btn" onClick={handleLogout}>Logout</button>
        </>
      )}
    </div>
  )
}

export default App
