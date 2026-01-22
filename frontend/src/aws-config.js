const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'us-east-1_QFETQOHxZ',
      userPoolClientId: '7a0btq8hbg64aflquk18jqmq2l',
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
