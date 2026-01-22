import React from 'react';

function Header({ user, onSignOut }) {
  return (
    <header className="App-header">
      <div className="header-content">
        <div>
          <h1>🌍 Bedrock City Facts</h1>
          <p className="subtitle">Powered by AWS Bedrock & React</p>
        </div>
        <div className="user-info">
          <span className="user-email">{user?.signInDetails?.loginId}</span>
          <button onClick={onSignOut} className="sign-out-button">
            Sign Out
          </button>
        </div>
      </div>
    </header>
  );
}

export default Header;
