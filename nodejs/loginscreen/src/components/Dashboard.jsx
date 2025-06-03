import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { getCurrentUser, logout as authLogout, getStoredUser } from '../services/authService';
import './Dashboard.css';

function Dashboard() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  // Memoized function to load user data
  const loadUser = useCallback(async () => {
    const token = localStorage.getItem('authToken');
    if (!token) {
      navigate('/');
      return null;
    }

    try {
      // Use stored user for immediate UI update
      const storedUser = getStoredUser();
      if (storedUser) {
        setUser(storedUser);
      }

      // Fetch fresh data
      const userData = await getCurrentUser();
      return userData;
    } catch (err) {
      console.error('Error loading user:', err);
      throw err;
    }
  }, [navigate]);

  useEffect(() => {
    let isMounted = true;

    const init = async () => {
      try {
        const userData = await loadUser();
        if (isMounted && userData) {
          setUser(userData);
        }
      } catch (err) {
        console.error('Error in init:', err);
        setError('Failed to load user data. Redirecting to login...');
        setTimeout(() => {
          authLogout();
        }, 1500);
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    };

    init();

    return () => {
      isMounted = false;
    };
  }, [loadUser]);

  const handleLogout = () => {
    authLogout();
  };

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh' }}>
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="container mt-5">
      <div className="row justify-content-center">
        <div className="col-md-8">
          <div className="card shadow">
            <div className="card-header d-flex justify-content-between align-items-center">
              <h2 className="mb-0">Dashboard</h2>
              <button 
                onClick={handleLogout}
                className="btn btn-outline-danger"
              >
                Logout
              </button>
            </div>
            <div className="card-body">
              {error && (
                <div className="alert alert-warning" role="alert">
                  {error}
                </div>
              )}
              
              {user ? (
                <div className="fade-in">
                  <h3>Welcome, {user.username || 'User'}!</h3>
                  <div className="mt-4">
                    <h4>Your Profile</h4>
                    <table className="table table-bordered">
                      <tbody>
                        <tr>
                          <th scope="row" style={{ width: '30%' }}>User ID</th>
                          <td>{user.id}</td>
                        </tr>
                        <tr>
                          <th scope="row">Username</th>
                          <td>{user.username}</td>
                        </tr>
                        <tr>
                          <th scope="row">Email</th>
                          <td>{user.email || 'N/A'}</td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              ) : (
                <div className="alert alert-warning">
                  No user data available. Redirecting to login...
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default React.memo(Dashboard);