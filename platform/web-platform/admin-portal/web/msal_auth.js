// Microsoft Entra browser authentication for the BC Eats Admin Flutter web app.
// MSAL Browser v2 is used because Microsoft no longer hosts v3+ on its CDN.
window.bcMicrosoftLogin = async function(clientId, authority) {
  if (!window.msal || !window.msal.PublicClientApplication) {
    throw new Error('Microsoft authentication library did not load. Check internet access or the MSAL script URL.');
  }
  const app = new window.msal.PublicClientApplication({
    auth: { clientId: clientId, authority: authority, redirectUri: window.location.origin },
    cache: { cacheLocation: 'sessionStorage', storeAuthStateInCookie: false }
  });
  const scopes = ['api://' + clientId + '/access_as_user'];
  const result = await app.loginPopup({ scopes: scopes });
  if (!result || !result.accessToken) {
    throw new Error('Microsoft did not return an API access token. Check the app registration and API scope.');
  }
  return result.accessToken;
};
