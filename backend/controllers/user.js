// User management logic
// ...implement user management logic here...
const { prisma } = require('../config/database');
const { catchAsync, AppError } = require('../middleware/errorHandler');
const { logger } = require('../middleware/logger');
const bcrypt = require('bcrypt');

class UserController {
  // Get all users (with pagination and search)
  getUsers = catchAsync(async (req, res, next) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const search = req.query.search || '';
    const skip = (page - 1) * limit;

    const whereClause = {
      isActive: true,
      ...(search && {
        OR: [
          { firstName: { contains: search, mode: 'insensitive' } },
          { lastName: { contains: search, mode: 'insensitive' } },
          { username: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } }
        ]
      })
    };

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where: whereClause,
        select: {
          id: true,
          email: true,
          username: true,
          firstName: true,
          lastName: true,
          profileImageUrl: true,
          createdAt: true,
          _count: {
            select: {
              posts: true,
              followers: true,
              follows: true
            }
          }
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' }
      }),
      prisma.user.count({ where: whereClause })
    ]);

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  });

  // Get user by ID
  getUserById = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const currentUserId = req.user?.id;

    const user = await prisma.user.findFirst({
      where: {
        id,
        isActive: true
      },
      select: {
        id: true,
        email: true,
        username: true,
        firstName: true,
        lastName: true,
        phoneNumber: currentUserId === id, // Only show phone if own profile
        dateOfBirth: currentUserId === id, // Only show DOB if own profile
        profileImageUrl: true,
        isEmailVerified: true,
        createdAt: true,
        lastLoginAt: currentUserId === id, // Only show last login if own profile
        userPreferences: currentUserId === id ? {
          select: {
            profileVisibility: true,
            language: true,
            theme: true
          }
        } : false,
        _count: {
          select: {
            posts: true,
            followers: true,
            follows: true
          }
        }
      }
    });

    if (!user) {
      return next(new AppError('User not found', 404));
    }

    // Check if current user is following this user
    let isFollowing = false;
    if (currentUserId && currentUserId !== id) {
      const followRelation = await prisma.follow.findFirst({
        where: {
          followerId: currentUserId,
          followingId: id
        }
      });
      isFollowing = !!followRelation;
    }

    res.json({
      success: true,
      data: {
        user: {
          ...user,
          isFollowing
        }
      }
    });
  });

  // Update user profile
  updateProfile = catchAsync(async (req, res, next) => {
    const userId = req.user.id;
    const {
      firstName,
      lastName,
      username,
      phoneNumber,
      dateOfBirth,
      profileImageUrl
    } = req.body;

    // Check if username is already taken (if provided and different)
    if (username) {
      const existingUser = await prisma.user.findFirst({
        where: {
          username,
          id: { not: userId }
        }
      });

      if (existingUser) {
        return next(new AppError('Username is already taken', 409));
      }
    }

    // Update user
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        firstName,
        lastName,
        username,
        phoneNumber,
        dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : undefined,
        profileImageUrl
      },
      select: {
        id: true,
        email: true,
        username: true,
        firstName: true,
        lastName: true,
        phoneNumber: true,
        dateOfBirth: true,
        profileImageUrl: true,
        updatedAt: true
      }
    });

    logger.info(`User profile updated: ${req.user.email}`, { userId });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: { user: updatedUser }
    });
  });

  // Update user preferences
  updatePreferences = catchAsync(async (req, res, next) => {
    const userId = req.user.id;
    const {
      emailNotifications,
      pushNotifications,
      smsNotifications,
      profileVisibility,
      allowMessaging,
      allowTagging,
      language,
      timezone,
      theme
    } = req.body;

    const updatedPreferences = await prisma.userPreferences.upsert({
      where: { userId },
      update: {
        emailNotifications,
        pushNotifications,
        smsNotifications,
        profileVisibility,
        allowMessaging,
        allowTagging,
        language,
        timezone,
        theme
      },
      create: {
        userId,
        emailNotifications,
        pushNotifications,
        smsNotifications,
        profileVisibility,
        allowMessaging,
        allowTagging,
        language,
        timezone,
        theme
      }
    });

    logger.info(`User preferences updated: ${req.user.email}`, { userId });

    res.json({
      success: true,
      message: 'Preferences updated successfully',
      data: { preferences: updatedPreferences }
    });
  });

  // Follow user
  followUser = catchAsync(async (req, res, next) => {
    const { id: targetUserId } = req.params;
    const currentUserId = req.user.id;

    if (currentUserId === targetUserId) {
      return next(new AppError('You cannot follow yourself', 400));
    }

    // Check if target user exists
    const targetUser = await prisma.user.findFirst({
      where: { id: targetUserId, isActive: true }
    });

    if (!targetUser) {
      return next(new AppError('User not found', 404));
    }

    // Check if already following
    const existingFollow = await prisma.follow.findFirst({
      where: {
        followerId: currentUserId,
        followingId: targetUserId
      }
    });

    if (existingFollow) {
      return next(new AppError('You are already following this user', 409));
    }

    // Create follow relationship
    await prisma.follow.create({
      data: {
        followerId: currentUserId,
        followingId: targetUserId
      }
    });

    // Create notification for the followed user
    await prisma.notification.create({
      data: {
        userId: targetUserId,
        type: 'FOLLOW',
        title: 'New Follower',
        message: `${req.user.firstName} ${req.user.lastName} started following you`,
        relatedUserId: currentUserId
      }
    });

    logger.info(`User ${currentUserId} followed user ${targetUserId}`);

    res.json({
      success: true,
      message: 'User followed successfully'
    });
  });

  // Unfollow user
  unfollowUser = catchAsync(async (req, res, next) => {
    const { id: targetUserId } = req.params;
    const currentUserId = req.user.id;

    const follow = await prisma.follow.findFirst({
      where: {
        followerId: currentUserId,
        followingId: targetUserId
      }
    });

    if (!follow) {
      return next(new AppError('You are not following this user', 404));
    }

    await prisma.follow.delete({
      where: { id: follow.id }
    });

    logger.info(`User ${currentUserId} unfollowed user ${targetUserId}`);

    res.json({
      success: true,
      message: 'User unfollowed successfully'
    });
  });

  // Get user's followers
  getFollowers = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const [followers, total] = await Promise.all([
      prisma.follow.findMany({
        where: { followingId: id },
        select: {
          follower: {
            select: {
              id: true,
              username: true,
              firstName: true,
              lastName: true,
              profileImageUrl: true,
              _count: {
                select: {
                  followers: true,
                  follows: true
                }
              }
            }
          },
          createdAt: true
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' }
      }),
      prisma.follow.count({ where: { followingId: id } })
    ]);

    res.json({
      success: true,
      data: {
        followers: followers.map(f => ({
          ...f.follower,
          followedAt: f.createdAt
        })),
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  });

  // Get user's following
  getFollowing = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const [following, total] = await Promise.all([
      prisma.follow.findMany({
        where: { followerId: id },
        select: {
          following: {
            select: {
              id: true,
              username: true,
              firstName: true,
              lastName: true,
              profileImageUrl: true,
              _count: {
                select: {
                  followers: true,
                  follows: true
                }
              }
            }
          },
          createdAt: true
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' }
      }),
      prisma.follow.count({ where: { followerId: id } })
    ]);

    res.json({
      success: true,
      data: {
        following: following.map(f => ({
          ...f.following,
          followedAt: f.createdAt
        })),
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  });

  // Deactivate account
  deactivateAccount = catchAsync(async (req, res, next) => {
    const userId = req.user.id;

    await prisma.$transaction([
      // Deactivate user
      prisma.user.update({
        where: { id: userId },
        data: { isActive: false }
      }),
      // Deactivate all sessions
      prisma.userSession.updateMany({
        where: { userId },
        data: { isActive: false }
      })
    ]);

    logger.info(`User account deactivated: ${req.user.email}`, { userId });

    res.json({
      success: true,
      message: 'Account deactivated successfully'
    });
  });
}

module.exports = new UserController();
