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

