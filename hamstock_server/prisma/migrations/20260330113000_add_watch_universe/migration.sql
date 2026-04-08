-- CreateTable
CREATE TABLE "WatchUniverse" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "market" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "priority" INTEGER NOT NULL DEFAULT 100,

    CONSTRAINT "WatchUniverse_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "WatchUniverse_market_code_key" ON "WatchUniverse"("market", "code");

-- CreateIndex
CREATE INDEX "WatchUniverse_enabled_priority_idx" ON "WatchUniverse"("enabled", "priority");
