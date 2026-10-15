const { hash, compare } = require('bcryptjs');
exports.doHash = (value, salt = 12) => hash(value, salt);
exports.doHashValidation = (value, hashedValue) => compare(value, hashedValue);
