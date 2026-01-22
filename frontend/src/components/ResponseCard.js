import React from 'react';

function ResponseCard({ response, requestTime, title, endpoint, cityName, promptType }) {
  if (!response) return null;

  const payload = { city: cityName };
  
  const prompts = {
    direct: `Please provide exactly 10 interesting and factual information points about ${cityName}. 
Format your response as a JSON object with the following structure:
{
    "city": "${cityName}",
    "facts": [
        "fact 1",
        "fact 2",
        ...
    ]
}

Make sure each fact is unique, interesting, and accurate. Include a mix of historical, cultural, geographical, and modern facts about the city. If this is not a real city or you don't have information about it, please indicate that in your response.`,
    agent: `Please provide exactly 10 interesting facts about ${cityName}. 

Format your response as a numbered list (1. 2. 3. etc.) with each fact on a new line.

Include a mix of:
- General historical, cultural, and geographical facts
- Specific data from your knowledge base about air quality, water pollution, and cost of living if available
- Modern facts about the city

If you have knowledge base data for this city, make sure to include those specific metrics in your facts.`
  };

  const parseAgentFacts = (agentResponse) => {
    if (!agentResponse) return null;

    const lines = agentResponse.split('\n');
    const facts = [];
    let preamble = '';
    let postamble = '';
    let inFactsSection = false;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
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

  return (
    <div className="response-container">
      <div className="response-title-row">
        <h3 className="response-title">{title}</h3>
        {requestTime && (
          <div className="request-time">
            ⏱️ <strong>{requestTime}s</strong>
          </div>
        )}
      </div>
      
      {endpoint && (
        <details className="api-endpoint-section">
          <summary className="api-endpoint-summary">🌐 API Request Details</summary>
          <div className="api-endpoint-content">
            <div className="endpoint-method">POST {endpoint}</div>
            <div className="endpoint-payload">
              <strong>Payload:</strong>
              <pre>{JSON.stringify(payload, null, 2)}</pre>
            </div>
          </div>
        </details>
      )}
      
      {promptType && (
        <details className="prompt-section">
          <summary className="prompt-summary">💬 Gen AI Prompt</summary>
          <div className="prompt-content">
            <pre>{prompts[promptType]}</pre>
          </div>
        </details>
      )}
      
      <details className="response-section" open>
        <summary className="response-summary">📋 Formatted Response</summary>
        <div className="formatted-response">
          <div className="response-header">
            <h3>{response.city}</h3>
            {response.message && <p className="response-message">{response.message}</p>}
          </div>
          
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
}

export default ResponseCard;
