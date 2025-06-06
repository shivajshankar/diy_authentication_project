import React from 'react';

console.log('Register1.jsx: File is loading');

const Register1 = () => {
  console.log('Register1: Component rendering');
  
  return (
    <div style={{
      padding: '40px',
      border: '3px solid green',
      margin: '20px',
      backgroundColor: '#f0fff0',
      borderRadius: '10px'
    }}>
      <h1>🎉 Register1 Component Loaded! 🎉</h1>
      <p>This component is now working in isolation.</p>
      <div style={{ marginTop: '20px', padding: '10px', backgroundColor: 'white', borderRadius: '5px' }}>
        <h3>Debug Info:</h3>
        <p>Current URL: {window.location.href}</p>
        <p>Path: {window.location.pathname}</p>
      </div>
    </div>
  );
};

export default Register1;
