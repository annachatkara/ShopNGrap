// Post operations logic
// ...implement post operations logic here...
const { prisma } = require('../config/database');
const { catchAsync, AppError } = require('../middleware/errorHandler');
const { logger } = require('../middleware/logger');

class PostController {
  // Create a new post
  createPost = catchAsync(async (req, res, next) => {
    const { title, content, imageUrls = [], videoUrl, tagIds = [] } = req.body;
    const authorId = req.user.id;

    // Create post with tags
    const post = await prisma.post.create({
      data: {
        title,
        content,
        imageUrls,
        videoUrl,
        authorId,
        publishedAt: new Date(),
        tags: {
          create: tagIds.map(tagId => ({
            tag: { connect: { id: tagId } }
          }))
        }
      },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            firstName: true,
            lastName: true,
            profileImageUrl: true
          }
        },
        tags: {
          include: {
            tag: {
              select: {
                id: true,
                name: true,
                slug: true,
                color: true
              }
            }
          }
        },
        _count: {
          select: {
            likes: true,
            comments: true
          }
        }
      }
    });

    // Update tag usage count
    if (tagIds.length > 0) {
      await prisma.tag.updateMany({
        where: { id: { in: tagIds } },
        data: { usageCount: { increment: 1 } }
      });
    }

    logger.info(`Post created by user ${authorId}`, { postId: post.id });

    res.status(201).json({
      success: true,
      message: 'Post created successfully',
      data: { post }
    });
  });

  // Get all posts (feed)
  getPosts = catchAsync(async (req, res, next) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const search = req.query.search || '';
    const tag = req.query.tag || '';
    const authorId = req.query.authorId || '';
    const skip = (page - 1) * limit;
    const currentUserId = req.user?.id;

    const whereClause = {
      isPublished: true,
      isDeleted: false,
      ...(search && {
        OR: [
          { title: { contains: search, mode: 'insensitive' } },
          { content: { contains: search, mode: 'insensitive' } }
        ]
      }),
      ...(authorId && { authorId }),
      ...(tag && {
        tags: {
          some: {
            tag: {
              OR: [
                { name: { equals: tag, mode: 'insensitive' } },
                { slug: { equals: tag, mode: 'insensitive' } }
              ]
            }
          }
        }
      })
    };

    const [posts, total] = await Promise.all([
      prisma.post.findMany({
        where: whereClause,
        include: {
          author: {
            select: {
              id: true,
              username: true,
              firstName: true,
              lastName: true,
              profileImageUrl: true
            }
          },
          tags: {
            include: {
              tag: {
                select: {
                  id: true,
                  name: true,
                  slug: true,
                  color: true
                }
              }
            }
          },
          _count: {
            select: {
              likes: true,
              comments: true
            }
          },
          ...(currentUserId && {
            likes: {
              where: { userId: currentUserId },
              select: { id: true }
            }
          })
        },
        skip,
        take: limit,
        orderBy: [
          { isPinned: 'desc' },
          { createdAt: 'desc' }
        ]
      }),
      prisma.post.count({ where: whereClause })
    ]);

    // Add isLiked field
    const postsWithLikes = posts.map(post => ({
      ...post,
      isLiked: currentUserId ? post.likes?.length > 0 : false,
      likes: undefined // Remove the likes array, we only need the count
    }));

    res.json({
      success: true,
      data: {
        posts: postsWithLikes,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  });

  // Get post by ID
  getPostById = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const currentUserId = req.user?.id;

    const post = await prisma.post.findFirst({
      where: {
        id,
        isDeleted: false
      },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            firstName: true,
            lastName: true,
            profileImageUrl: true
          }
        },
        tags: {
          include: {
            tag: {
              select: {
                id: true,
                name: true,
                slug: true,
                color: true
              }
            }
          }
        },
        comments: {
          where: {
            isDeleted: false,
            parentId: null // Only top-level comments
          },
          include: {
            author: {
              select: {
                id: true,
                username: true,
                firstName: true,
                lastName: true,
                profileImageUrl: true
              }
            },
            replies: {
              where: { isDeleted: false },
              include: {
                author: {
                  select: {
                    id: true,
                    username: true,
                    firstName: true,
                    lastName: true,
                    profileImageUrl: true
                  }
                },
                _count: {
                  select: { likes: true }
                }
              },
              orderBy: { createdAt: 'asc' }
            },
            _count: {
              select: {
                likes: true,
                replies: true
              }
            }
          },
          orderBy: { createdAt: 'desc' },
          take: 5 // Limit initial comments
        },
        _count: {
          select: {
            likes: true,
            comments: { where: { isDeleted: false } }
          }
        },
        ...(currentUserId && {
          likes: {
            where: { userId: currentUserId },
            select: { id: true }
          }
        })
      }
    });

    if (!post) {
      return next(new AppError('Post not found', 404));
    }

    // Increment view count
    await prisma.post.update({
      where: { id },
      data: { viewCount: { increment: 1 } }
    });

    const postWithLikes = {
      ...post,
      isLiked: currentUserId ? post.likes?.length > 0 : false,
      likes: undefined
    };

    res.json({
      success: true,
      data: { post: postWithLikes }
    });
  });

  // Update post
  updatePost = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const { title, content, imageUrls, videoUrl, tagIds = [] } = req.body;
    const userId = req.user.id;

    // Check if post exists and user owns it
    const existingPost = await prisma.post.findFirst({
      where: { id, authorId: userId, isDeleted: false }
    });

    if (!existingPost) {
      return next(new AppError('Post not found or access denied', 404));
    }

    // Update post with new tags
    const post = await prisma.$transaction(async (prisma) => {
      // Remove existing tags
      await prisma.postTag.deleteMany({
        where: { postId: id }
      });

      // Update post and add new tags
      return await prisma.post.update({
        where: { id },
        data: {
          title,
          content,
          imageUrls,
          videoUrl,
          tags: {
            create: tagIds.map(tagId => ({
              tag: { connect: { id: tagId } }
            }))
          }
        },
        include: {
          author: {
            select: {
              id: true,
              username: true,
              firstName: true,
              lastName: true,
              profileImageUrl: true
            }
          },
          tags: {
            include: {
              tag: {
                select: {
                  id: true,
                  name: true,
                  slug: true,
                  color: true
                }
              }
            }
          },
          _count: {
            select: {
              likes: true,
              comments: true
            }
          }
        }
      });
    });

    logger.info(`Post updated by user ${userId}`, { postId: id });

    res.json({
      success: true,
      message: 'Post updated successfully',
      data: { post }
    });
  });

  // Delete post (soft delete)
  deletePost = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const userId = req.user.id;

    const post = await prisma.post.findFirst({
      where: { id, authorId: userId, isDeleted: false }
    });

    if (!post) {
      return next(new AppError('Post not found or access denied', 404));
    }

    await prisma.post.update({
      where: { id },
      data: {
        isDeleted: true,
        deletedAt: new Date()
      }
    });

    logger.info(`Post deleted by user ${userId}`, { postId: id });

    res.json({
      success: true,
      message: 'Post deleted successfully'
    });
  });

  // Like/Unlike post
  toggleLike = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const userId = req.user.id;

    // Check if post exists
    const post = await prisma.post.findFirst({
      where: { id, isDeleted: false },
      select: { id: true, authorId: true }
    });

    if (!post) {
      return next(new AppError('Post not found', 404));
    }

    // Check if already liked
    const existingLike = await prisma.like.findFirst({
      where: { userId, postId: id }
    });

    let isLiked;
    if (existingLike) {
      // Unlike
      await prisma.like.delete({
        where: { id: existingLike.id }
      });
      isLiked = false;
      logger.info(`Post unliked by user ${userId}`, { postId: id });
    } else {
      // Like
      await prisma.like.create({
        data: { userId, postId: id }
      });
      isLiked = true;

      // Create notification for post author (if not self-like)
      if (post.authorId !== userId) {
        await prisma.notification.create({
          data: {
            userId: post.authorId,
            type: 'LIKE',
            title: 'New Like',
            message: `${req.user.firstName} ${req.user.lastName} liked your post`,
            relatedUserId: userId,
            relatedPostId: id
          }
        });
      }

      logger.info(`Post liked by user ${userId}`, { postId: id });
    }

    // Get updated like count
    const likeCount = await prisma.like.count({
      where: { postId: id }
    });

    res.json({
      success: true,
      message: isLiked ? 'Post liked' : 'Post unliked',
      data: {
        isLiked,
        likeCount
      }
    });
  });

  // Pin/Unpin post
  togglePin = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const userId = req.user.id;

    const post = await prisma.post.findFirst({
      where: { id, authorId: userId, isDeleted: false }
    });

    if (!post) {
      return next(new AppError('Post not found or access denied', 404));
    }

    const updatedPost = await prisma.post.update({
      where: { id },
      data: { isPinned: !post.isPinned }
    });

    logger.info(`Post ${post.isPinned ? 'unpinned' : 'pinned'} by user ${userId}`, { postId: id });

    res.json({
      success: true,
      message: `Post ${updatedPost.isPinned ? 'pinned' : 'unpinned'} successfully`,
      data: { isPinned: updatedPost.isPinned }
    });
  });

  // Get user's posts
  getUserPosts = catchAsync(async (req, res, next) => {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    const currentUserId = req.user?.id;

    const [posts, total] = await Promise.all([
      prisma.post.findMany({
        where: {
          authorId: userId,
          isDeleted: false,
          isPublished: true
        },
        include: {
          author: {
            select: {
              id: true,
              username: true,
              firstName: true,
              lastName: true,
              profileImageUrl: true
            }
          },
          tags: {
            include: {
              tag: {
                select: {
                  id: true,
                  name: true,
                  slug: true,
                  color: true
                }
              }
            }
          },
          _count: {
            select: {
              likes: true,
              comments: true
            }
          },
          ...(currentUserId && {
            likes: {
              where: { userId: currentUserId },
              select: { id: true }
            }
          })
        },
        skip,
        take: limit,
        orderBy: [
          { isPinned: 'desc' },
          { createdAt: 'desc' }
        ]
      }),
      prisma.post.count({
        where: {
          authorId: userId,
          isDeleted: false,
          isPublished: true
        }
      })
    ]);

    const postsWithLikes = posts.map(post => ({
      ...post,
      isLiked: currentUserId ? post.likes?.length > 0 : false,
      likes: undefined
    }));

    res.json({
      success: true,
      data: {
        posts: postsWithLikes,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  });
}

module.exports = new PostController();
