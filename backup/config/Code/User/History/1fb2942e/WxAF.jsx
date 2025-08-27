// File: src/main.jsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import './styles/App.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

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

// File: src/components/OnrampWidget.jsx
import React from 'react';

const OnrampWidget = ({ total, onConfirm }) => {
  const clientId = import.meta.env.VITE_ONCHAINKIT_API_KEY;
  const walletAddress = import.meta.env.VITE_RECEIVING_WALLET;

  const handleClick = () => {
    const widget = window.CoinbaseOnramp?.init({
      clientId,
      appId: clientId,
      walletAddress,
      defaultNetwork: 'base',
      defaultAsset: 'usdc',
      experienceLoggedIn: 'popup',
      amount: total,
      onSuccess: (event) => {
        console.log('Success:', event);
        onConfirm();
      },
      onExit: (event) => {
        console.log('Exited:', event);
      },
    });

    widget.open();
  };

  return <button onClick={handleClick}>Buy with Coinbase</button>;
};

export default OnrampWidget;

