import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is not set');
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

const coreUniverse = [
  { name: '삼성전자', code: '005930', market: 'KOSPI', priority: 1 },
  { name: 'SK하이닉스', code: '000660', market: 'KOSPI', priority: 2 },
  { name: 'LG에너지솔루션', code: '373220', market: 'KOSPI', priority: 3 },
  { name: '현대차', code: '005380', market: 'KOSPI', priority: 4 },
  { name: '기아', code: '000270', market: 'KOSPI', priority: 5 },
  { name: 'KB금융', code: '105560', market: 'KOSPI', priority: 6 },
  { name: 'NAVER', code: '035420', market: 'KOSPI', priority: 7 },
  { name: '삼성바이오로직스', code: '207940', market: 'KOSPI', priority: 8 },
  { name: 'POSCO홀딩스', code: '005490', market: 'KOSPI', priority: 9 },
  { name: '셀트리온', code: '068270', market: 'KOSPI', priority: 10 },

  { name: '애플', code: 'AAPL', market: 'US', priority: 101 },
  { name: '엔비디아', code: 'NVDA', market: 'US', priority: 102 },
  { name: '마이크로소프트', code: 'MSFT', market: 'US', priority: 103 },
  { name: '아마존', code: 'AMZN', market: 'US', priority: 104 },
  { name: '알파벳A', code: 'GOOGL', market: 'US', priority: 105 },
  { name: '메타', code: 'META', market: 'US', priority: 106 },
  { name: '테슬라', code: 'TSLA', market: 'US', priority: 107 },
  { name: '브로드컴', code: 'AVGO', market: 'US', priority: 108 },
  { name: '넷플릭스', code: 'NFLX', market: 'US', priority: 109 },
  { name: 'AMD', code: 'AMD', market: 'US', priority: 110 },
];

async function main() {
  await prisma.watchUniverse.createMany({
    data: coreUniverse.map((item) => ({
      ...item,
      enabled: true,
    })),
    skipDuplicates: true,
  });

  for (const item of coreUniverse) {
    await prisma.stock.upsert({
      where: { code: item.code },
      update: {
        name: item.name,
        market: item.market,
      },
      create: {
        name: item.name,
        code: item.code,
        market: item.market,
        price: 0,
        changeRate: 0,
        marketCap: 0,
        volume: 0,
      },
    });
  }

  console.log('core universe seed completed');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

