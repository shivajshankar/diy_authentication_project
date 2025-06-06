import React, { useEffect } from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import 'bootstrap/dist/css/bootstrap.min.css';
import './App.css';
import Login from './components/Login';
import LoginSSO from './components/LoginSSO';
import Register from './components/Register';
import Register1 from './components/Register1';
import Dashboard from './components/Dashboard';
import { useAuth } from './context/AuthContext';

console.log('%cApp.jsx Version: 2.0.REFACTORED', 'color: magenta; font-size: 1.2em; font-weight: bold;');
console.log('App.jsx: File is loading!');

// Debug component to log route changes
const RouteLogger = () => {
  const location = useLocation();
  
  useEffect(() => {
    console.log('Route changed to:', location.pathname);
  }, [location]);
  return null;
};

// A simple wrapper that uses the auth context for protection
const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  console.log(`ProtectedRoute: isAuthenticated=${isAuthenticated}, loading=${loading}`);

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh' }}>
        <div className="spinner-border" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    console.log('ProtectedRoute: Not authenticated, redirecting to /login1');
    return <Navigate to="/login1" replace state={{ from: window.location.pathname }} />;
  }

  return children;
};

// A wrapper for public-only routes (login, register, etc.)
const PublicRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  console.log(`PublicRoute: isAuthenticated=${isAuthenticated}, loading=${loading}`);

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh' }}>
        <div className="spinner-border" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  if (isAuthenticated) {
    console.log('PublicRoute: Already authenticated, redirecting to /dashboard');
    return <Navigate to="/dashboard" replace />;
  }

  return children;
};

function App() {
  console.log('App2: Rendering');
  
  return (
    <div className="App">
      <RouteLogger />
      <Routes>
        {/* Public routes */}
        <Route path="/login/sso" element={
          <PublicRoute>
            <LoginSSO />
          </PublicRoute>
        } />
        
        <Route path="/login1" element={
          <PublicRoute>
            <Login />
          </PublicRoute>
        } />
        
        <Route path="/register" element={
          <PublicRoute>
            <Register />
          </PublicRoute>
        } />
        
        <Route path="/register1" element={
          <div style={{ border: '3px solid blue', padding: '20px', margin: '20px' }}>
            <h2>Register1 Route</h2>
            <Register1 />
          </div>
        } />
        
        {/* Protected routes */}
        <Route path="/dashboard" element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        } />
        
        {/* OAuth callback route */}
        <Route path="/oauth2/redirect" element={
          <div>Processing OAuth2 login...</div>
        } />
        
        {/* Default route */}
        <Route path="/" element={
          <PublicRoute>
            {({ isAuthenticated }) => (
              isAuthenticated ? (
                <Navigate to="/dashboard" replace />
              ) : (
                <Navigate to="/login1" replace />
              )
            )}
          </PublicRoute>
        } />
        
        {/* Catch all other routes */}
        <Route path="*" element={
          <div style={{ padding: '20px' }}>
            <h1>404 Not Found</h1>
            <p>No route matches {window.location.pathname}</p>
          </div>
        } />
      </Routes>
    </div>
  );
}

export default App;
