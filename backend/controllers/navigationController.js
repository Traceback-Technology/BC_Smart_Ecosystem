/**
 * Navigation controller.
 *
 * Navigation can be used by registered users and guests.
 * A registered user's routes are linked with userId.
 * A guest's routes are linked with guestId.
 */

const mongoose = require('mongoose');
const Route = require('../models/routeModel');

function estimate(origin, destination) {
  const seed = ((origin || '').length + (destination || '').length) % 8;

  return {
    estimatedMinutes: 8 + seed,
    distanceKm: Number((0.8 + seed * 0.2).toFixed(1))
  };
}

function getRouteOwner(req) {
  if (req.user?.guestId) {
    return { guestId: req.user.guestId };
  }

  return { userId: req.user.userId };
}

exports.preview = async (req, res, next) => {
  try {
    const origin = req.body.origin || req.body.pickupLocation?.address;
    const destination = req.body.destination || req.body.destinationLocation?.address;

    if (!origin || !destination) {
      return res.status(400).json({
        success: false,
        message: 'Origin and destination are required'
      });
    }

    const metrics = estimate(origin, destination);
    const owner = getRouteOwner(req);

    const route = await Route.create({
      ...owner,
      origin,
      destination,
      pickupLocation: req.body.pickupLocation,
      destinationLocation: req.body.destinationLocation,
      ...metrics
    });

    return res.status(201).json({
      success: true,
      data: route
    });
  } catch (error) {
    return next(error);
  }
};

exports.start = async (req, res, next) => {
  try {
    const owner = getRouteOwner(req);

    const route = await Route.findOneAndUpdate(
      {
        _id: req.params.id,
        ...owner
      },
      { status: 'active' },
      { new: true }
    );

    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found'
      });
    }

    return res.json({
      success: true,
      message: 'Navigation started',
      data: route
    });
  } catch (error) {
    return next(error);
  }
};

exports.getRoute = async (req, res, next) => {
  try {
    const owner = getRouteOwner(req);

    const route = await Route.findOne({
      _id: req.params.id,
      ...owner
    }).populate('droneId orderId');

    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found'
      });
    }

    return res.json({
      success: true,
      data: route
    });
  } catch (error) {
    return next(error);
  }
};

exports.getUserRoutes = async (req, res, next) => {
  try {
    const owner = getRouteOwner(req);
    const data = await Route.find(owner).sort({ createdAt: -1 });

    return res.json({
      success: true,
      data
    });
  } catch (error) {
    return next(error);
  }
};

// ---------------------------------------------------------------------------
// Route history (BC Ways)
//
// The phone calculates routes locally, so it reports the real distance and
// time here when navigation starts, then marks the route completed/cancelled.
// ---------------------------------------------------------------------------

const HISTORY_STATUSES = ['active', 'completed', 'cancelled'];

function cleanText(value, max = 120) {
  return typeof value === 'string' ? value.trim().slice(0, max) : '';
}

function finiteNumber(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }

  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

// Walking routes only: delivery routes carry a drone or order reference.
function walkingRoutes(owner) {
  return { ...owner, droneId: null, orderId: null };
}

exports.recordHistory = async (req, res, next) => {
  try {
    const origin = cleanText(req.body.origin);
    const destination = cleanText(req.body.destination);
    const distanceMeters = finiteNumber(req.body.distanceMeters);
    const minutes = finiteNumber(req.body.estimatedMinutes);

    if (!origin || !destination) {
      return res.status(400).json({
        success: false,
        message: 'Origin and destination are required'
      });
    }

    if (distanceMeters === null || distanceMeters < 0 || distanceMeters > 50000) {
      return res.status(400).json({
        success: false,
        message: 'A valid distanceMeters is required'
      });
    }

    if (minutes === null || minutes < 0 || minutes > 600) {
      return res.status(400).json({
        success: false,
        message: 'A valid estimatedMinutes is required'
      });
    }

    const owner = getRouteOwner(req);

    // Only one route can be in progress at a time: close any that was left active.
    await Route.updateMany(
      { ...walkingRoutes(owner), status: 'active' },
      { status: 'cancelled', endedAt: new Date() }
    );

    const route = await Route.create({
      ...owner,
      origin,
      destination,
      originNodeId: cleanText(req.body.originNodeId, 60) || undefined,
      destinationNodeId: cleanText(req.body.destinationNodeId, 60) || undefined,
      distanceKm: Number((distanceMeters / 1000).toFixed(3)),
      estimatedMinutes: Math.max(1, Math.round(minutes)),
      status: 'active'
    });

    return res.status(201).json({
      success: true,
      data: route
    });
  } catch (error) {
    return next(error);
  }
};

exports.updateHistoryStatus = async (req, res, next) => {
  try {
    const { status } = req.body;

    if (!['completed', 'cancelled'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Status must be completed or cancelled'
      });
    }

    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(404).json({
        success: false,
        message: 'Active route not found'
      });
    }

    const route = await Route.findOneAndUpdate(
      {
        _id: req.params.id,
        ...walkingRoutes(getRouteOwner(req)),
        status: 'active'
      },
      { status, endedAt: new Date() },
      { new: true }
    );

    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Active route not found'
      });
    }

    return res.json({
      success: true,
      data: route
    });
  } catch (error) {
    return next(error);
  }
};

exports.listHistory = async (req, res, next) => {
  try {
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 50);
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);

    const filter = {
      ...walkingRoutes(getRouteOwner(req)),
      status: { $in: HISTORY_STATUSES }
    };

    const [data, total] = await Promise.all([
      Route.find(filter)
        .select('origin destination originNodeId destinationNodeId distanceKm estimatedMinutes status createdAt endedAt')
        .sort({ createdAt: -1, _id: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      Route.countDocuments(filter)
    ]);

    return res.json({
      success: true,
      data,
      pagination: { page, limit, total, hasMore: page * limit < total }
    });
  } catch (error) {
    return next(error);
  }
};
