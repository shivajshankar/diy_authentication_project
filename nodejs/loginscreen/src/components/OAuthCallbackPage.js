import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { handleOAuthCallback } from '../services/authService';
import { Spinner, Alert } from 'react-bootstrap';

const OAuthCallbackPage = () => {
  const [error, setError] = useState(null);
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();

  useEffect(() => {
    const processOAuthCallback = async () => {
      try {
        const token = searchParams.get('token');
        if (token) {
          // If token is in URL (direct from backend)
          localStorage.setItem('authToken', token);
          // Redirect to home or dashboard
          navigate('/dashboard');
        } else {
          // If using session-based auth
          await handleOAuthCallback();
          navigate('/dashboard');
        }
      } catch (err) {
        console.error('OAuth callback error:', err);
        setError('Failed to log in with Google. Please try again.');
      }
    };

    processOAuthCallback();
  }, [navigate, searchParams]);

  return (
    <div className="d-flex justify-content-center align-items-center" style={{ minHeight: '80vh' }}>
      <div className="text-center">
        {error ? (
          <Alert variant="danger">{error}</Alert>
        ) : (
          <>
            <Spinner animation="border" role="status" className="mb-3">
              <span className="visually-hidden">Loading...</span>
            </Spinner>
            <p>Completing login...</p>
          </>
        )}
      </div>
    </div>
  );
};

export default OAuthCallbackPage;
