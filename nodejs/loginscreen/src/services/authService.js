import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080/api';

// Create a single axios instance
const api = axios.create({
  baseURL: API_URL,
  withCredentials: true,  // Important for sending cookies
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
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
      if (!window.location.pathname.includes('login1')) {
        localStorage.removeItem('authToken');
        localStorage.removeItem('user');
        currentUserRequest = null;
        window.location.href = '/login1';
      }
    }
    return Promise.reject(error);
  }
);

/**
 * Logs in a user with username and password
 * @param {string} username - The user's username
 * @param {string} password - The user's password
 * @returns {Promise<Object>} The user data and access token
 */
const login = async (username, password) => {
  try {
    console.log('authService: Sending login request for user:', username);
    const response = await api.post('/auth/signin', {
      username,
      password
    }, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      withCredentials: false
    });
    
    console.log('authService: Login response received', {
      hasToken: !!response?.data?.accessToken,
      userId: response?.data?.id
    });
    
    if (response.data.accessToken) {
      const userData = {
        id: response.data.id,
        username: response.data.username || username.split('@')[0],
        email: response.data.email || username
      };
      
      console.log('Login successful:', { user: userData });
      
      // Return the response data which will be handled by the Login component
      return {
        ...response.data,
        user: userData
      };
    }
    
    throw new Error('No access token received');
  } catch (error) {
    console.error('authService: Login error:', {
      message: error.message,
      response: error.response?.data,
      status: error.response?.status
    });
    
    // Enhance the error with more context
    const errorMessage = error.response?.data?.message || 
                        error.message || 
                        'Login failed. Please try again.';
    const enhancedError = new Error(errorMessage);
    enhancedError.response = error.response;
    throw enhancedError;
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
  window.location.href = '/login1';
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

// Add OAuth2 login handler
const handleOAuthCallback = async () => {
  try {
    // Check if we have token in URL parameters
    const urlParams = new URLSearchParams(window.location.search);
    const token = urlParams.get('token');
    const email = urlParams.get('email');
    const name = urlParams.get('name');

    if (token && email) {
      // We have the token in the URL, store it and return user data
      const userData = {
        token,
        user: {
          email,
          name,
          // Add any other user data you need
        }
      };
      
      localStorage.setItem('authToken', token);
      localStorage.setItem('user', JSON.stringify(userData));
      return userData;
    } else {
      // Fallback to the API call if no token in URL
      const response = await api.get('/oauth2/success');
      if (response.data.token) {
        localStorage.setItem('authToken', response.data.token);
        localStorage.setItem('user', JSON.stringify(response.data));
      }
      return response.data;
    }
  } catch (error) {
    console.error('OAuth callback error:', error);
    throw error;
  }
};

// Get OAuth login URL
const getOAuthLoginUrl = (provider = 'google') => {
  return `${API_URL.replace('/api', '')}/oauth2/authorization/${provider}`;
};

const authService = {
  login,
  register,
  logout,
  getCurrentUser,
  getStoredUser,
  handleOAuthCallback,
  getOAuthLoginUrl
};

// Make authService available globally for debugging
if (typeof window !== 'undefined') {
  window.authService = authService;
}

export { 
  login, 
  register, 
  logout, 
  getCurrentUser, 
  getStoredUser, 
  handleOAuthCallback, 
  getOAuthLoginUrl 
};

export default authService;