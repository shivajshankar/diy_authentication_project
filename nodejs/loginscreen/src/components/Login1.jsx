import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { login as authServiceLogin } from '../services/authService';

// Debug log for environment variables
console.log('Login1 - Environment Variables:', {
  NODE_ENV: process.env.NODE_ENV,
  REACT_APP_API_URL: process.env.REACT_APP_API_URL,
  REACT_APP_GOOGLE_AUTH_URL: process.env.REACT_APP_GOOGLE_AUTH_URL,
  REACT_APP_ENV: process.env.REACT_APP_ENV
});

const Login1 = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { login: contextLogin, isAuthenticated } = useAuth();

  // Debug log for component mount and auth state
  useEffect(() => {
    console.log('=== LOGIN COMPONENT DEBUG ===');
    console.log('Component mounted. isAuthenticated:', isAuthenticated);
    console.log('Environment variables:', {
      NODE_ENV: process.env.NODE_ENV,
      REACT_APP_API_URL: process.env.REACT_APP_API_URL,
      REACT_APP_GOOGLE_AUTH_URL: process.env.REACT_APP_GOOGLE_AUTH_URL,
      REACT_APP_ENV: process.env.REACT_APP_ENV
    });
    console.log('============================');
    
    return () => {
      console.log('Login component unmounting');
    };
  }, [isAuthenticated]);

  useEffect(() => {
    const form = document.querySelector('form');
    console.log('Login1: Form element found?', !!form);
    
    if (form) {
      const handleSubmit = (e) => {
        console.log('Form submit event captured directly');
      };
      form.addEventListener('submit', handleSubmit);
      return () => form.removeEventListener('submit', handleSubmit);
    }
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    console.log('Login form submitted with:', { username });
    setLoading(true);
    setError('');
    
    try {
      console.log('Calling authService.login...');
      const response = await authServiceLogin(username, password);
      console.log('Login response:', response);
      
      if (response && response.accessToken) {
        const userData = {
          id: response.id,
          username: response.username || username.split('@')[0],
          email: response.email || username
        };
        
        console.log('Attempting to update auth context with user data:', userData);
        const loginSuccess = await contextLogin({
          user: userData,
          authToken: response.accessToken
        });
        
        console.log('Login success?', loginSuccess);
        
        if (loginSuccess) {
          const from = window.location.state?.from?.pathname || '/dashboard';
          console.log('Login successful, navigating to:', from);
          navigate(from, { replace: true });
        } else {
          const errorMsg = 'Failed to complete login process';
          console.error(errorMsg);
          setError(errorMsg);
        }
      } else {
        const errorMsg = 'Invalid response from server';
        console.error(errorMsg, response);
        setError(errorMsg);
      }
    } catch (error) {
      console.error('Login error:', error);
      setError(error.message || 'Login failed. Please check your credentials and try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container mt-5">
      <div className="row justify-content-center">
        <div className="col-md-6 col-lg-4">
          <div className="card shadow">
            <div className="card-body p-4">
              <h2 className="text-center mb-4">Sign in to your account</h2>
              
              {error && (
                <div className="alert alert-danger" role="alert">
                  {error}
                </div>
              )}
              
              <form onSubmit={handleSubmit}>
                <div className="mb-3">
                  <label htmlFor="username" className="form-label">
                    Username or Email
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="username"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    required
                    disabled={loading}
                  />
                </div>
                
                <div className="mb-3">
                  <label htmlFor="password" className="form-label">
                    Password
                  </label>
                  <input
                    type="password"
                    className="form-control"
                    id="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    disabled={loading}
                  />
                </div>
                
                <div className="d-grid gap-2">
                  <button 
                    type="submit" 
                    className="btn btn-primary"
                    disabled={loading}
                  >
                    {loading ? 'Signing in...' : 'Sign in'}
                  </button>
                </div>
              </form>
              
              <div className="text-center mt-3">
                <p className="mb-0">
                  Don't have an account?{' '}
                  <Link to="/register" className="text-decoration-none">
                    Sign up
                  </Link>
                </p>
                <p className="mt-2 mb-0">
                  <Link to="/login/sso" className="text-decoration-none">
                    Sign in with SSO
                  </Link>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login1;
