

// File: src/App.jsx
import React, { useState } from 'react';
import OnrampWidget from './components/OnrampWidget';
import './styles/App.css';

const App = () => {
  const [price, setPrice] = useState(10);
  const [tip, setTip] = useState(0);
  const [confirmed, setConfirmed] = useState(false);

  const total = (parseFloat(price) + parseFloat(tip || 0)).toFixed(2);

  return (
    <div className="app-container">
      <h1>🎨 Surprise Art Store</h1>
      <p>Select your tier and (optionally) leave a tip to support the artist.</p>

      <label>Choose an artwork tier:</label>
      <select value={price} onChange={e => setPrice(e.target.value)}>
        {[10, 20, 40, 80, 100, 200].map(amount => (
          <option key={amount} value={amount}>${amount} Tier</option>
        ))}
      </select>

      <label>Tip (optional):</label>
      <input
        type="number"
        min="0"
        value={tip}
        onChange={e => setTip(e.target.value)}
        placeholder="Add a tip"
      />

      <h3>Total: ${total}</h3>

      <OnrampWidget total={total} onConfirm={() => setConfirmed(true)} />

      {confirmed && (
        <div className="confirmation">
          ✅ Payment confirmed! You’ll receive your surprise artwork soon.
        </div>
      )}
    </div>
  );
};

export default App;
