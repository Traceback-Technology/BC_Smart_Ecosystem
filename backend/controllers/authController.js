/**
 * Authentication controller.
 *
 * This controller handles HTTP requests for:
 * - normal email/password accounts
 * - Microsoft student login
 * - the public Microsoft configuration endpoint
 *
 * Guest sessions are handled by the dedicated guest controller.
 * This keeps each authentication flow focused on one responsibility.
 */

const User = require('../models/usersModel');
const { signupSchema, signinSchema } = require('../middlewares/validator');
const { doHash, doHashValidation } = require('../utils/hashing');
const { makeUserToken } = require('../utils/tokens');

function makeToken(user) {
  return makeUserToken(user);
}

function classifyCampusAccount(email) {
  const value = String(email || '').trim().toLowerCase();

  if (/^\d{6}@student\.belgiumcampus\.ac\.za$/.test(value)) {
    return 'student';
  }

  if (/^[a-z][a-z0-9._-]*@belgiumcampus\.ac\.za$/.test(value)) {
    return 'staff';
  }

  return 'unclassified';
}

function safeUser(user) {
  return {
    id: user._id,
    name: user.name,
    fullName: user.fullName,
    email: user.email,
    phone: user.phone,
    role: user.role,
    accountType: user.accountType || 'unclassified',
    verified: user.verified
  };
}

function getMicrosoftConfiguration() {
  const clientId = String(process.env.MICROSOFT_CLIENT_ID || '').trim();
  const authority = String(process.env.MICROSOFT_AUTHORITY || '')
    .trim()
    .replace(/\/$/, '');

  return { clientId, authority };
}

function validateMicrosoftConfiguration(clientId, authority) {
  if (!clientId || !authority) {
    return 'Microsoft authentication is not configured. Set MICROSOFT_CLIENT_ID and MICROSOFT_AUTHORITY in the backend .env file.';
  }

  if (!/^https:\/\/login\.microsoftonline\.com\/common$/i.test(authority)) {
    return 'MICROSOFT_AUTHORITY must be https://login.microsoftonline.com/common';
  }

  return null;
}

exports.microsoftConfig = (req, res) => {
  const configuration = getMicrosoftConfiguration();
  const error = validateMicrosoftConfiguration(
    configuration.clientId,
    configuration.authority
  );

  if (error) {
    return res.status(500).json({
      success: false,
      message: error
    });
  }

  return res.json({
    success: true,
    data: configuration
  });
};

exports.signup = async (req, res, next) => {
  try {
    const { error, value } = signupSchema.validate(req.body);

    if (error) {
      return res.status(400).json({
        success: false,
        message: error.details[0].message
      });
    }

    const email = value.email.toLowerCase();
    const existingUser = await User.findOne({ email });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'Email already in use'
      });
    }

    const password = await doHash(value.password);
    const user = await User.create({
      ...value,
      email,
      password
    });

    const token = makeToken(user);

    return res.status(201).json({
      success: true,
      message: 'Account created',
      token,
      data: safeUser(user)
    });
  } catch (error) {
    return next(error);
  }
};

exports.signin = async (req, res, next) => {
  try {
    const { error, value } = signinSchema.validate(req.body);

    if (error) {
      return res.status(400).json({
        success: false,
        message: error.details[0].message
      });
    }

    const email = value.email.toLowerCase();
    const user = await User.findOne({ email }).select('+password');

    if (!user?.password) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const validPassword = await doHashValidation(value.password, user.password);

    if (!validPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const token = makeToken(user);

    res.cookie(
      'Authorization',
      `Bearer ${token}`,
      {
        httpOnly: true,
        sameSite: 'lax',
        secure: process.env.NODE_ENV === 'production',
        maxAge: 8 * 60 * 60 * 1000
      }
    );

    return res.json({
      success: true,
      token,
      data: safeUser(user)
    });
  } catch (error) {
    return next(error);
  }
};

exports.loginWithMicrosoft = async (req, res, next) => {
  try {
    const microsoftUser = req.microsoftUser;

    if (!microsoftUser?.email) {
      return res.status(401).json({
        success: false,
        message: 'Microsoft authentication failed'
      });
    }

    // This identity has already passed Microsoft token verification.
    if (microsoftUser.tenantId !== 'ea1a909b-6600-4a25-82a5-0c6ed7d0513b') {
      return res.status(403).json({
        success: false,
        message: 'Please sign in with your Belgium Campus Microsoft account.'
      });
    }

    const email = microsoftUser.email.trim().toLowerCase();
    const accountType = classifyCampusAccount(email);
    let user = await User.findOne({
      $or: [
        { microsoftId: microsoftUser.oid },
        { email }
      ]
    });

    if (!user) {
      user = await User.create({
        name: microsoftUser.name || email.split('@')[0],
        fullName: microsoftUser.name,
        email,
        microsoftId: microsoftUser.oid,
        tenantId: microsoftUser.tenantId,
        verified: true
      });
    }

    if (user.microsoftId !== microsoftUser.oid) {
      user.microsoftId = microsoftUser.oid;
    }

    if (user.tenantId !== microsoftUser.tenantId) {
      user.tenantId = microsoftUser.tenantId;
    }

    user.accountType = accountType;
    user.verified = true;

    await user.save();

    const token = makeToken(user);

    return res.json({
      success: true,
      message: 'Microsoft login successful',
      token,
      data: safeUser(user)
    });
  } catch (error) {
    return next(error);
  }
};

exports.signout = (req, res) => {
  res.clearCookie('Authorization');

  return res.json({
    success: true,
    message: 'Logged out'
  });
};

exports.me = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.userId)
      .select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    return res.json({
      success: true,
      data: user
    });
  } catch (error) {
    return next(error);
  }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const allowedFields = [
      'name',
      'fullName',
      'phone',
      'avatarUrl',
      'profileImage',
      'deliveryAddress',
      'addresses',
      'language',
      'theme',
      'notificationSettings'
    ];

    const changes = {};

    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        changes[field] = req.body[field];
      }
    }

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      changes,
      {
        new: true,
        runValidators: true
      }
    ).select('-password');

    return res.json({
      success: true,
      message: 'Profile updated',
      data: user
    });
  } catch (error) {
    return next(error);
  }
};

exports.makeToken = makeToken;
