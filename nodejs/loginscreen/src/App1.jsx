import React from 'react';
import { Routes, Route } from 'react-router-dom';
import Register1 from './components/Register1';

console.log('App1.jsx: Loading minimal app with only Register1');

function App1() {
  console.log('App1: Rendering');
  
  return (
    <div className="App1" style={{ padding: '20px', backgroundColor: '#f0f8ff' }}>
      <h1>Minimal Test App</h1>
      <Routes>
        <Route path="/register1" element={<Register1 />} />
        <Route path="/" element={
          <div>
            <h2>Welcome to Minimal Test App</h2>
            <p>Try navigating to <a href="/register1">/register1</a></p>
          </div>
        } />
      </Routes>
    </div>
  );
}

export default App1;
