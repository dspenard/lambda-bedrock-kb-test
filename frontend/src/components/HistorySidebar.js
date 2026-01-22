import React from 'react';

function HistorySidebar({ history, currentResultId, onLoadHistoryItem }) {
  if (history.length === 0) return null;

  return (
    <div className="history-sidebar">
      <h3 className="history-title">📜 Recent Queries</h3>
      <div className="history-list">
        {history.map((item) => (
          <div
            key={item.id}
            className={`history-item ${currentResultId === item.id ? 'active' : ''}`}
            onClick={() => onLoadHistoryItem(item)}
          >
            <div className="history-city">{item.city}</div>
            <div className="history-time">
              {new Date(item.timestamp).toLocaleTimeString()}
            </div>
            <div className="history-stats">
              <span>🎯 Direct: {item.directRequestTime}s</span>
              <span>🤖 Agent: {item.agentRequestTime}s</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default HistorySidebar;
