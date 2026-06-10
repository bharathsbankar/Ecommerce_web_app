import axios from 'axios';

// The React app runs in the user's browser, so it communicates with the
// microservices by making HTTP requests to the host-mapped port of KrakenD (port 8080).
const api = axios.create({
  baseURL: 'http://localhost:8080'
});

// Authorization Interceptor: Automatically extract stored JWT and append as Bearer token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

export default api;
