import React from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './components/Login';
import Register from './components/Register';
import Dashboard from './components/Dashboard';
import OAuth2RedirectHandler from './components/OAuth2RedirectHandler';

console.log('App: Module loaded');

// Private route component
const PrivateRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  const location = useLocation();
  
  console.log('PrivateRoute: Rendering', { 
    isAuthenticated, 
    loading, 
    path: location.pathname 
  });
  
  if (loading) {
    console.log('PrivateRoute: Loading, showing spinner');
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-500"></div>
      </div>
    );
  }
  
  if (!isAuthenticated) {
    console.log('PrivateRoute: Not authenticated, redirecting to login');
    return <Navigate to="/login1" state={{ from: location }} replace />;
  }

  console.log('PrivateRoute: User authenticated, rendering children');
  return children;
};

// Public route component
const PublicRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  const location = useLocation();

  console.log('PublicRoute: Rendering', { 
    isAuthenticated, 
    loading, 
    path: location.pathname 
  });

  if (loading) {
    console.log('PublicRoute: Loading, showing spinner');
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-500"></div>
      </div>
    );
  }

  if (isAuthenticated) {
    const from = location.state?.from?.pathname || '/dashboard';
    console.log('PublicRoute: Already authenticated, redirecting to', from);
    return <Navigate to={from} replace />;
  }

  console.log('PublicRoute: Not authenticated, rendering children');
  return children;
};

function AppContent() {
  const { loading } = useAuth();
  const location = useLocation();
  
  console.log('AppContent: Rendering', { 
    loading, 
    path: location.pathname 
  });
  
  if (loading) {
    console.log('AppContent: Loading, showing spinner');
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-500"></div>
      </div>
    );
  }
  
  console.log('AppContent: Render routes');
  return (
    <div className="App">
      <Routes>
        <Route
          path="/login1"
          element={
            <PublicRoute>
              <Login />
            </PublicRoute>
          }
        />
        <Route
          path="/register"
          element={
            <PublicRoute>
              <Register />
            </PublicRoute>
          }
        />
        <Route
          path="/oauth2/redirect"
          element={
            <PublicRoute>
              <OAuth2RedirectHandler />
            </PublicRoute>
          }
        />
        <Route
          path="/dashboard"
          element={
            <PrivateRoute>
              <Dashboard />
            </PrivateRoute>
          }
        />
        <Route
          path="/"
          element={
            <PublicRoute>
              {({ isAuthenticated }) => (
                isAuthenticated ? (
                  <Navigate to="/dashboard" replace />
                ) : (
                  <Navigate to="/login1" replace />
                )
              )}
            </PublicRoute>
          }
        />
        <Route
          path="*"
          element={
            <Navigate to="/" replace />
          }
        />
      </Routes>
    </div>
  );
}

function App() {
  console.log('App: Rendering');
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
