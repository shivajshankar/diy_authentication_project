import React, { useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import GoogleLoginButton from './GoogleLoginButton';
import { useAuth } from '../context/AuthContext';

const LoginSSO = ({ onLoginSuccess }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const { login, isAuthenticated } = useAuth();
  const from = location.state?.from?.pathname || '/dashboard';

  console.log('LoginSSO: Rendering', { isAuthenticated, from });

  // Handle successful OAuth login
  useEffect(() => {
    console.log('LoginSSO: Checking for token in URL');
    const urlParams = new URLSearchParams(window.location.search);
    const token = urlParams.get('token');
    
    if (token) {
      console.log('LoginSSO: Found token in URL');
      const completeOAuthLogin = async () => {
        try {
          // Store the token
          localStorage.setItem('authToken', token);
          
          // Get user info
          const response = await fetch('/api/auth/me', {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          });
          
          if (response.ok) {
            const userData = await response.json();
            console.log('LoginSSO: User data fetched', userData);
            
            // Update auth context
            await login({ 
              user: userData, 
              authToken: token 
            });
            
            // Call the success handler
            if (onLoginSuccess) {
              onLoginSuccess();
            }
            
            // Get the redirect URL from session storage or use the default
            const redirectUrl = sessionStorage.getItem('redirectAfterLogin') || from;
            sessionStorage.removeItem('redirectAfterLogin');
            
            // Clear the token from URL
            window.history.replaceState({}, document.title, window.location.pathname);
            
            console.log('LoginSSO: Redirecting to', redirectUrl);
            navigate(redirectUrl, { replace: true });
          } else {
            throw new Error('Failed to fetch user data');
          }
        } catch (error) {
          console.error('OAuth login error:', error);
          // Redirect to login page on error
          navigate('/login1', { 
            state: { 
              error: 'Failed to complete login. Please try again.' 
            },
            replace: true 
          });
        }
      };
      
      completeOAuthLogin();
    }
  }, [navigate, login, onLoginSuccess, from]);

  // Redirect if already authenticated and not in the middle of OAuth flow
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const token = urlParams.get('token');
    
    if (isAuthenticated && !token) {
      console.log('LoginSSO: Already authenticated, redirecting to', from);
      navigate(from, { replace: true });
    }
  }, [isAuthenticated, navigate, from]);

  return (
    <div className="container mt-5">
      <div className="row justify-content-center">
        <div className="col-md-6 col-lg-4">
          <div className="card shadow">
            <div className="card-body p-4">
              <h2 className="text-center mb-4">Sign in with SSO</h2>
              
              <div className="mb-4">
                <p className="text-center mb-4">Choose your SSO provider</p>
                
                {/* Google SSO Button */}
                <div className="mb-3">
                  <GoogleLoginButton />
                </div>
                
                <div className="text-center mt-4">
                  <a href="/login" className="text-decoration-none">
                    Back to email login
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LoginSSO;
