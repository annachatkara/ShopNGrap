import { prisma } from '../config/database.js';
import { catchAsync, AppError } from '../middleware/errorHandler.js';
import crypto from 'crypto';
import bcrypt from 'bcrypt';

class OtpController {
  // Send OTP (simulated)
  sendOtp = catchAsync(async (req, res) => {
    const { email } = req.body;
    if (!email) throw new AppError('Email is required', 400);

    // Generate 6-digit OTP
    const otp = ('' + Math.floor(100000 + Math.random() * 900000));

    // Expiration: 10 minutes
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    // Save OTP record (invalidate previous unused OTPs for same email)
    await prisma.otpVerification.updateMany({
      where: { email, isUsed: false },
      data: { isUsed: true }
    });

    await prisma.otpVerification.create({
      data: { email, otp, expiresAt }
    });

    // Simulate sending OTP (here we just return OTP in response for dev)
    console.log(`OTP for ${email}: ${otp}`);

    res.json({ success: true, message: `OTP sent to ${email}. (Simulated)`, otp }); // Remove otp in production
  });

  // Verify OTP and register user
  verifyOtp = catchAsync(async (req, res) => {
    const { email, otp, password, firstName, lastName, phoneNumber, role } = req.body;
    if (!email || !otp || !password || !firstName || !lastName) {
      throw new AppError('Required fields missing', 400);
    }

    // Find valid OTP
    const otpRecord = await prisma.otpVerification.findFirst({
      where: {
        email,
        otp,
        isUsed: false,
        expiresAt: { gt: new Date() }
      }
    });

    if (!otpRecord) throw new AppError('Invalid or expired OTP', 400);

    // Check if user exists
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) throw new AppError('User already exists', 409);

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // Create user
    const user = await prisma.user.create({
      data: { email, passwordHash, firstName, lastName, phoneNumber, role }
    });

    // Mark OTP used
    await prisma.otpVerification.update({
      where: { id: otpRecord.id },
      data: { isUsed: true }
    });

    res.status(201).json({ success: true, message: 'User registered successfully', user });
  });
}

export default new OtpController();
