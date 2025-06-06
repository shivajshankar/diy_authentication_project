import React from 'react';
import { FcGoogle } from 'react-icons/fc';

const GoogleLoginButton = () => {
  const handleGoogleLogin = () => {
    // Store the current path to redirect back after login
    const redirectAfterLogin = window.location.pathname === '/login/sso' 
      ? '/login/sso' 
      : window.location.pathname;
    
    // Store the redirect URL in session storage
    sessionStorage.setItem('redirectAfterLogin', redirectAfterLogin);
    
    // Redirect to the server's OAuth endpoint
    window.location.href = '/api/auth/oauth2/authorization/google';
  };

  return (
    <button 
      onClick={handleGoogleLogin}
      className="btn btn-outline-secondary w-100 d-flex align-items-center justify-content-center"
      type="button"
    >
      <FcGoogle className="me-2" size={20} />
      Continue with Google
    </button>
  );
};

export default GoogleLoginButton;
