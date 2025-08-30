const { prisma } = require('../config/database');
const { AppError } = require('./errorHandler');

const checkVerified = async (req, res, next) => {
  try {
    if (!req.user || !req.user.id) {
      return next(new AppError('User not authenticated', 401));
    }

    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { id: true, isVerified: true }
    });

    if (!user) {
      return next(new AppError('User not found', 404));
    }

    if (!user.isVerified) {
      return next(new AppError('User not verified via OTP', 403));
    }

    // Proceed if verified
    next();
  } catch (error) {
    next(error);
  }
};

module.exports = checkVerified;
