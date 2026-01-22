import React, { useState } from 'react';

function ResponseComparison({ currentResult, aiAvailable }) {
  const [aiAnalysis, setAiAnalysis] = useState(null);
  const [aiLoading, setAiLoading] = useState(false);

  const parseAgentFacts = (agentResponse) => {
    if (!agentResponse) return null;

    const lines = agentResponse.split('\n');
    const facts = [];

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      const factMatch = line.match(/^(\d+)[.)]\s*(.+)/);
      if (factMatch) {
        facts.push(factMatch[2]);
      }
    }

    return facts.length > 0 ? facts : null;
  };

  const compareResponses = (directResp, agentResp) => {
    if (!directResp || !agentResp) return null;

    const directFacts = directResp.facts || [];
    const agentFacts = parseAgentFacts(agentResp.agent_response) || [];

    const areSimilar = (fact1, fact2) => {
      const f1 = fact1.toLowerCase();
      const f2 = fact2.toLowerCase();
      const words1 = f1.split(/\s+/).filter(w => w.length > 3);
      const words2 = f2.split(/\s+/).filter(w => w.length > 3);
      const commonWords = words1.filter(w => words2.includes(w));
      return commonWords.length >= 3;
    };

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

  const generateAiAnalysis = async () => {
    if (!currentResult || !aiAvailable) return;

    setAiLoading(true);
    setAiAnalysis(null);

    try {
      const session = await window.ai.languageModel.create({
        systemPrompt: 'You are an expert at analyzing and comparing information. Provide clear, concise insights.'
      });

      const directFacts = currentResult.directResponse.facts || [];
      const agentFacts = parseAgentFacts(currentResult.agentResponse.agent_response) || [];

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
      session.destroy();
    } catch (err) {
      console.error('AI Analysis Error:', err);
    } finally {
      setAiLoading(false);
    }
  };

  if (!currentResult) return null;

  const comparison = compareResponses(currentResult.directResponse, currentResult.agentResponse);
  if (!comparison) return null;

  return (
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
            <p>Chrome AI setup instructions would go here...</p>
          </div>
        </details>
      )}

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
              <p>Use Chrome's built-in AI to get intelligent insights about the differences between these two responses.</p>
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
    </div>
  );
}

export default ResponseComparison;
