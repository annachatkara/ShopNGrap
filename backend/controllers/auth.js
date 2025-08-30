// Authentication logic
// ...implement authentication logic here...
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { prisma } = require('../config/database');
const { catchAsync, AppError } = require('../middleware/errorHandler');
const { generateToken, generateRefreshToken } = require('../middleware/auth');
const { logger } = require('../middleware/logger');

class AuthController {
  // Register new user
  register = catchAsync(async (req, res, next) => {
    const { email, password, firstName, lastName, username, phoneNumber } = req.body;

    // Check if user already exists
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { email },
          ...(username ? [{ username }] : [])
        ]
      }
    });

    if (existingUser) {
      if (existingUser.email === email) {
        return next(new AppError('User with this email already exists', 409));
      }
      if (existingUser.username === username) {
        return next(new AppError('Username is already taken', 409));
      }
    }

    // Hash password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        firstName,
        lastName,
        username,
        phoneNumber,
        userPreferences: {
          create: {} // Create default preferences
        }
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        username: true,
        isEmailVerified: true,
        createdAt: true
      }
    });

    // Generate tokens
    const tokenPayload = { userId: user.id, email: user.email };
    const token = generateToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    // Create session
    await prisma.userSession.create({
      data: {
        userId: user.id,
        sessionToken: token,
        refreshToken,
        deviceInfo: req.get('User-Agent'),
        ipAddress: req.ip,
        userAgent: req.get('User-Agent'),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
      }
    });

    logger.info(`New user registered: ${email}`, { userId: user.id });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user,
        tokens: {
          accessToken: token,
          refreshToken,
          expiresIn: '7d'
        }
      }
    });
  });

  // Login user
  login = catchAsync(async (req, res, next) => {
    const { email, password, rememberMe = false } = req.body;

    // Find user with password
    const user = await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        username: true,
        passwordHash: true,
        isActive: true,
        isEmailVerified: true,
        lastLoginAt: true
      }
    });

    if (!user || !await bcrypt.compare(password, user.passwordHash)) {
      return next(new AppError('Invalid email or password', 401));
    }

    if (!user.isActive) {
      return next(new AppError('Account is deactivated. Please contact support.', 403));
    }

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() }
    });

    // Generate tokens
    const tokenPayload = { userId: user.id, email: user.email };
    const expiresIn = rememberMe ? '30d' : '7d';
    const token = generateToken({ ...tokenPayload, rememberMe });
    const refreshToken = generateRefreshToken(tokenPayload);

    // Deactivate old sessions (optional, for security)
    await prisma.userSession.updateMany({
      where: { userId: user.id, isActive: true },
      data: { isActive: false }
    });

    // Create new session
    await prisma.userSession.create({
      data: {
        userId: user.id,
        sessionToken: token,
        refreshToken,
        deviceInfo: req.get('User-Agent'),
        ipAddress: req.ip,
        userAgent: req.get('User-Agent'),
        expiresAt: new Date(Date.now() + (rememberMe ? 30 : 7) * 24 * 60 * 60 * 1000)
      }
    });

    // Remove password from output
    const { passwordHash, ...userWithoutPassword } = user;

    logger.info(`User logged in: ${email}`, { userId: user.id });

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: userWithoutPassword,
        tokens: {
          accessToken: token,
          refreshToken,
          expiresIn
        }
      }
    });
  });

  // Logout user
  logout = catchAsync(async (req, res, next) => {
    const { sessionToken } = req.session || {};

    if (sessionToken) {
      // Deactivate session
      await prisma.userSession.updateMany({
        where: { sessionToken, isActive: true },
        data: { isActive: false }
      });
    }

    logger.info(`User logged out: ${req.user.email}`, { userId: req.user.id });

    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  });

  // Refresh token
  refreshToken = catchAsync(async (req, res, next) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return next(new AppError('Refresh token is required', 400));
    }

    // Find session with refresh token
    const session = await prisma.userSession.findFirst({
      where: {
        refreshToken,
        isActive: true,
        expiresAt: { gt: new Date() }
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            username: true,
            isActive: true
          }
        }
      }
    });

    if (!session || !session.user.isActive) {
      return next(new AppError('Invalid or expired refresh token', 401));
    }

    // Generate new tokens
    const tokenPayload = { userId: session.user.id, email: session.user.email };
    const newAccessToken = generateToken(tokenPayload);
    const newRefreshToken = generateRefreshToken(tokenPayload);

    // Update session
    await prisma.userSession.update({
      where: { id: session.id },
      data: {
        sessionToken: newAccessToken,
        refreshToken: newRefreshToken,
        lastUsedAt: new Date()
      }
    });

    res.json({
      success: true,
      message: 'Tokens refreshed successfully',
      data: {
        user: session.user,
        tokens: {
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          expiresIn: '7d'
        }
      }
    });
  });

  // Request password reset
  requestPasswordReset = catchAsync(async (req, res, next) => {
    const { email } = req.body;

    const user = await prisma.user.findUnique({
      where: { email },
      select: { id: true, email: true, firstName: true }
    });

    if (!user) {
      // Don't reveal if email exists
      return res.json({
        success: true,
        message: 'If an account with that email exists, you will receive a password reset link.'
      });
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const hashedToken = crypto.createHash('sha256').update(resetToken).digest('hex');

    // Store reset token
    await prisma.passwordReset.create({
      data: {
        userId: user.id,
        token: hashedToken,
        expiresAt: new Date(Date.now() + 15 * 60 * 1000) // 15 minutes
      }
    });

    // TODO: Send email with reset link
    // For now, just log it (in production, use email service)
    logger.info(`Password reset requested for: ${email}`, {
      userId: user.id,
      resetToken: resetToken // Remove this in production
    });

    res.json({
      success: true,
      message: 'If an account with that email exists, you will receive a password reset link.',
      // Remove this in production
      ...(process.env.NODE_ENV === 'development' && { resetToken })
    });
  });

  // Reset password
  resetPassword = catchAsync(async (req, res, next) => {
    const { token, password } = req.body;

    if (!token || !password) {
      return next(new AppError('Token and password are required', 400));
    }

    // Hash the token
    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');

    // Find valid reset token
    const passwordReset = await prisma.passwordReset.findFirst({
      where: {
        token: hashedToken,
        isUsed: false,
        expiresAt: { gt: new Date() }
      },
      include: {
        user: { select: { id: true, email: true } }
      }
    });

    if (!passwordReset) {
      return next(new AppError('Invalid or expired reset token', 400));
    }

    // Hash new password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Update password and mark token as used
    await prisma.$transaction([
      prisma.user.update({
        where: { id: passwordReset.userId },
        data: { passwordHash }
      }),
      prisma.passwordReset.update({
        where: { id: passwordReset.id },
        data: { isUsed: true, usedAt: new Date() }
      }),
      // Deactivate all sessions for security
      prisma.userSession.updateMany({
        where: { userId: passwordReset.userId },
        data: { isActive: false }
      })
    ]);

    logger.info(`Password reset successful for: ${passwordReset.user.email}`, {
      userId: passwordReset.userId
    });

    res.json({
      success: true,
      message: 'Password reset successful. Please log in with your new password.'
    });
  });

  // Change password (for authenticated users)
  changePassword = catchAsync(async (req, res, next) => {
    const { currentPassword, password: newPassword } = req.body;
    const userId = req.user.id;

    // Get user with current password
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { passwordHash: true, email: true }
    });

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isCurrentPasswordValid) {
      return next(new AppError('Current password is incorrect', 400));
    }

    // Hash new password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    await prisma.user.update({
      where: { id: userId },
      data: { passwordHash }
    });

    logger.info(`Password changed for user: ${user.email}`, { userId });

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  });

  // Get current user profile
  getProfile = catchAsync(async (req, res, next) => {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        username: true,
        firstName: true,
        lastName: true,
        phoneNumber: true,
        dateOfBirth: true,
        profileImageUrl: true,
        isEmailVerified: true,
        createdAt: true,
        lastLoginAt: true,
        userPreferences: {
          select: {
            emailNotifications: true,
            pushNotifications: true,
            smsNotifications: true,
            profileVisibility: true,
            language: true,
            timezone: true,
            theme: true
          }
        },
        _count: {
          select: {
            posts: true,
            followers: true,
            follows: true
          }
        }
      }
    });

    res.json({
      success: true,
      data: { user }
    });
  });
}

module.exports = new AuthController();
