import prisma from '../utils/prisma.js';
import { logAdminActivity } from '../middleware/admin.js';
import bcrypt from 'bcrypt';

// Send admin request (Customer)
export const sendAdminRequest = async (req, res) => {
  try {
    const { shopName, adminName, description, phone, address } = req.body;

    // Check if user already has pending request
    const existingRequest = await prisma.adminRequest.findFirst({
      where: {
        userId: req.user.id,
        status: 'pending'
      }
    });

    if (existingRequest) {
      return res.status(400).json({ 
        error: 'You already have a pending admin request' 
      });
    }

    // Check if user is already an admin
    if (req.user.role === 'admin') {
      return res.status(400).json({ 
        error: 'You are already an admin' 
      });
    }

    const adminRequest = await prisma.adminRequest.create({
      data: {
        userId: req.user.id,
        shopName,
        adminName,
        description,
        phone,
        address
      },
      include: {
        user: {
          select: { id: true, name: true, email: true }
        }
      }
    });

    res.status(201).json({
      message: 'Admin request submitted successfully',
      request: adminRequest
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to submit admin request', 
      details: error.message 
    });
  }
};

// Get my admin requests (Customer)
export const getMyRequests = async (req, res) => {
  try {
    const requests = await prisma.adminRequest.findMany({
      where: { userId: req.user.id },
      include: {
        handledBy: {
          select: { name: true, email: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ requests });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to fetch requests', 
      details: error.message 
    });
  }
};

// Get all admin requests (Superuser)
export const getAllRequests = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (status) where.status = status;

    const requests = await prisma.adminRequest.findMany({
      where,
      include: {
        user: {
          select: { id: true, name: true, email: true, phone: true, createdAt: true }
        },
        handledBy: {
          select: { name: true, email: true }
        }
      },
      skip: parseInt(skip),
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    });

    const total = await prisma.adminRequest.count({ where });

    res.json({
      requests,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to fetch admin requests', 
      details: error.message 
    });
  }
};

// Approve admin request (Superuser)
export const approveRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    // Get request details
    const request = await prisma.adminRequest.findUnique({
      where: { id: parseInt(id) },
      include: {
        user: true
      }
    });

    if (!request) {
      return res.status(404).json({ error: 'Request not found' });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({ error: 'Request already processed' });
    }

    // Transaction to approve request and create shop + admin
    const result = await prisma.$transaction(async (tx) => {
      // Update request status
      await tx.adminRequest.update({
        where: { id: parseInt(id) },
        data: {
          status: 'approved',
          reason: reason || 'Request approved',
          handledById: req.user.id,
          handledAt: new Date()
        }
      });

      // Create shop with admin
      const shop = await tx.shop.create({
        data: {
          name: request.shopName,
          description: request.description,
          address: request.address,
          phone: request.phone,
          adminId: request.userId
        }
      });

      // Update user role to admin
      await tx.user.update({
        where: { id: request.userId },
        data: { role: 'admin' }
      });

      return { request, shop };
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'APPROVED_ADMIN_REQUEST',
      `Approved admin request for ${request.user.email}. Shop: ${request.shopName}`,
      parseInt(id),
      'admin_request'
    );

    res.json({
      message: 'Admin request approved successfully',
      request: result.request,
      shop: result.shop
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to approve request', 
      details: error.message 
    });
  }
};

// Reject admin request (Superuser)
export const rejectRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    if (!reason) {
      return res.status(400).json({ error: 'Reason is required for rejection' });
    }

    const request = await prisma.adminRequest.findUnique({
      where: { id: parseInt(id) },
      include: {
        user: {
          select: { name: true, email: true }
        }
      }
    });

    if (!request) {
      return res.status(404).json({ error: 'Request not found' });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({ error: 'Request already processed' });
    }

    const updatedRequest = await prisma.adminRequest.update({
      where: { id: parseInt(id) },
      data: {
        status: 'rejected',
        reason,
        handledById: req.user.id,
        handledAt: new Date()
      },
      include: {
        user: {
          select: { name: true, email: true }
        },
        handledBy: {
          select: { name: true, email: true }
        }
      }
    });

    // Log activity
    await logAdminActivity(
      req.user.id,
      'REJECTED_ADMIN_REQUEST',
      `Rejected admin request for ${request.user.email}. Reason: ${reason}`,
      parseInt(id),
      'admin_request'
    );

    res.json({
      message: 'Admin request rejected',
      request: updatedRequest
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to reject request', 
      details: error.message 
    });
  }
};

// Get request statistics (Superuser)
export const getRequestStats = async (req, res) => {
  try {
    const [total, pending, approved, rejected] = await Promise.all([
      prisma.adminRequest.count(),
      prisma.adminRequest.count({ where: { status: 'pending' } }),
      prisma.adminRequest.count({ where: { status: 'approved' } }),
      prisma.adminRequest.count({ where: { status: 'rejected' } })
    ]);

    res.json({
      stats: {
        total,
        pending,
        approved,
        rejected
      }
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to fetch stats', 
      details: error.message 
    });
  }
};
