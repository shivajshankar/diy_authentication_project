import React, { useEffect } from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import 'bootstrap/dist/css/bootstrap.min.css';
import './App.css';
import Login1 from './components/Login1';
import LoginSSO from './components/LoginSSO';
import Register from './components/Register';
import Register1 from './components/Register1';
import Dashboard from './components/Dashboard';
import { useAuth } from './context/AuthContext';

console.log('App2.jsx: Loading with enhanced logging');

// Debug component
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
  console.log('ProtectedRoute:', { isAuthenticated, loading });

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
    console.log('ProtectedRoute: Not authenticated, redirecting to login');
    return <Navigate to="/login1" replace state={{ from: window.location.pathname }} />;
  }

  return children;
};

// A wrapper for public-only routes (login, register, etc.)
const PublicRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  console.log('PublicRoute:', { isAuthenticated, loading });

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
    console.log('PublicRoute: Already authenticated, redirecting to dashboard');
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
            <Login1 />
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
        
        {/* Default route */}
        <Route path="/" element={
          <Navigate to="/login1" replace />
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
