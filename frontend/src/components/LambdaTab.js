import React, { useState, useEffect } from 'react';
import { fetchAuthSession } from 'aws-amplify/auth';
import CityInput from './CityInput';
import ResponseCard from './ResponseCard';
import ResponseComparison from './ResponseComparison';
import HistorySidebar from './HistorySidebar';

const API_BASE_URL = 'https://gzo6g9zrm8.execute-api.us-east-1.amazonaws.com/prod';

function LambdaTab() {
  const [cityName, setCityName] = useState('');
  const [loading, setLoading] = useState(false);
  const [currentResult, setCurrentResult] = useState(null);
  const [history, setHistory] = useState([]);
  const [error, setError] = useState(null);
  const [aiAvailable, setAiAvailable] = useState(false);

  useEffect(() => {
    const checkAiAvailability = async () => {
      if (window.ai && window.ai.languageModel) {
        try {
          const capabilities = await window.ai.languageModel.capabilities();
          setAiAvailable(capabilities.available === 'readily');
        } catch (err) {
          console.log('Chrome AI not available:', err);
          setAiAvailable(false);
        }
      }
    };
    checkAiAvailability();
  }, []);

  const callBothLambdas = async () => {
    if (!cityName.trim()) {
      setError('Please enter a city name');
      return;
    }

    setLoading(true);
    setError(null);
    setCurrentResult(null);

    try {
      const session = await fetchAuthSession();
      const token = session.tokens?.idToken?.toString();

      if (!token) {
        setError('Authentication token not found. Please sign in again.');
        setLoading(false);
        return;
      }

      const directPromise = (async () => {
        const startTime = performance.now();
        const response = await fetch(`${API_BASE_URL}/direct`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token,
          },
          body: JSON.stringify({ city: cityName }),
        });
        const endTime = performance.now();
        const data = await response.json();
        return {
          data,
          time: ((endTime - startTime) / 1000).toFixed(2),
          status: response.status
        };
      })();

      const agentPromise = (async () => {
        const startTime = performance.now();
        const response = await fetch(`${API_BASE_URL}/agent`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token,
          },
          body: JSON.stringify({ city: cityName }),
        });
        const endTime = performance.now();
        const data = await response.json();
        return {
          data,
          time: ((endTime - startTime) / 1000).toFixed(2),
          status: response.status
        };
      })();

      const [directResult, agentResult] = await Promise.all([directPromise, agentPromise]);

      if (directResult.status === 401 || agentResult.status === 401) {
        setError('Unauthorized. Please sign in again.');
        setLoading(false);
        return;
      }

      const result = {
        id: Date.now(),
        timestamp: new Date().toISOString(),
        city: cityName.trim(),
        directResponse: directResult.data,
        agentResponse: agentResult.data,
        directRequestTime: directResult.time,
        agentRequestTime: agentResult.time
      };

      setCurrentResult(result);
      setHistory(prev => [result, ...prev].slice(0, 10));
      
    } catch (err) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const loadHistoryItem = (item) => {
    setCurrentResult(item);
    setCityName(item.city);
  };

  return (
    <div className="lambda-tab">
      <h2>Compare Direct Model vs Agent Invocation</h2>
      <p className="tab-description">
        <strong>Direct Model:</strong> Calls Claude 3 Haiku directly via Bedrock API<br/>
        <strong>Bedrock Agent:</strong> Uses an agent with knowledge base access for enhanced responses
      </p>
      
      <div className="main-layout">
        <div className="query-section">
          <CityInput
            value={cityName}
            onChange={setCityName}
            onSubmit={callBothLambdas}
            disabled={loading}
          />

          <div className="button-section">
            <button
              onClick={callBothLambdas}
              disabled={loading}
              className="lambda-button primary"
            >
              {loading ? '⏳ Running...' : '🚀 Run'}
            </button>
          </div>

          {error && (
            <div className="error-box">
              {error}
            </div>
          )}

          {loading && (
            <div className="loading-overlay">
              <div className="loading-spinner">
                <div className="spinner-large"></div>
                <p className="loading-text">Calling both Lambda functions via API Gateway endpoints...</p>
              </div>
            </div>
          )}

          {currentResult && (
            <>
              <div className="responses-grid">
                <div className="response-column">
                  <ResponseCard
                    response={currentResult.directResponse}
                    requestTime={currentResult.directRequestTime}
                    title="🎯 Direct Model Invocation"
                    endpoint={`${API_BASE_URL}/direct`}
                    cityName={currentResult.city}
                    promptType="direct"
                  />
                </div>
                
                <div className="response-column">
                  <ResponseCard
                    response={currentResult.agentResponse}
                    requestTime={currentResult.agentRequestTime}
                    title="🤖 Bedrock Agent Invocation"
                    endpoint={`${API_BASE_URL}/agent`}
                    cityName={currentResult.city}
                    promptType="agent"
                  />
                </div>
              </div>

              <ResponseComparison
                currentResult={currentResult}
                aiAvailable={aiAvailable}
              />
            </>
          )}
        </div>

        <HistorySidebar
          history={history}
          currentResultId={currentResult?.id}
          onLoadHistoryItem={loadHistoryItem}
        />
      </div>
    </div>
  );
}

export default LambdaTab;
