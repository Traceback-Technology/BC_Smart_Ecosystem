/**
 * Navigation controller.
 *
 * Navigation can be used by registered users and guests.
 * A registered user's routes are linked with userId.
 * A guest's routes are linked with guestId.
 */

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
