/**
 * Guest model.
 *
 * A guest is not a User.
 * Every guest session gets its own MongoDB document and MongoDB generates
 * the unique _id automatically.
 *
 * The createdAt field has a MongoDB TTL index. This means MongoDB can
 * automatically remove old guest sessions after the retention period.
 */

const mongoose = require('mongoose');

const retentionDays = Number(process.env.GUEST_RETENTION_DAYS || 7);
const retentionSeconds = retentionDays * 24 * 60 * 60;

const guestSchema = new mongoose.Schema({
  // MongoDB TTL removes the document after this many seconds.
  createdAt: {
    type: Date,
    default: Date.now,
    expires: retentionSeconds,
    index: true
  }
});

module.exports = mongoose.model('Guest', guestSchema);
