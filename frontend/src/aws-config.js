const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'us-east-1_6vAtz1rGj',
      userPoolClientId: '7on0nrn3hie7e1s9ra2rsn5v96',
      loginWith: {
        email: true,
      },
      signUpVerificationMethod: 'code',
      userAttributes: {
        email: {
          required: true,
        },
      },
      allowGuestAccess: false,
      passwordFormat: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireNumbers: true,
        requireSpecialCharacters: false,
      },
    },
  },
};

export default awsConfig;
