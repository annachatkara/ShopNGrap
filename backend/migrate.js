// Database migration helper
// ...implement migration helper logic here...
///usr/bin/env node

/**
 * Prisma Migration Script
 * Handles database migrations and setup
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

const log = (message, color = 'reset') => {
  console.log(`${colors[color]}${message}${colors.reset}`);
};

class PrismaMigrator {
  constructor() {
    this.command = process.argv[2];
    this.migrationName = process.argv[3];
  }

  async run() {
    try {
      switch (this.command) {
        case 'init':
          await this.initDatabase();
          break;
        case 'generate':
          await this.generateClient();
          break;
        case 'migrate':
          await this.runMigration();
          break;
        case 'deploy':
          await this.deployMigrations();
          break;
        case 'reset':
          await this.resetDatabase();
          break;
        case 'studio':
          await this.openStudio();
          break;
        case 'seed':
          await this.seedDatabase();
          break;
        case 'status':
          await this.checkMigrationStatus();
          break;
        default:
          this.showHelp();
      }
    } catch (error) {
      log(`Error: ${error.message}`, 'red');
      process.exit(1);
    }
  }

  async initDatabase() {
    log('🗄️  Initializing database...', 'cyan');

    // Check if .env file exists
    if (!fs.existsSync('.env')) {
      log('❌ .env file not found. Please create it with DATABASE_URL', 'red');
      process.exit(1);
    }

    // Generate Prisma client
    await this.generateClient();

    // Run initial migration
    const migrationName = this.migrationName || 'init';
    log(`🚀 Running initial migration: ${migrationName}`, 'yellow');

    try {
      execSync(`npx prisma migrate dev --name ${migrationName}`, { stdio: 'inherit' });
      log('✅ Database initialized successfully!', 'green');

      // Optional: Run seed if seed file exists
      if (fs.existsSync('prisma/seed.js') || fs.existsSync('prisma/seed.ts')) {
        log('🌱 Seed file found. Running seeder...', 'cyan');
        await this.seedDatabase();
      }
    } catch (error) {
      log('❌ Migration failed:', 'red');
      console.error(error.message);
      process.exit(1);
    }
  }

  async generateClient() {
    log('⚙️  Generating Prisma client...', 'cyan');
    try {
      execSync('npx prisma generate', { stdio: 'inherit' });
      log('✅ Prisma client generated successfully!', 'green');
    } catch (error) {
      throw new Error('Failed to generate Prisma client');
    }
  }

  async runMigration() {
    const migrationName = this.migrationName;
    if (!migrationName) {
      log('❌ Migration name is required. Usage: npm run migrate migrate <name>', 'red');
      process.exit(1);
    }

    log(`🔄 Creating migration: ${migrationName}`, 'cyan');
    try {
      execSync(`npx prisma migrate dev --name ${migrationName}`, { stdio: 'inherit' });
      log('✅ Migration completed successfully!', 'green');
    } catch (error) {
      throw new Error('Migration failed');
    }
  }

  async deployMigrations() {
    log('🚀 Deploying migrations to production...', 'cyan');
    try {
      execSync('npx prisma migrate deploy', { stdio: 'inherit' });
      log('✅ Migrations deployed successfully!', 'green');
    } catch (error) {
      throw new Error('Migration deployment failed');
    }
  }

  async resetDatabase() {
    log('⚠️  This will delete all data in the database!', 'yellow');
    log('🔄 Resetting database...', 'cyan');

    try {
      execSync('npx prisma migrate reset --force', { stdio: 'inherit' });
      log('✅ Database reset completed!', 'green');
    } catch (error) {
      throw new Error('Database reset failed');
    }
  }

  async openStudio() {
    log('🎨 Opening Prisma Studio...', 'cyan');
    try {
      execSync('npx prisma studio', { stdio: 'inherit' });
    } catch (error) {
      throw new Error('Failed to open Prisma Studio');
    }
  }

  async seedDatabase() {
    log('🌱 Seeding database...', 'cyan');
    try {
      execSync('npx prisma db seed', { stdio: 'inherit' });
      log('✅ Database seeded successfully!', 'green');
    } catch (error) {
      log('⚠️  Seeding failed or no seed file configured', 'yellow');
    }
  }

  async checkMigrationStatus() {
    log('📊 Checking migration status...', 'cyan');
    try {
      execSync('npx prisma migrate status', { stdio: 'inherit' });
    } catch (error) {
      throw new Error('Failed to check migration status');
    }
  }

  showHelp() {
    log('🔧 Prisma Migration Helper', 'bright');
    log('Usage: node migrate.js <command> [options]', 'cyan');
    log('');
    log('Commands:', 'bright');
    log('  init [name]     Initialize database with migrations', 'green');
    log('  generate        Generate Prisma client', 'green');
    log('  migrate <name>  Create and run a new migration', 'green');
    log('  deploy          Deploy migrations (production)', 'green');
    log('  reset           Reset database (⚠️  destructive)', 'red');
    log('  studio          Open Prisma Studio', 'green');
    log('  seed            Run database seeder', 'green');
    log('  status          Check migration status', 'green');
    log('');
    log('Examples:', 'bright');
    log('  node migrate.js init', 'cyan');
    log('  node migrate.js migrate add_user_preferences', 'cyan');
    log('  node migrate.js deploy', 'cyan');
    log('');
  }
}

// Run the migrator
const migrator = new PrismaMigrator();
migrator.run();
