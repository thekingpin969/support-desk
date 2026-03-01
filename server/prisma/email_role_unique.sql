-- Migration: composite_email_role_unique
-- WHAT: Drop the global unique index on email, add a composite unique index on (email, role)
-- This allows the same email to exist across different roles, but not twice in the same role.

-- Step 1: Drop the old unique constraint on email alone
ALTER TABLE "User" DROP CONSTRAINT IF EXISTS "User_email_key";

-- Step 2: Add composite unique constraint on (email, role)
ALTER TABLE "User" ADD CONSTRAINT "User_email_role_key" UNIQUE ("email", "role");
