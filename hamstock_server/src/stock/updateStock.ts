import 'dotenv/config'
import YahooFinance from 'yahoo-finance2'
import { PrismaClient } from '@prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const yahooFinance = new YahooFinance()

const connectionString = process.env.DATABASE_URL
if (!connectionString) {
  throw new Error('DATABASE_URL is not set')
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
})

async function updateStocks() {
  const stocks = await prisma.stock.findMany()

  for (const stock of stocks) {
    try {
      const symbol =
        stock.market === 'KOSPI'
          ? `${stock.code}.KS`
          : stock.code

      const data = (await yahooFinance.quote(symbol)) as {
        regularMarketPrice?: number
        regularMarketChangePercent?: number
        regularMarketVolume?: number
        marketCap?: number
      }

      await prisma.stock.update({
        where: { id: stock.id },
        data: {
          price: data.regularMarketPrice ?? 0,
          changeRate: data.regularMarketChangePercent ?? 0,
          volume: data.regularMarketVolume ?? 0,
          marketCap: data.marketCap ?? 0,
          updatedAt: new Date(),
        },
      })

      console.log(`${stock.name} 업데이트 완료`)
    } catch (e) {
      console.log(`${stock.name} 실패`)
    }
  }
}

updateStocks()
