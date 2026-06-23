-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "FriendRequestStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "MeritTxnType" AS ENUM ('WOODEN_FISH_TAP', 'MERIT_TRANSFER_IN', 'MERIT_TRANSFER_OUT');

-- CreateEnum
CREATE TYPE "ArgumentSessionStatus" AS ENUM ('ACTIVE', 'FINISHED');

-- CreateEnum
CREATE TYPE "MeditationTrackCategory" AS ENUM ('GREAT_COMPASSION_MANTRA', 'CALM_MUSIC', 'WHITE_NOISE', 'NATURE_SOUND');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "shortId" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "nickname" TEXT NOT NULL,
    "avatarUrl" TEXT,
    "totalMerit" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserDailyStats" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "dateKey" TEXT NOT NULL,
    "todayMerit" INTEGER NOT NULL DEFAULT 0,
    "todayFortune" INTEGER NOT NULL DEFAULT 0,
    "meditationSec" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "UserDailyStats_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MeritTransaction" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "MeritTxnType" NOT NULL,
    "amount" INTEGER NOT NULL,
    "balanceAfter" INTEGER NOT NULL,
    "counterpartyId" TEXT,
    "clientRequestId" TEXT NOT NULL,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MeritTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FriendRequest" (
    "id" TEXT NOT NULL,
    "fromUserId" TEXT NOT NULL,
    "toUserId" TEXT NOT NULL,
    "status" "FriendRequestStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FriendRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Friendship" (
    "id" TEXT NOT NULL,
    "userAId" TEXT NOT NULL,
    "userBId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Friendship_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ArgumentPracticeSession" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" "ArgumentSessionStatus" NOT NULL DEFAULT 'ACTIVE',
    "opponentLabel" TEXT NOT NULL,
    "relationship" TEXT NOT NULL,
    "whatHappened" TEXT NOT NULL,
    "practiceGoal" TEXT NOT NULL,
    "opponentStyle" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finishedAt" TIMESTAMP(3),

    CONSTRAINT "ArgumentPracticeSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ArgumentPracticeMessage" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ArgumentPracticeMessage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ArgumentPracticeReview" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "emotionalStability" INTEGER NOT NULL,
    "boundaryExpression" INTEGER NOT NULL,
    "logicClarity" INTEGER NOT NULL,
    "antiFrameControl" INTEGER NOT NULL,
    "relationshipPreservation" INTEGER NOT NULL,
    "effectiveResponse" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "summary" TEXT NOT NULL,
    "posterPayload" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ArgumentPracticeReview_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ArgumentAnalysisRecord" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "chatTextRedacted" TEXT NOT NULL,
    "selfSide" TEXT NOT NULL,
    "relationship" TEXT NOT NULL,
    "analysisGoal" TEXT NOT NULL,
    "report" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "ArgumentAnalysisRecord_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MeditationTrack" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "category" "MeditationTrackCategory" NOT NULL,
    "audioUrl" TEXT NOT NULL,
    "durationSec" INTEGER NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MeditationTrack_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MeditationSession" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "trackId" TEXT NOT NULL,
    "durationSec" INTEGER NOT NULL DEFAULT 0,
    "moodDelta" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MeditationSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PrivacyAcknowledgement" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "docType" TEXT NOT NULL,
    "version" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PrivacyAcknowledgement_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_shortId_key" ON "User"("shortId");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "UserDailyStats_userId_dateKey_key" ON "UserDailyStats"("userId", "dateKey");

-- CreateIndex
CREATE INDEX "MeritTransaction_userId_createdAt_idx" ON "MeritTransaction"("userId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "MeritTransaction_userId_clientRequestId_key" ON "MeritTransaction"("userId", "clientRequestId");

-- CreateIndex
CREATE INDEX "FriendRequest_toUserId_status_idx" ON "FriendRequest"("toUserId", "status");

-- CreateIndex
CREATE INDEX "FriendRequest_fromUserId_status_idx" ON "FriendRequest"("fromUserId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "Friendship_userAId_userBId_key" ON "Friendship"("userAId", "userBId");

-- CreateIndex
CREATE INDEX "ArgumentPracticeMessage_sessionId_createdAt_idx" ON "ArgumentPracticeMessage"("sessionId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "ArgumentPracticeReview_sessionId_key" ON "ArgumentPracticeReview"("sessionId");

-- CreateIndex
CREATE INDEX "ArgumentAnalysisRecord_userId_createdAt_idx" ON "ArgumentAnalysisRecord"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "MeditationSession_userId_createdAt_idx" ON "MeditationSession"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "MeditationSession_trackId_idx" ON "MeditationSession"("trackId");

-- AddForeignKey
ALTER TABLE "UserDailyStats" ADD CONSTRAINT "UserDailyStats_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeritTransaction" ADD CONSTRAINT "MeritTransaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FriendRequest" ADD CONSTRAINT "FriendRequest_fromUserId_fkey" FOREIGN KEY ("fromUserId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FriendRequest" ADD CONSTRAINT "FriendRequest_toUserId_fkey" FOREIGN KEY ("toUserId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Friendship" ADD CONSTRAINT "Friendship_userAId_fkey" FOREIGN KEY ("userAId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Friendship" ADD CONSTRAINT "Friendship_userBId_fkey" FOREIGN KEY ("userBId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ArgumentPracticeSession" ADD CONSTRAINT "ArgumentPracticeSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ArgumentPracticeMessage" ADD CONSTRAINT "ArgumentPracticeMessage_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "ArgumentPracticeSession"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ArgumentPracticeReview" ADD CONSTRAINT "ArgumentPracticeReview_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "ArgumentPracticeSession"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ArgumentAnalysisRecord" ADD CONSTRAINT "ArgumentAnalysisRecord_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeditationSession" ADD CONSTRAINT "MeditationSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeditationSession" ADD CONSTRAINT "MeditationSession_trackId_fkey" FOREIGN KEY ("trackId") REFERENCES "MeditationTrack"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PrivacyAcknowledgement" ADD CONSTRAINT "PrivacyAcknowledgement_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

