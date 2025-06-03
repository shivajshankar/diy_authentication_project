import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080/api';

// Create a single axios instance
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Cache for the current user request
let currentUserRequest = null;
let lastRequestTime = 0;
const REQUEST_CACHE_DURATION = 5000; // 5 seconds cache

// Helper function to get stored user
const getStoredUser = () => {
  const userStr = localStorage.getItem('user');
  return userStr ? JSON.parse(userStr) : null;
};

// Add request interceptor to include auth token
api.interceptors.request.use(
  (config) => {
    // Skip adding token for login/register requests
    if (config.url.includes('/auth/signin') || config.url.includes('/auth/signup')) {
      return config;
    }
    
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Add response interceptor to handle 401 errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Only clear and redirect if we're not already on the login page
      if (!window.location.pathname.includes('login')) {
        localStorage.removeItem('authToken');
        localStorage.removeItem('user');
        currentUserRequest = null;
        window.location.href = '/';
      }
    }
    return Promise.reject(error);
  }
);

const login = async (username, password) => {
  try {
    const response = await api.post('/auth/signin', { username, password });
    
    if (response.data.accessToken) {
      localStorage.setItem('authToken', response.data.accessToken);
      
      const userData = {
        id: response.data.id,
        username: response.data.username,
        email: response.data.email
      };
      
      localStorage.setItem('user', JSON.stringify(userData));
      return userData;
    }
    
    throw new Error('No access token received');
  } catch (error) {
    console.error('Login error:', error);
    throw error.response?.data?.message || 'Login failed. Please check your credentials.';
  }
};

const register = (username, email, password) => {
  return api.post('/auth/signup', { username, email, password });
};

const logout = () => {
  // Clear all auth data and cache
  localStorage.removeItem('authToken');
  localStorage.removeItem('user');
  currentUserRequest = null;
  lastRequestTime = 0;
  
  // Redirect to login page
  window.location.href = '/';
};

const getCurrentUser = async () => {
  const now = Date.now();
  
  // Return cached request if it's still valid
  if (currentUserRequest && (now - lastRequestTime) < REQUEST_CACHE_DURATION) {
    return currentUserRequest;
  }

  try {
    const token = localStorage.getItem('authToken');
    if (!token) {
      throw new Error('No authentication token found');
    }

    // Create a new request
    currentUserRequest = (async () => {
      try {
        const response = await api.get('/auth/me');
        
        if (response.data) {
          const userData = {
            id: response.data.id,
            username: response.data.username,
            email: response.data.email
          };
          
          localStorage.setItem('user', JSON.stringify(userData));
          lastRequestTime = Date.now();
          return userData;
        }
        
        throw new Error('No user data received');
      } finally {
        // Clear the current request when it's no longer valid
        if ((Date.now() - lastRequestTime) >= REQUEST_CACHE_DURATION) {
          currentUserRequest = null;
        }
      }
    })();

    return await currentUserRequest;
  } catch (error) {
    console.error('Error fetching current user:', error);
    // Clear auth data on error
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
    currentUserRequest = null;
    lastRequestTime = 0;
    throw error;
  }
};

export { login, register, logout, getCurrentUser, getStoredUser };