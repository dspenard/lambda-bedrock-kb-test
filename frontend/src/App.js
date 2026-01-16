import React, { useState } from 'react';
import { Amplify } from 'aws-amplify';
import { Authenticator } from '@aws-amplify/ui-react';
import { fetchAuthSession } from 'aws-amplify/auth';
import '@aws-amplify/ui-react/styles.css';
import './App.css';
import awsConfig from './aws-config';

Amplify.configure(awsConfig);

const API_BASE_URL = 'https://w3qxrgn9r8.execute-api.us-east-1.amazonaws.com/prod';

function App() {
  const [activeTab, setActiveTab] = useState('lambda');
  const [cityName, setCityName] = useState('');
  const [loading, setLoading] = useState(false);
  const [currentResult, setCurrentResult] = useState(null);
  const [history, setHistory] = useState([]);
  const [error, setError] = useState(null);
  const [aiAnalysis, setAiAnalysis] = useState(null);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiAvailable, setAiAvailable] = useState(false);
  const [showCityDropdown, setShowCityDropdown] = useState(false);

  // Cities from the knowledge base (alphabetically sorted)
  const knowledgeBaseCities = [
    'Amsterdam',
    'Athens',
    'Auckland',
    'Bangkok',
    'Barcelona',
    'Beijing',
    'Berlin',
    'Bogotá',
    'Boston',
    'Brussels',
    'Budapest',
    'Buenos Aires',
    'Cairo',
    'Cape Town',
    'Chicago',
    'Chongqing',
    'Copenhagen',
    'Delhi',
    'Dhaka',
    'Dubai',
    'Dublin',
    'Guangzhou',
    'Hong Kong',
    'Istanbul',
    'Jakarta',
    'Johannesburg',
    'Karachi',
    'Kolkata',
    'Lagos',
    'Lima',
    'Lisbon',
    'London',
    'Los Angeles',
    'Madrid',
    'Manila',
    'Melbourne',
    'Mexico City',
    'Moscow',
    'Mumbai',
    'New York',
    'Osaka',
    'Paris',
    'Rio de Janeiro',
    'Rome',
    'São Paulo',
    'Seoul',
    'Shanghai',
    'Singapore',
    'Sydney',
    'Tokyo'
  ];

  // Filter cities based on input
  const filteredCities = cityName
    ? knowledgeBaseCities.filter(city =>
        city.toLowerCase().includes(cityName.toLowerCase())
      )
    : knowledgeBaseCities;

  // Check if Chrome AI is available on component mount
  React.useEffect(() => {
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

  // Function to parse agent response and extract facts
  const parseAgentFacts = (agentResponse) => {
    if (!agentResponse) return null;

    // Try to find numbered facts in the response
    const lines = agentResponse.split('\n');
    const facts = [];
    let preamble = '';
    let postamble = '';
    let inFactsSection = false;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      // Check if line starts with a number followed by period or parenthesis
      const factMatch = line.match(/^(\d+)[.)]\s*(.+)/);
      
      if (factMatch) {
        inFactsSection = true;
        facts.push(factMatch[2]);
      } else if (line.length > 0) {
        if (!inFactsSection && facts.length === 0) {
          preamble += line + '\n';
        } else if (inFactsSection && line.length > 0) {
          postamble += line + '\n';
        }
      }
    }

    if (facts.length > 0) {
      return {
        preamble: preamble.trim(),
        facts: facts,
        postamble: postamble.trim()
      };
    }

    return null;
  };

  const callBothLambdas = async () => {
    if (!cityName.trim()) {
      setError('Please enter a city name');
      return;
    }

    setLoading(true);
    setError(null);
    setCurrentResult(null);

    try {
      // Get the JWT token from Cognito
      const session = await fetchAuthSession();
      const token = session.tokens?.idToken?.toString();

      if (!token) {
        setError('Authentication token not found. Please sign in again.');
        setLoading(false);
        return;
      }

      // Call both endpoints in parallel with individual timing
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
      
      // Add to history (keep last 10)
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
    setAiAnalysis(null); // Clear AI analysis when loading history
  };

  // Function to generate AI analysis using Chrome's built-in AI
  const generateAiAnalysis = async () => {
    if (!currentResult || !aiAvailable) return;

    setAiLoading(true);
    setAiAnalysis(null);

    try {
      const session = await window.ai.languageModel.create({
        systemPrompt: 'You are an expert at analyzing and comparing information. Provide clear, concise insights.'
      });

      const directFacts = currentResult.directResponse.facts || [];
      const agentParsed = parseAgentFacts(currentResult.agentResponse.agent_response);
      const agentFacts = agentParsed?.facts || [];

      const prompt = `I have two different responses about the city "${currentResult.city}":

DIRECT MODEL RESPONSE (${directFacts.length} facts):
${directFacts.map((f, i) => `${i + 1}. ${f}`).join('\n')}

AGENT WITH KNOWLEDGE BASE RESPONSE (${agentFacts.length} facts):
${agentFacts.map((f, i) => `${i + 1}. ${f}`).join('\n')}

Please analyze these two responses and provide:
1. Key differences in the type of information provided
2. Which response appears more detailed or specific
3. Any unique insights from the knowledge base (agent) response
4. Overall assessment of which approach provides better information

Keep your analysis concise and focused on the most important differences.`;

      const result = await session.prompt(prompt);
      setAiAnalysis(result);
      
      // Clean up the session
      session.destroy();
    } catch (err) {
      setError(`AI Analysis Error: ${err.message}`);
    } finally {
      setAiLoading(false);
    }
  };

  // Function to compare responses and find differences
  const compareResponses = (directResp, agentResp) => {
    if (!directResp || !agentResp) return null;

    const directFacts = directResp.facts || [];
    const agentParsed = parseAgentFacts(agentResp.agent_response);
    const agentFacts = agentParsed?.facts || [];

    // Simple similarity check (case-insensitive, partial matching)
    const areSimilar = (fact1, fact2) => {
      const f1 = fact1.toLowerCase();
      const f2 = fact2.toLowerCase();
      
      // Check if they share significant words (more than 3 words in common)
      const words1 = f1.split(/\s+/).filter(w => w.length > 3);
      const words2 = f2.split(/\s+/).filter(w => w.length > 3);
      const commonWords = words1.filter(w => words2.includes(w));
      
      return commonWords.length >= 3;
    };

    // Categorize facts
    const uniqueToDirect = [];
    const uniqueToAgent = [];
    const similar = [];

    directFacts.forEach((directFact, idx) => {
      const matchIndex = agentFacts.findIndex(agentFact => areSimilar(directFact, agentFact));
      if (matchIndex !== -1) {
        similar.push({
          direct: directFact,
          agent: agentFacts[matchIndex],
          directIndex: idx + 1,
          agentIndex: matchIndex + 1
        });
      } else {
        uniqueToDirect.push({ fact: directFact, index: idx + 1 });
      }
    });

    agentFacts.forEach((agentFact, idx) => {
      const alreadyMatched = similar.some(s => s.agent === agentFact);
      if (!alreadyMatched) {
        uniqueToAgent.push({ fact: agentFact, index: idx + 1 });
      }
    });

    return {
      uniqueToDirect,
      uniqueToAgent,
      similar,
      directTotal: directFacts.length,
      agentTotal: agentFacts.length
    };
  };

  // Render response component
  const renderResponse = (response, requestTime, title, endpoint, cityName) => {
    if (!response) return null;

    const payload = { city: cityName };

    return (
      <div className="response-container">
        <h3 className="response-title">{title}</h3>
        
        {endpoint && (
          <div className="api-endpoint">
            <div className="endpoint-method">POST {endpoint}</div>
            <div className="endpoint-payload">
              <strong>Payload:</strong>
              <pre>{JSON.stringify(payload, null, 2)}</pre>
            </div>
          </div>
        )}
        
        {requestTime && (
          <div className="request-time">
            ⏱️ Request completed in <strong>{requestTime}s</strong>
          </div>
        )}
        
        <details className="response-section" open>
          <summary className="response-summary">📋 Formatted Response</summary>
          <div className="formatted-response">
            <div className="response-header">
              <h3>{response.city}</h3>
              {response.message && <p className="response-message">{response.message}</p>}
            </div>
            
            {/* Direct Lambda response with facts array */}
            {response.facts && response.facts.length > 0 && (
              <div className="facts-table">
                <table>
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Fact</th>
                    </tr>
                  </thead>
                  <tbody>
                    {response.facts.map((fact, index) => (
                      <tr key={index}>
                        <td className="fact-number">{index + 1}</td>
                        <td className="fact-text">{fact}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
            
            {/* Agent Lambda response - parse and display facts */}
            {response.agent_response && !response.facts && (() => {
              const parsed = parseAgentFacts(response.agent_response);
              
              if (parsed) {
                return (
                  <div className="agent-response-box">
                    {parsed.preamble && (
                      <div className="agent-preamble">
                        {parsed.preamble}
                      </div>
                    )}
                    
                    <div className="facts-table">
                      <table>
                        <thead>
                          <tr>
                            <th>#</th>
                            <th>Fact</th>
                          </tr>
                        </thead>
                        <tbody>
                          {parsed.facts.map((fact, index) => (
                            <tr key={index}>
                              <td className="fact-number">{index + 1}</td>
                              <td className="fact-text">{fact}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                    
                    {parsed.postamble && (
                      <div className="agent-postamble">
                        {parsed.postamble}
                      </div>
                    )}
                  </div>
                );
              } else {
                // Fallback if no facts found
                return (
                  <div className="agent-response-box">
                    <div className="agent-response-text">
                      {response.agent_response}
                    </div>
                  </div>
                );
              }
            })()}
            
            <div className="response-metadata">
              {response.total_facts && (
                <span className="metadata-item">
                  <strong>Total Facts:</strong> {response.total_facts}
                </span>
              )}
              {response.model_used && (
                <span className="metadata-item">
                  <strong>Model:</strong> {response.model_used}
                </span>
              )}
              {response.source && (
                <span className="metadata-item">
                  <strong>Source:</strong> {response.source}
                </span>
              )}
              {response.agent_id && (
                <span className="metadata-item">
                  <strong>Agent ID:</strong> {response.agent_id}
                </span>
              )}
            </div>
          </div>
        </details>
        
        <details className="response-section">
          <summary className="response-summary">🔍 Raw JSON Response</summary>
          <div className="json-response">
            <pre>{JSON.stringify(response, null, 2)}</pre>
          </div>
        </details>
      </div>
    );
  };

  return (
    <Authenticator>
      {({ signOut, user }) => (
        <div className="App">
          <header className="App-header">
            <div className="header-content">
              <div>
                <h1>🌍 Bedrock City Facts</h1>
                <p className="subtitle">Powered by AWS Bedrock & React</p>
              </div>
              <div className="user-info">
                <span className="user-email">{user?.signInDetails?.loginId}</span>
                <button onClick={signOut} className="sign-out-button">
                  Sign Out
                </button>
              </div>
            </div>
          </header>

          <div className="tabs">
            <button
              className={`tab ${activeTab === 'lambda' ? 'active' : ''}`}
              onClick={() => setActiveTab('lambda')}
            >
              Model vs Agent
            </button>
            <button
              className={`tab ${activeTab === 'tab2' ? 'active' : ''}`}
              onClick={() => setActiveTab('tab2')}
            >
              Tab 2
            </button>
            <button
              className={`tab ${activeTab === 'tab3' ? 'active' : ''}`}
              onClick={() => setActiveTab('tab3')}
            >
              Tab 3
            </button>
          </div>

          <div className="content">
            {activeTab === 'lambda' && (
              <div className="lambda-tab">
                <h2>Compare Direct Model vs Agent Invocation</h2>
                <p className="tab-description">
                  <strong>Direct Model:</strong> Calls Claude 3 Haiku directly via Bedrock API<br/>
                  <strong>Bedrock Agent:</strong> Uses an agent with knowledge base access for enhanced responses
                </p>
                
                <div className="main-layout">
                  <div className="query-section">
                    <div className="input-section">
                      <label className="input-label">
                        💡 Select from some popular cities with supplemental knowledge base data, or enter any city (even fictional ones!)
                      </label>
                      <div className="autocomplete-wrapper">
                        <input
                          type="text"
                          placeholder="Enter or select a city name (e.g., Tokyo, Paris, New York)"
                          value={cityName}
                          onChange={(e) => setCityName(e.target.value)}
                          onFocus={() => setShowCityDropdown(true)}
                          onBlur={() => setTimeout(() => setShowCityDropdown(false), 200)}
                          onKeyPress={(e) => e.key === 'Enter' && !loading && callBothLambdas()}
                          disabled={loading}
                          className="city-input"
                        />
                        {showCityDropdown && filteredCities.length > 0 && (
                          <div className="city-dropdown">
                            {filteredCities.map((city, index) => (
                              <div
                                key={index}
                                className="city-option"
                                onClick={() => {
                                  setCityName(city);
                                  setShowCityDropdown(false);
                                }}
                              >
                                {city}
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>

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
                            {renderResponse(
                              currentResult.directResponse, 
                              currentResult.directRequestTime, 
                              '🎯 Direct Model Invocation',
                              `${API_BASE_URL}/direct`,
                              currentResult.city
                            )}
                          </div>
                          
                          <div className="response-column">
                            {renderResponse(
                              currentResult.agentResponse, 
                              currentResult.agentRequestTime, 
                              '🤖 Bedrock Agent Invocation',
                              `${API_BASE_URL}/agent`,
                              currentResult.city
                            )}
                          </div>
                        </div>

                        <div className="comparison-section">
                          <h3 className="comparison-title">🔍 Response Comparison</h3>
                          
                          <details className="comparison-how-it-works">
                            <summary className="how-it-works-summary">
                              ℹ️ How does this comparison work?
                            </summary>
                            <div className="how-it-works-content">
                              <p>
                                This comparison is generated <strong>client-side</strong> using a simple text similarity algorithm:
                              </p>
                              <ol>
                                <li><strong>Extract facts:</strong> Parse the numbered facts from both responses</li>
                                <li><strong>Compare each fact:</strong> For each fact, check if it shares 3 or more significant words (longer than 3 characters) with any fact from the other response</li>
                                <li><strong>Categorize:</strong> Group facts into three categories:
                                  <ul>
                                    <li><strong>Unique to Direct Model:</strong> Facts only in the direct model response</li>
                                    <li><strong>Unique to Agent:</strong> Facts only in the agent response (often includes knowledge base data)</li>
                                    <li><strong>Similar Facts:</strong> Facts that appear in both responses with similar wording</li>
                                  </ul>
                                </li>
                              </ol>
                              <p className="how-it-works-note">
                                <strong>Note:</strong> This is a basic word-matching algorithm. For more sophisticated analysis, 
                                use the Chrome AI feature (if available) which provides semantic understanding of the differences.
                              </p>
                            </div>
                          </details>

                          {!aiAvailable && (
                            <details className="ai-setup-instructions">
                              <summary className="ai-setup-summary">
                                💡 <strong>Chrome AI not available (Experimental Feature).</strong> Click here for setup instructions
                              </summary>
                              <div className="ai-setup-content">
                                <div className="experimental-notice">
                                  ⚠️ <strong>Note:</strong> Chrome's built-in AI is highly experimental and may not work for everyone. 
                                  The comparison feature works great without it!
                                </div>

                                <h4>How to Enable Chrome AI (Advanced)</h4>
                                
                                <div className="setup-step">
                                  <h5>1. Get Chrome Canary, Dev, or Beta</h5>
                                  <p>You need Chrome version 127 or higher. Download one of these:</p>
                                  <ul>
                                    <li><a href="https://www.google.com/chrome/canary/" target="_blank" rel="noopener noreferrer">Chrome Canary</a></li>
                                    <li><a href="https://www.google.com/chrome/dev/" target="_blank" rel="noopener noreferrer">Chrome Dev</a></li>
                                    <li><a href="https://www.google.com/chrome/beta/" target="_blank" rel="noopener noreferrer">Chrome Beta</a></li>
                                  </ul>
                                </div>

                                <div className="setup-step">
                                  <h5>2. Enable Required Flags</h5>
                                  <p>Open Chrome and enable these flags:</p>
                                  <div className="flag-item">
                                    <strong>Prompt API:</strong>
                                    <code>chrome://flags/#prompt-api-for-gemini-nano</code>
                                    <span className="flag-value">Set to: <strong>Enabled</strong></span>
                                  </div>
                                  <div className="flag-item">
                                    <strong>Optimization Guide:</strong>
                                    <code>chrome://flags/#optimization-guide-on-device-model</code>
                                    <span className="flag-value">Set to: <strong>Enabled BypassPerfRequirement</strong></span>
                                  </div>
                                </div>

                                <div className="setup-step">
                                  <h5>3. Restart Chrome</h5>
                                  <p>Click the blue "Relaunch" button that appears at the bottom of the flags page. Wait for Chrome to fully restart.</p>
                                </div>

                                <div className="setup-step">
                                  <h5>4. Download the AI Model Component</h5>
                                  <p>After restarting:</p>
                                  <ol>
                                    <li>Go to: <code>chrome://components/</code></li>
                                    <li>Find "Optimization Guide On Device Model" in the list</li>
                                    <li>Click the "Check for update" button next to it</li>
                                    <li>Wait for the component to download (may take several minutes)</li>
                                    <li>The version number should update when complete</li>
                                  </ol>
                                </div>

                                <div className="setup-step">
                                  <h5>5. Verify Installation</h5>
                                  <p>Test if the API is available:</p>
                                  <ol>
                                    <li>Open DevTools (F12 or Cmd+Option+I on Mac)</li>
                                    <li>Go to the Console tab</li>
                                    <li>Run: <code>console.log(window.ai)</code></li>
                                    <li>If you see an object (not undefined), continue to next step</li>
                                    <li>Run: <code>await window.ai.languageModel.create()</code></li>
                                    <li><strong>You may see an error</strong> - hover over it to see if the model needs downloading</li>
                                    <li>Wait a few minutes, then run the command again</li>
                                    <li>When it succeeds without error, you're ready!</li>
                                  </ol>
                                </div>

                                <div className="setup-step">
                                  <h5>6. Refresh This Page</h5>
                                  <p>Once the model is ready, refresh this page and the "✨ AI Analysis" button will appear!</p>
                                </div>

                                <div className="setup-note">
                                  <strong>Troubleshooting:</strong> If <code>window.ai</code> is still undefined after following all steps, 
                                  the API may be gated by origin trials, regional restrictions, or other experimental limitations. 
                                  This is normal for cutting-edge features. The app works perfectly without it!
                                </div>
                              </div>
                            </details>
                          )}

                          {(() => {
                            const comparison = compareResponses(
                              currentResult.directResponse, 
                              currentResult.agentResponse
                            );
                            if (!comparison) return null;

                            return (
                              <div className="comparison-content">
                                <div className="comparison-stats">
                                  <div className="stat-item">
                                    <span className="stat-label">Direct Model Facts:</span>
                                    <span className="stat-value">{comparison.directTotal}</span>
                                  </div>
                                  <div className="stat-item">
                                    <span className="stat-label">Agent Facts:</span>
                                    <span className="stat-value">{comparison.agentTotal}</span>
                                  </div>
                                  <div className="stat-item">
                                    <span className="stat-label">Similar Facts:</span>
                                    <span className="stat-value">{comparison.similar.length}</span>
                                  </div>
                                </div>

                                {aiAvailable && (
                                  <div className="ai-analysis-section">
                                    <div className="ai-analysis-intro">
                                      <strong>🤖 AI-Powered Analysis</strong>
                                      <p>Use Chrome's built-in AI to get intelligent insights about the differences between these two responses. 
                                      This is an alternative to the client-side comparison shown below.</p>
                                    </div>
                                    <button
                                      onClick={generateAiAnalysis}
                                      disabled={aiLoading}
                                      className="ai-analysis-button"
                                    >
                                      {aiLoading ? '⏳ Analyzing...' : '✨ AI Analysis'}
                                    </button>
                                    
                                    {aiAnalysis && (
                                      <div className="ai-analysis-result">
                                        <h4>🤖 Chrome AI Analysis</h4>
                                        <div className="ai-analysis-text">
                                          {aiAnalysis}
                                        </div>
                                      </div>
                                    )}
                                  </div>
                                )}

                                <div className="comparison-grid">
                                  {comparison.uniqueToDirect.length > 0 && (
                                    <div className="comparison-box unique-direct">
                                      <h4>🎯 Unique to Direct Model ({comparison.uniqueToDirect.length})</h4>
                                      <ul>
                                        {comparison.uniqueToDirect.map((item, idx) => (
                                          <li key={idx}>
                                            <span className="fact-badge">#{item.index}</span>
                                            {item.fact}
                                          </li>
                                        ))}
                                      </ul>
                                    </div>
                                  )}

                                  {comparison.uniqueToAgent.length > 0 && (
                                    <div className="comparison-box unique-agent">
                                      <h4>🤖 Unique to Agent ({comparison.uniqueToAgent.length})</h4>
                                      <ul>
                                        {comparison.uniqueToAgent.map((item, idx) => (
                                          <li key={idx}>
                                            <span className="fact-badge">#{item.index}</span>
                                            {item.fact}
                                          </li>
                                        ))}
                                      </ul>
                                    </div>
                                  )}

                                  {comparison.similar.length > 0 && (
                                    <div className="comparison-box similar-facts">
                                      <h4>🤝 Similar Facts ({comparison.similar.length})</h4>
                                      <div className="similar-list">
                                        {comparison.similar.map((item, idx) => (
                                          <div key={idx} className="similar-item">
                                            <div className="similar-fact direct-similar">
                                              <span className="fact-badge">Direct #{item.directIndex}</span>
                                              {item.direct}
                                            </div>
                                            <div className="similar-arrow">↔️</div>
                                            <div className="similar-fact agent-similar">
                                              <span className="fact-badge">Agent #{item.agentIndex}</span>
                                              {item.agent}
                                            </div>
                                          </div>
                                        ))}
                                      </div>
                                    </div>
                                  )}
                                </div>
                              </div>
                            );
                          })()}
                        </div>
                      </>
                    )}
                  </div>

                  {history.length > 0 && (
                    <div className="history-sidebar">
                      <h3 className="history-title">📜 Recent Queries</h3>
                      <div className="history-list">
                        {history.map((item) => (
                          <div
                            key={item.id}
                            className={`history-item ${currentResult?.id === item.id ? 'active' : ''}`}
                            onClick={() => loadHistoryItem(item)}
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
                  )}
                </div>
              </div>
            )}

            {activeTab === 'tab2' && (
              <div className="tab-content">
                <h2>Tab 2</h2>
              </div>
            )}

            {activeTab === 'tab3' && (
              <div className="tab-content">
                <h2>Tab 3</h2>
              </div>
            )}
          </div>
        </div>
      )}
    </Authenticator>
  );
}

export default App;
