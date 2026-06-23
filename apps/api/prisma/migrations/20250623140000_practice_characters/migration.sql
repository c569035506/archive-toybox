-- CreateTable
CREATE TABLE "ArgumentPracticeCharacter" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "relationship" TEXT NOT NULL DEFAULT '',
    "opponentStyle" TEXT NOT NULL,
    "identityDesc" TEXT NOT NULL DEFAULT '',
    "personalityDesc" TEXT NOT NULL DEFAULT '',
    "voiceGender" TEXT NOT NULL DEFAULT 'female',
    "voiceAge" TEXT NOT NULL DEFAULT 'middle',
    "memorySummary" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ArgumentPracticeCharacter_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "ArgumentPracticeSession" ADD COLUMN "characterId" TEXT;

-- CreateIndex
CREATE INDEX "ArgumentPracticeCharacter_userId_updatedAt_idx" ON "ArgumentPracticeCharacter"("userId", "updatedAt");

-- AddForeignKey
ALTER TABLE "ArgumentPracticeCharacter" ADD CONSTRAINT "ArgumentPracticeCharacter_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ArgumentPracticeSession" ADD CONSTRAINT "ArgumentPracticeSession_characterId_fkey" FOREIGN KEY ("characterId") REFERENCES "ArgumentPracticeCharacter"("id") ON DELETE SET NULL ON UPDATE CASCADE;
