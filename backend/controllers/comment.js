// Comment management logic
// ...implement comment management logic here...
const { prisma } = require('../config/database');
const { catchAsync, AppError } = require('../middleware/errorHandler');
const { logger } = require('../middleware/logger');

class CommentController {
  // Create a new comment
  createComment = catchAsync(async (req, res, next) => {
    const { postId } = req.params;
    const { content, parentId } = req.body;
    const authorId = req.user.id;

    // Check if post exists
    const post = await prisma.post.findFirst({
      where: { id: postId, isDeleted: false },
      select: { id: true, authorId: true }
    });

    if (!post) {
      return next(new AppError('Post not found', 404));
    }

    // If parentId is provided, check if parent comment exists
    if (parentId) {
      const parentComment = await prisma.comment.findFirst({
        where: { id: parentId, postId, isDeleted: false }
      });

      if (!parentComment) {
        return next(new AppError('Parent comment not found', 404));
      }
    }

    // Create comment
    const comment = await prisma.comment.create({
      data: {
        content,
        postId,
        authorId,
        parentId
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
        _count: {
          select: {
            likes: true,
            replies: true
          }
        }
      }
    });

    // Create notification for post author (if not commenting on own post)
    if (post.authorId !== authorId) {
      await prisma.notification.create({
        data: {
          userId: post.authorId,
          type: 'COMMENT',
          title: 'New Comment',
          message: `${req.user.firstName} ${req.user.lastName} commented on your post`,
          relatedUserId: authorId,
          relatedPostId: postId
        }
      });
    }

    logger.info(`Comment created by user ${authorId} on post ${postId}`, { commentId: comment.id });

    res.status(201).json({
      success: true,
      message: 'Comment created successfully',
      data: { comment }
    });
  });

  // Get comments for a post
  getPostComments = catchAsync(async (req, res, next) => {
    const { postId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const currentUserId = req.user?.id;

    // Check if post exists
    const post = await prisma.post.findFirst({
      where: { id: postId, isDeleted: false },
      select: { id: true }
    });

    if (!post) {
      return next(new AppError('Post not found', 404));
    }

    const [comments, total] = await Promise.all([
      prisma.comment.findMany({
        where: {
          postId,
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
              },
              ...(currentUserId && {
                likes: {
                  where: { userId: currentUserId },
                  select: { id: true }
                }
              })
            },
            orderBy: { createdAt: 'asc' },
            take: 3 // Limit replies per comment
          },
          _count: {
            select: {
              likes: true,
              replies: { where: { isDeleted: false } }
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
        orderBy: { createdAt: 'desc' }
      }),
      prisma.comment.count({
        where: {
          postId,
          isDeleted: false,
          parentId: null
        }
      })
    ]);

    // Add isLiked field
    const commentsWithLikes = comments.map(comment => ({
      ...comment,
      isLiked: currentUserId ? comment.likes?.length > 0 : false,
      likes: undefined,
      replies: comment.replies.map(reply => ({
        ...reply,
        isLiked: currentUserId ? reply.likes?.length > 0 : false,
        likes: undefined
      }))
    }));

    res.json({
      success: true,
      data: {
        comments: commentsWithLikes,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  });

  // Get replies for a comment
  getCommentReplies = catchAsync(async (req, res, next) => {
    const { commentId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    const currentUserId = req.user?.id;

    const [replies, total] = await Promise.all([
      prisma.comment.findMany({
        where: {
          parentId: commentId,
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
          _count: {
            select: { likes: true }
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
        orderBy: { createdAt: 'asc' }
      }),
      prisma.comment.count({
        where: {
          parentId: commentId,
          isDeleted: false
        }
      })
    ]);

    const repliesWithLikes = replies.map(reply => ({
      ...reply,
      isLiked: currentUserId ? reply.likes?.length > 0 : false,
      likes: undefined
    }));

    res.json({
      success: true,
      data: {
        replies: repliesWithLikes,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  });

  // Update comment
  updateComment = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const { content } = req.body;
    const userId = req.user.id;

    const comment = await prisma.comment.findFirst({
      where: { id, authorId: userId, isDeleted: false }
    });

    if (!comment) {
      return next(new AppError('Comment not found or access denied', 404));
    }

    const updatedComment = await prisma.comment.update({
      where: { id },
      data: { content },
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
          select: {
            likes: true,
            replies: true
          }
        }
      }
    });

    logger.info(`Comment updated by user ${userId}`, { commentId: id });

    res.json({
      success: true,
      message: 'Comment updated successfully',
      data: { comment: updatedComment }
    });
  });

  // Delete comment (soft delete)
  deleteComment = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const userId = req.user.id;

    const comment = await prisma.comment.findFirst({
      where: { id, authorId: userId, isDeleted: false }
    });

    if (!comment) {
      return next(new AppError('Comment not found or access denied', 404));
    }

    await prisma.comment.update({
      where: { id },
      data: {
        isDeleted: true,
        deletedAt: new Date()
      }
    });

    logger.info(`Comment deleted by user ${userId}`, { commentId: id });

    res.json({
      success: true,
      message: 'Comment deleted successfully'
    });
  });

  // Like/Unlike comment
  toggleLike = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const userId = req.user.id;

    // Check if comment exists
    const comment = await prisma.comment.findFirst({
      where: { id, isDeleted: false },
      select: { id: true, authorId: true, postId: true }
    });

    if (!comment) {
      return next(new AppError('Comment not found', 404));
    }

    // Check if already liked
    const existingLike = await prisma.like.findFirst({
      where: { userId, commentId: id }
    });

    let isLiked;
    if (existingLike) {
      // Unlike
      await prisma.like.delete({
        where: { id: existingLike.id }
      });
      isLiked = false;
      logger.info(`Comment unliked by user ${userId}`, { commentId: id });
    } else {
      // Like
      await prisma.like.create({
        data: { userId, commentId: id }
      });
      isLiked = true;
      logger.info(`Comment liked by user ${userId}`, { commentId: id });
    }

    // Get updated like count
    const likeCount = await prisma.like.count({
      where: { commentId: id }
    });

    res.json({
      success: true,
      message: isLiked ? 'Comment liked' : 'Comment unliked',
      data: {
        isLiked,
        likeCount
      }
    });
  });
}

module.exports = new CommentController();
