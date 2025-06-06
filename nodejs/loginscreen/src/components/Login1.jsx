import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { login as authServiceLogin } from '../services/authService';

const Login1 = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { login: contextLogin, isAuthenticated } = useAuth();

  useEffect(() => {
    console.log('Login1: Component mounted or auth state changed', { isAuthenticated });
    
    return () => {
      console.log('Login1: Component unmounting');
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
    console.log('Login1: Form submitted with:', { username, password });
    setLoading(true);
    setError('');
    
    try {
      console.log('Login1: Calling authService.login...');
      const response = await authServiceLogin(username, password);
      console.log('Login1: API Response:', response);
      
      if (response && response.accessToken) {
        const userData = {
          id: response.id,
          username: response.username || username.split('@')[0],
          email: response.email || username
        };
        
        console.log('Login1: Attempting to login with user data', userData);
        const loginSuccess = await contextLogin({
          user: userData,
          authToken: response.accessToken
        });
        
        console.log('Login1: Login success?', loginSuccess);
        
        if (loginSuccess) {
          const from = window.location.state?.from?.pathname || '/dashboard';
          console.log('Login1: Navigating to', from);
          navigate(from, { replace: true });
        } else {
          throw new Error('Failed to complete login process');
        }
      } else {
        throw new Error('Invalid response from server');
      }
    } catch (error) {
      console.error('Login1 error:', error);
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
