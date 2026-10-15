const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

/**
 * Microsoft Entra ID token verification.
 *
 * Only these Microsoft environment variables are required:
 *   MICROSOFT_CLIENT_ID
 *   MICROSOFT_AUTHORITY=https://login.microsoftonline.com/common
 *
 * MICROSOFT_AUTHORITY is used for Microsoft's tenant-independent JWKS
 * endpoint. The issuer is taken from the token's tenant (tid) and then
 * validated against the Microsoft authority host.
 */
const authority = String(process.env.MICROSOFT_AUTHORITY || '').replace(/\/$/, '');
const clientId = process.env.MICROSOFT_CLIENT_ID;

function getConfigError() {
  if (!clientId) return 'MICROSOFT_CLIENT_ID is not configured';
  if (!authority) return 'MICROSOFT_AUTHORITY is not configured';
  if (!/^https:\/\/login\.microsoftonline\.com\/common$/i.test(authority)) {
    return 'MICROSOFT_AUTHORITY must be https://login.microsoftonline.com/common';
  }
  return null;
}

function getJwksClient() {
  return jwksClient({
    jwksUri: `${authority}/discovery/v2.0/keys`,
    cache: true,
    rateLimit: true,
    jwksRequestsPerMinute: 10
  });
}

function getKey(client) {
  return (header, callback) => {
    if (!header?.kid) return callback(new Error('Microsoft token has no key id'));
    client.getSigningKey(header.kid, (err, key) => {
      if (err) return callback(err);
      callback(null, key.getPublicKey());
    });
  };
}

module.exports = (req, res, next) => {
  const configError = getConfigError();
  if (configError) {
    return res.status(500).json({
      success: false,
      message: `Microsoft authentication is not configured: ${configError}`
    });
  }

  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Microsoft Bearer token required'
    });
  }

  const token = header.slice(7).trim();
  if (!token) {
    return res.status(401).json({ success: false, message: 'Microsoft Bearer token required' });
  }

  // Decode only to discover the tenant-specific issuer. Signature validation
  // happens immediately afterwards with Microsoft's JWKS and the expected
  // client audience.
  const unverified = jwt.decode(token);
  const tenantId = unverified?.tid;
  const issuer = tenantId
    ? `${authority.replace(/\/common$/i, '')}/${tenantId}/v2.0`
    : null;

  if (!tenantId || !/^[0-9a-f-]{36}$/i.test(String(tenantId)) || !issuer) {
    return res.status(401).json({
      success: false,
      message: 'Invalid Microsoft token: tenant information is missing'
    });
  }

  const client = getJwksClient();
  jwt.verify(
    token,
    getKey(client),
    {
      algorithms: ['RS256'],
      issuer,
      audience: clientId
    },
    (err, decoded) => {
      if (err) {
        return res.status(401).json({
          success: false,
          message: 'Invalid Microsoft token'
        });
      }

      const email = String(
        decoded.preferred_username || decoded.email || decoded.upn || ''
      ).toLowerCase();

      if (!email || !decoded.oid) {
        return res.status(401).json({
          success: false,
          message: 'Microsoft token missing required claims'
        });
      }

      req.microsoftUser = {
        name: decoded.name || email.split('@')[0],
        email,
        oid: decoded.oid,
        tenantId: decoded.tid,
        raw: decoded
      };

      next();
    }
  );
};
