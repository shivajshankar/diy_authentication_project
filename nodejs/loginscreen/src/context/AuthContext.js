import React, { createContext, useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { getCurrentUser } from '../services/authService';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  console.log('AuthProvider: Initializing');
  
  const [state, setState] = useState({
    user: null,
    isAuthenticated: false,
    loading: true,
    initialized: false
  });

  console.log('AuthProvider: Initial state set', state);
  
  const navigate = useNavigate();
  const location = useLocation();
  const initialRender = useRef(true);

  // Initialize authentication state
  useEffect(() => {
    console.log('AuthProvider: Checking initial auth state');
    
    const initAuth = async () => {
      try {
        const user = await getCurrentUser();
        console.log('AuthProvider: Initial auth check - User authenticated', user);
        setState({
          user,
          isAuthenticated: true,
          loading: false,
          initialized: true
        });
      } catch (error) {
        console.log('AuthProvider: Initial auth check - No valid session');
        setState(prev => ({
          ...prev,
          isAuthenticated: false,
          loading: false,
          initialized: true
        }));
      }
    };

    initAuth();
  }, []);

  // Handle route protection and redirections
  useEffect(() => {
    if (!state.initialized) {
      console.log('AuthProvider: Auth not initialized yet, skipping redirection');
      return;
    }

    console.log(`AuthProvider: Route changed to ${location.pathname}`);
    console.log('AuthProvider: Current auth state', { 
      isAuthenticated: state.isAuthenticated,
      from: location.state?.from
    });

    const publicRoutes = ['/login1', '/register', '/register1', '/login/sso', '/oauth2/redirect'];
    const isPublicRoute = publicRoutes.includes(location.pathname);

    if (state.isAuthenticated && isPublicRoute) {
      // If authenticated and trying to access public route, redirect to dashboard or intended URL
      const redirectTo = location.state?.from?.pathname || '/dashboard';
      console.log(`AuthProvider: Authenticated user on public route, redirecting to ${redirectTo}`);
      navigate(redirectTo, { replace: true });
    } else if (!state.isAuthenticated && !isPublicRoute) {
      // If not authenticated and trying to access protected route, redirect to login
      console.log('AuthProvider: Unauthenticated user, redirecting to login');
      navigate('/login1', { 
        state: { from: location },
        replace: true 
      });
    }
  }, [location, navigate, state.isAuthenticated, state.initialized]);

  // Login function to update auth state
  const login = useCallback(async ({ user, authToken }) => {
    console.group('AuthProvider: login called');
    try {
      if (!user || !authToken) {
        throw new Error('User and token are required');
      }

      console.log('AuthProvider: Storing user and token');
      localStorage.setItem('user', JSON.stringify(user));
      localStorage.setItem('authToken', authToken);
      
      setState({
        user,
        isAuthenticated: true,
        loading: false,
        initialized: true
      });
      
      console.log('AuthProvider: Login successful');
      return true;
    } catch (error) {
      console.error('AuthProvider: Login failed:', error);
      setState(prev => ({
        ...prev,
        isAuthenticated: false,
        loading: false,
        error: error.message
      }));
      return false;
    } finally {
      console.groupEnd();
    }
  }, []);

  // Logout function
  const logout = useCallback(() => {
    console.log('AuthProvider: Logging out');
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
    
    setState({
      user: null,
      isAuthenticated: false,
      loading: false,
      initialized: true
    });
    
    navigate('/login1', { replace: true });
    console.log('AuthProvider: Logout complete');
  }, [navigate]);

  return (
    <AuthContext.Provider
      value={{
        user: state.user,
        isAuthenticated: state.isAuthenticated,
        loading: state.loading,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = React.useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export default AuthContext;
