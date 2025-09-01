import prisma from '../utils/prisma.js';

// Get product reviews
export const getProductReviews = async (req, res) => {
  try {
    const { productId } = req.params;
    const { page = 1, limit = 10, rating } = req.query;
    const skip = (page - 1) * limit;

    const where = { productId: parseInt(productId) };
    if (rating) where.rating = parseInt(rating);

    const reviews = await prisma.review.findMany({
      where,
      include: {
        user: {
          select: { id: true, name: true }
        }
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.review.count({ where });

    // Get rating summary
    const ratingSummary = await prisma.review.groupBy({
      by: ['rating'],
      where: { productId: parseInt(productId) },
      _count: { rating: true }
    });

    const averageRating = await prisma.review.aggregate({
      where: { productId: parseInt(productId) },
      _avg: { rating: true },
      _count: { rating: true }
    });

    res.json({
      reviews,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      },
      summary: {
        averageRating: averageRating._avg.rating || 0,
        totalReviews: averageRating._count.rating,
        ratingDistribution: ratingSummary.reduce((acc, item) => {
          acc[item.rating] = item._count.rating;
          return acc;
        }, {})
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch reviews', details: error.message });
  }
};

// Create review
export const createReview = async (req, res) => {
  try {
    const { productId, rating, comment } = req.body;

    // Check if product exists and user has purchased it
    const product = await prisma.product.findUnique({
      where: { id: parseInt(productId) }
    });

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    // Check if user has purchased this product
    const purchase = await prisma.orderItem.findFirst({
      where: {
        productId: parseInt(productId),
        order: {
          userId: req.user.id,
          status: 'delivered'
        }
      }
    });

    if (!purchase) {
      return res.status(400).json({ error: 'You can only review products you have purchased and received' });
    }

    // Check if user already reviewed this product
    const existingReview = await prisma.review.findUnique({
      where: {
        userId_productId: {
          userId: req.user.id,
          productId: parseInt(productId)
        }
      }
    });

    if (existingReview) {
      return res.status(400).json({ error: 'You have already reviewed this product' });
    }

    const review = await prisma.review.create({
      data: {
        userId: req.user.id,
        productId: parseInt(productId),
        rating: parseInt(rating),
        comment
      },
      include: {
        user: {
          select: { id: true, name: true }
        },
        product: {
          select: { id: true, name: true }
        }
      }
    });

    res.status(201).json({
      message: 'Review created successfully',
      review
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create review', details: error.message });
  }
};

// Update review
export const updateReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, comment } = req.body;

    // Check if review belongs to user
    const existingReview = await prisma.review.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      }
    });

    if (!existingReview) {
      return res.status(404).json({ error: 'Review not found' });
    }

    const review = await prisma.review.update({
      where: { id: parseInt(id) },
      data: {
        ...(rating && { rating: parseInt(rating) }),
        ...(comment !== undefined && { comment })
      },
      include: {
        user: {
          select: { id: true, name: true }
        },
        product: {
          select: { id: true, name: true }
        }
      }
    });

    res.json({
      message: 'Review updated successfully',
      review
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update review', details: error.message });
  }
};

// Delete review
export const deleteReview = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if review belongs to user
    const existingReview = await prisma.review.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      }
    });

    if (!existingReview) {
      return res.status(404).json({ error: 'Review not found' });
    }

    await prisma.review.delete({
      where: { id: parseInt(id) }
    });

    res.json({ message: 'Review deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete review', details: error.message });
  }
};

// Get user reviews
export const getUserReviews = async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const reviews = await prisma.review.findMany({
      where: { userId: req.user.id },
      include: {
        product: {
          select: { id: true, name: true, imageUrl: true }
        }
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.review.count({
      where: { userId: req.user.id }
    });

    res.json({
      reviews,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch user reviews', details: error.message });
  }
};
