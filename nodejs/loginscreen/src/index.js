import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import './index.css';
import App2 from './App2';
import reportWebVitals from './reportWebVitals';
import 'bootstrap/dist/css/bootstrap.min.css';
import { AuthProvider } from './context/AuthContext';

console.log('index.js: Starting application initialization');

const root = ReactDOM.createRoot(document.getElementById('root'));

console.log('index.js: Root element created, starting render');

root.render(
  <React.StrictMode>
    <BrowserRouter>
      <AuthProvider>
        <App2 />
      </AuthProvider>
    </BrowserRouter>
  </React.StrictMode>
);

console.log('index.js: Render completed');

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
