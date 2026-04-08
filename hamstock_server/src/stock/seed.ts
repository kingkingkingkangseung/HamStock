import 'dotenv/config'
import { PrismaClient } from '@prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const connectionString = process.env.DATABASE_URL
if (!connectionString) {
  throw new Error('DATABASE_URL is not set')
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
})

async function main() {
  await prisma.stock.createMany({
    data: [
      { name: "삼성전자", code: "005930", market: "KOSPI", price: 0, changeRate: 0, marketCap: 0, volume: 0, updatedAt: new Date() },
      { name: "SK하이닉스", code: "000660", market: "KOSPI", price: 0, changeRate: 0, marketCap: 0, volume: 0, updatedAt: new Date() },
      { name: "엔비디아", code: "NVDA", market: "NASDAQ", price: 0, changeRate: 0, marketCap: 0, volume: 0, updatedAt: new Date() },
      { name: "애플", code: "AAPL", market: "NASDAQ", price: 0, changeRate: 0, marketCap: 0, volume: 0, updatedAt: new Date() },
    ],
    skipDuplicates: true
  })

  console.log("종목 데이터 넣기 완료")
}

main()
