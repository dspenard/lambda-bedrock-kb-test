import React from 'react';

function TabBar({ activeTab, onTabChange }) {
  const tabs = [
    { id: 'lambda', label: 'Model vs Agent' },
    { id: 'tab2', label: 'Tab 2' },
    { id: 'tab3', label: 'Tab 3' }
  ];

  return (
    <div className="tabs">
      {tabs.map(tab => (
        <button
          key={tab.id}
          className={`tab ${activeTab === tab.id ? 'active' : ''}`}
          onClick={() => onTabChange(tab.id)}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}

export default TabBar;
