import prisma from '../utils/prisma.js';

// Get user addresses
export const getAddresses = async (req, res) => {
  try {
    const addresses = await prisma.address.findMany({
      where: { userId: req.user.id },
      orderBy: [
        { isDefault: 'desc' },
        { createdAt: 'desc' }
      ]
    });

    res.json({ addresses });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch addresses', details: error.message });
  }
};

// Create address
export const createAddress = async (req, res) => {
  try {
    const { fullName, phone, pincode, street, city, state, country = 'India', isDefault = false } = req.body;

    // If setting as default, remove default from other addresses
    if (isDefault) {
      await prisma.address.updateMany({
        where: { userId: req.user.id },
        data: { isDefault: false }
      });
    }

    const address = await prisma.address.create({
      data: {
        userId: req.user.id,
        fullName,
        phone,
        pincode,
        street,
        city,
        state,
        country,
        isDefault
      }
    });

    res.status(201).json({
      message: 'Address created successfully',
      address
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create address', details: error.message });
  }
};

// Update address
export const updateAddress = async (req, res) => {
  try {
    const { id } = req.params;
    const { fullName, phone, pincode, street, city, state, country, isDefault } = req.body;

    // Check if address belongs to user
    const existingAddress = await prisma.address.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      }
    });

    if (!existingAddress) {
      return res.status(404).json({ error: 'Address not found' });
    }

    // If setting as default, remove default from other addresses
    if (isDefault && !existingAddress.isDefault) {
      await prisma.address.updateMany({
        where: { 
          userId: req.user.id,
          id: { not: parseInt(id) }
        },
        data: { isDefault: false }
      });
    }

    const address = await prisma.address.update({
      where: { id: parseInt(id) },
      data: {
        ...(fullName && { fullName }),
        ...(phone && { phone }),
        ...(pincode && { pincode }),
        ...(street && { street }),
        ...(city && { city }),
        ...(state && { state }),
        ...(country && { country }),
        ...(isDefault !== undefined && { isDefault })
      }
    });

    res.json({
      message: 'Address updated successfully',
      address
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update address', details: error.message });
  }
};

// Delete address
export const deleteAddress = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if address belongs to user
    const existingAddress = await prisma.address.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      }
    });

    if (!existingAddress) {
      return res.status(404).json({ error: 'Address not found' });
    }

    // Check if address is used in any orders
    const orderCount = await prisma.order.count({
      where: { addressId: parseInt(id) }
    });

    if (orderCount > 0) {
      return res.status(400).json({ 
        error: 'Cannot delete address used in orders',
        orderCount 
      });
    }

    await prisma.address.delete({
      where: { id: parseInt(id) }
    });

    // If deleted address was default, set another as default
    if (existingAddress.isDefault) {
      const firstAddress = await prisma.address.findFirst({
        where: { userId: req.user.id },
        orderBy: { createdAt: 'asc' }
      });

      if (firstAddress) {
        await prisma.address.update({
          where: { id: firstAddress.id },
          data: { isDefault: true }
        });
      }
    }

    res.json({ message: 'Address deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete address', details: error.message });
  }
};

// Set default address
export const setDefaultAddress = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if address belongs to user
    const address = await prisma.address.findFirst({
      where: {
        id: parseInt(id),
        userId: req.user.id
      }
    });

    if (!address) {
      return res.status(404).json({ error: 'Address not found' });
    }

    // Remove default from all addresses and set new default
    await prisma.$transaction([
      prisma.address.updateMany({
        where: { userId: req.user.id },
        data: { isDefault: false }
      }),
      prisma.address.update({
        where: { id: parseInt(id) },
        data: { isDefault: true }
      })
    ]);

    res.json({ message: 'Default address updated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to set default address', details: error.message });
  }
};
