import React, { useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { handleOAuthCallback } from '../services/authService';

const OAuth2RedirectHandler = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { login } = useAuth();

  useEffect(() => {
    const processOAuthCallback = async () => {
      try {
        const response = await handleOAuthCallback();
        
        if (response && response.token && response.user) {
          login(response.user, response.token);
          navigate('/dashboard');
        } else {
          navigate('/login1', { state: { error: 'Authentication failed. Please try again.' } });
        }
      } catch (error) {
        console.error('OAuth2 callback error:', error);
        navigate('/login1', { 
          state: { 
            error: error.response?.data?.message || 'Authentication failed. Please try again.' 
          } 
        });
      }
    };

    processOAuthCallback();
  }, [location, navigate, login]);

  return (
    <div className="d-flex justify-content-center align-items-center vh-100">
      <div className="spinner-border text-primary" role="status">
        <span className="visually-hidden">Loading...</span>
      </div>
      <span className="ms-3">Completing authentication...</span>
    </div>
  );
};

export default OAuth2RedirectHandler;
