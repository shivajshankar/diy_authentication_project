import React from 'react';
import { FaGoogle } from 'react-icons/fa';
import { useNavigate } from 'react-router-dom';
import authService from '../services/authService';

const GoogleLoginButton = ({ buttonText = "Continue with Google", className = "" }) => {
  const navigate = useNavigate();

  const handleGoogleLogin = async () => {
    try {
      // This will redirect to the backend's OAuth2 login endpoint
      window.location.href = `${process.env.REACT_APP_API_URL.replace('/api', '')}/oauth2/authorization/google`;
    } catch (error) {
      console.error('Google login error:', error);
    }
  };

  return (
    <button
      onClick={handleGoogleLogin}
      className={`btn btn-outline-danger w-100 ${className}`}
      type="button"
    >
      <FaGoogle className="me-2" /> {buttonText}
    </button>
  );
};

export default GoogleLoginButton;
