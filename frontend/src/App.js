import React, { useState } from 'react';
import { Amplify } from 'aws-amplify';
import { Authenticator } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';
import './App.css';
import awsConfig from './aws-config';
import Header from './components/Header';
import TabBar from './components/TabBar';
import LambdaTab from './components/LambdaTab';

Amplify.configure(awsConfig);

function App() {
  const [activeTab, setActiveTab] = useState('lambda');

  return (
    <Authenticator>
      {({ signOut, user }) => (
        <div className="App">
          <Header user={user} onSignOut={signOut} />
          
          <TabBar activeTab={activeTab} onTabChange={setActiveTab} />

          <div className="content">
            {activeTab === 'lambda' && <LambdaTab />}
            
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
