import { BadRequestException, Injectable } from '@nestjs/common';

const DAILY_SEED_LIMIT = 5;
const INITIAL_BALANCE = 10000000;
const SEED_EXCHANGE_UNIT = 10;
const SEED_EXCHANGE_CASH = 500000;

type QuizAnswer = 'O' | 'X';

type QuizQuestion = {
  id: number;
  category: string;
  text: string;
  answer: QuizAnswer;
  explanation: string;
};

const QUESTIONS: QuizQuestion[] = [
  { id: 1, category: '경제 기초', text: '기회비용은 어떤 선택을 위해 포기한 여러 대안 중 가장 가치가 큰 하나만을 의미한다.', answer: 'O', explanation: '기회비용은 포기한 대안 전체의 합이 아니라 가장 가치 있는 하나의 대안입니다.' },
  { id: 2, category: '경제 기초', text: '인플레이션이 발생하면 화폐의 구매력은 상승한다.', answer: 'X', explanation: '물가가 오르면 같은 돈으로 살 수 있는 양이 줄어 구매력은 하락합니다.' },
  { id: 3, category: '경제 기초', text: '대체재 관계에 있는 두 재화 중 한 재화의 가격이 오르면, 다른 재화의 수요는 증가한다.', answer: 'O', explanation: '한 상품이 비싸지면 상대적으로 저렴한 대체재 수요가 증가합니다.' },
  { id: 4, category: '경제 기초', text: '보완재 관계에 있는 두 재화는 한 재화의 가격이 오르면 다른 재화의 수요도 함께 감소한다.', answer: 'O', explanation: '함께 쓰는 상품은 한쪽 소비가 줄면 다른 쪽 수요도 같이 줄어듭니다.' },
  { id: 5, category: '경제 기초', text: '매몰비용은 이미 지출되어 다시 회수할 수 없는 비용이므로 합리적 선택을 할 때 고려하지 않아야 한다.', answer: 'O', explanation: '이미 되돌릴 수 없는 비용보다 앞으로의 편익과 비용을 봐야 합니다.' },
  { id: 6, category: '경제 기초', text: '국내총생산(GDP)에는 외국인이 우리나라 영토 안에서 생산한 최종 생산물의 가치도 포함된다.', answer: 'O', explanation: 'GDP는 국적이 아니라 한 나라 영토 안에서 생산된 가치를 기준으로 합니다.' },
  { id: 7, category: '경제 기초', text: '스태그플레이션은 경기 침체와 물가 상승이 동시에 발생하는 현상을 말한다.', answer: 'O', explanation: 'Stagnation과 Inflation이 결합된 불황 속 물가 상승 현상입니다.' },
  { id: 8, category: '경제 기초', text: '수요법칙에 따르면 다른 조건이 일정할 때 상품 가격이 오르면 수요량은 증가한다.', answer: 'X', explanation: '일반적으로 가격이 오르면 소비자는 구매 수량을 줄입니다.' },
  { id: 9, category: '경제 기초', text: '규모의 경제란 생산 규모가 커질수록 제품 단위당 평균 생산 비용이 증가하는 현상이다.', answer: 'X', explanation: '규모의 경제는 대량 생산으로 단위당 평균 비용이 감소하는 현상입니다.' },
  { id: 10, category: '경제 기초', text: '엥겔계수는 총 소비지출에서 식료품비가 차지하는 비율을 나타내는 지표다.', answer: 'O', explanation: '소득이 낮을수록 식료품비 비중이 커지는 경향을 보여줍니다.' },
  { id: 11, category: '경제 기초', text: '공공재는 대가를 치르지 않은 사람도 소비에서 배제할 수 없는 비배제성을 가진다.', answer: 'O', explanation: '국방, 가로등처럼 비용을 내지 않은 사람도 혜택에서 막기 어렵습니다.' },
  { id: 12, category: '경제 기초', text: '독점시장의 공급자는 가격을 마음대로 결정하는 가격 설정자의 지위를 갖는다.', answer: 'O', explanation: '경쟁자가 없는 공급자는 공급량 조절로 가격 주도권을 가집니다.' },
  { id: 13, category: '경제 기초', text: '실업률은 전체 인구 중에서 실업자가 차지하는 비율을 계산한 것이다.', answer: 'X', explanation: '실업률은 경제활동인구 중 실업자의 비율입니다.' },
  { id: 14, category: '경제 기초', text: '낙수효과는 대기업이나 부유층의 소득이 늘어나면 저소득층에게도 혜택이 돌아간다는 이론이다.', answer: 'O', explanation: '상위층의 성장이 경제 전반으로 퍼진다는 성장 모델입니다.' },
  { id: 15, category: '경제 기초', text: '로렌츠 곡선이 균등분배선에 가까워질수록 소득 분배는 불평등하다.', answer: 'X', explanation: '균등분배선에 가까울수록 더 평등한 분배 상태입니다.' },
  { id: 16, category: '투자 기초', text: '배당금은 기업이 이익을 내지 못해도 주주에게 무조건 지급해야 하는 돈이다.', answer: 'X', explanation: '배당은 이익 일부를 나누는 것이므로 이익이 없으면 지급되지 않을 수 있습니다.' },
  { id: 17, category: '투자 기초', text: '시가총액은 상장 주식 수에 현재 주가를 곱한 금액으로 기업의 총 가치를 나타낸다.', answer: 'O', explanation: '시가총액은 시장에서 평가하는 기업 규모를 보여주는 대표 지표입니다.' },
  { id: 18, category: '투자 기초', text: 'PER이 시장 평균보다 낮다면 해당 주식은 과평가되어 있을 확률이 높다.', answer: 'X', explanation: 'PER이 낮으면 번 돈 대비 주가가 낮아 보통 저평가로 해석합니다.' },
  { id: 19, category: '투자 기초', text: '예수금은 이미 주식을 매수하는 데 사용 완료된 돈을 말한다.', answer: 'X', explanation: '예수금은 아직 투자하지 않았거나 매도 후 남은 대기 현금입니다.' },
  { id: 20, category: '투자 기초', text: '펀드는 여러 투자자의 돈을 모아 전문가가 대신 투자해 주는 간접 투자 상품이다.', answer: 'O', explanation: '펀드매니저가 자금을 운용하고 성과를 투자자에게 배분합니다.' },
  { id: 21, category: '투자 기초', text: 'ETF는 분산투자가 가능하면서도 주식처럼 거래소에서 실시간 매매할 수 있다.', answer: 'O', explanation: 'ETF는 펀드의 분산성과 주식의 거래 편의성을 결합한 상품입니다.' },
  { id: 22, category: '투자 기초', text: '서킷브레이커는 주가 급등락 때 시장을 진정시키기 위해 매매를 일시 중단하는 제도다.', answer: 'O', explanation: '과열과 공포로 인한 시장 충격을 줄이는 안전장치입니다.' },
  { id: 23, category: '투자 기초', text: '공매도는 주가 하락을 예상하고 주식을 빌려서 파는 투자 기법이다.', answer: 'O', explanation: '빌려 판 뒤 주가가 떨어지면 싸게 사서 갚아 차익을 노립니다.' },
  { id: 24, category: '투자 기초', text: '상장폐지가 결정된 주식은 즉시 가치가 0원이 되어 거래가 불가능하다.', answer: 'X', explanation: '정리매매 기간이나 장외 거래 가능성이 남을 수 있습니다.' },
  { id: 25, category: '투자 기초', text: '예금자보호제도는 주식의 원금 손실도 인당 5천만 원까지 보호한다.', answer: 'X', explanation: '주식과 펀드 같은 투자 상품의 원금 손실은 보호 대상이 아닙니다.' },
  { id: 26, category: '투자 기초', text: '채권은 정부나 기업이 자금 조달을 위해 발행하는 채무 증서다.', answer: 'O', explanation: '채권은 정해진 이자와 원금 상환을 약속하는 증서입니다.' },
  { id: 27, category: '투자 기초', text: '코스닥은 주로 대기업과 전통 금융 기업들이 상장된 시장이다.', answer: 'X', explanation: '코스닥은 벤처, IT, 중소기업 중심 시장입니다.' },
  { id: 28, category: '투자 기초', text: '우선주는 의결권이 제한되는 대신 배당을 우선적으로 받을 권리가 있다.', answer: 'O', explanation: '이름 뒤에 우가 붙는 종목들이 대표적인 우선주입니다.' },
  { id: 29, category: '투자 기초', text: '분산투자를 하면 시장 전체 위험까지 완전히 없앨 수 있다.', answer: 'X', explanation: '분산투자는 개별 기업 위험을 줄이지만 시장 전체 위험은 남습니다.' },
  { id: 30, category: '투자 기초', text: '선물 거래는 미래 특정 시점에 미리 정한 가격으로 매매하기로 약정하는 거래다.', answer: 'O', explanation: '미래 가격 변동 위험을 관리하거나 차익을 노리는 파생상품입니다.' },
  { id: 31, category: '투자 기초', text: '주식 매수 후 대금 결제는 매수 당일에 바로 이루어진다.', answer: 'X', explanation: '국내 주식은 일반적으로 D+2 결제 구조입니다.' },
  { id: 32, category: '투자 기초', text: '복리 효과는 원금에만 이자가 붙는 방식이다.', answer: 'X', explanation: '복리는 이자가 다시 원금에 더해져 이자를 낳는 방식입니다.' },
  { id: 33, category: '투자 기초', text: 'ROE는 주주의 돈을 활용해 얼마나 효율적으로 이익을 냈는지 보여준다.', answer: 'O', explanation: '자기자본 대비 순이익을 측정하는 수익성 지표입니다.' },
  { id: 34, category: '투자 기초', text: '블루칩은 위험이 매우 높은 신생 벤처기업 주식을 말한다.', answer: 'X', explanation: '블루칩은 재무구조가 안정적인 대형 우량주를 뜻합니다.' },
  { id: 35, category: '투자 기초', text: '액면분할을 하면 기업의 본질적 가치나 총 시가총액이 늘어난다.', answer: 'X', explanation: '주식 수와 주당 가격만 조정될 뿐 기업 가치 자체는 변하지 않습니다.' },
  { id: 36, category: '거시 경제', text: '중앙은행이 기준금리를 인상하면 일반적으로 시중 은행의 대출 금리도 올라간다.', answer: 'O', explanation: '자금 조달 비용이 커져 시중 금리도 동반 상승하는 경향이 있습니다.' },
  { id: 37, category: '거시 경제', text: '원-달러 환율 상승은 달러 대비 원화 가치가 떨어졌음을 의미한다.', answer: 'O', explanation: '1달러를 사기 위해 더 많은 원화가 필요해진 상태입니다.' },
  { id: 38, category: '거시 경제', text: '일반적으로 환율이 상승하면 국내 수출 기업의 가격 경쟁력은 강화된다.', answer: 'O', explanation: '해외에서 외화 표시 가격을 낮출 여력이 생겨 수출에 유리할 수 있습니다.' },
  { id: 39, category: '거시 경제', text: '한국은행이 시중의 국공채를 매입하면 시중 통화량은 감소한다.', answer: 'X', explanation: '채권 매입 대금이 시중에 풀리므로 통화량은 증가합니다.' },
  { id: 40, category: '거시 경제', text: '낙관적 전망이 지배적인 강세장을 베어 마켓이라고 한다.', answer: 'X', explanation: '강세장은 불 마켓, 약세장이 베어 마켓입니다.' },
  { id: 41, category: '거시 경제', text: '디플레이션은 물가가 지속적으로 하락하는 현상으로 경제에 무조건 긍정적이다.', answer: 'X', explanation: '소비 지연과 경기 침체를 동반할 수 있어 위험 신호일 수 있습니다.' },
  { id: 42, category: '생활 금융', text: '신용카드는 사용한 금액이 내 통장에서 즉시 출금되는 카드다.', answer: 'X', explanation: '즉시 출금은 체크카드이고 신용카드는 나중에 정산합니다.' },
  { id: 43, category: '생활 금융', text: '소득이 많아질수록 더 높은 세율을 적용하는 세금 방식을 누진세라고 한다.', answer: 'O', explanation: '고소득자에게 더 높은 세율을 적용해 형평성을 맞추는 구조입니다.' },
  { id: 44, category: '거시 경제', text: '재정 정책은 정부가 세금이나 정부 지출 규모를 조절해 경기를 조절하는 방식이다.', answer: 'O', explanation: '금리를 조절하는 통화 정책과 구분되는 정부 주도 정책입니다.' },
  { id: 45, category: '생활 금융', text: '신용점수가 낮아지면 대출을 받을 때 더 낮은 금리를 적용받아 유리하다.', answer: 'X', explanation: '신용점수가 낮으면 더 높은 금리나 대출 거절 가능성이 커집니다.' },
  { id: 46, category: '거시 경제', text: '양적완화는 중앙은행이 시장에 돈을 공급해 경기 침체를 방어하는 통화 정책이다.', answer: 'O', explanation: '기준금리 인하만으로 부족할 때 유동성을 직접 공급하는 방식입니다.' },
  { id: 47, category: '생활 금융', text: '변동금리 대출은 시장 상황에 따라 이자율이 계속 바뀌는 대출 상품이다.', answer: 'O', explanation: '금리 하락기에는 유리하지만 상승기에는 부담이 커집니다.' },
  { id: 48, category: '거시 경제', text: '국제 유가가 급등하면 석유 수입국인 우리나라 기업의 생산 비용 부담은 감소한다.', answer: 'X', explanation: '원자재 가격 상승은 기업의 생산 비용 부담을 키웁니다.' },
  { id: 49, category: '투자 기초', text: '배당락일에 주식을 매수해도 해당 분기의 배당금을 받을 수 있다.', answer: 'X', explanation: '배당을 받으려면 배당락일 전날까지 주식을 보유해야 합니다.' },
  { id: 50, category: '투자 기초', text: '펀드의 과거 수익률은 미래 수익률을 보장하는 절대적인 지표다.', answer: 'X', explanation: '과거 성과는 참고용일 뿐 미래 수익을 보장하지 않습니다.' },
];

@Injectable()
export class QuizService {
  private demoSeed = 0;
  private demoTodayAwarded = 0;
  private demoCashBalance = INITIAL_BALANCE;
  private demoTotalValue = INITIAL_BALANCE;

  async getRandom(userIdValue?: string) {
    const question = QUESTIONS[Math.floor(Math.random() * QUESTIONS.length)];

    return {
      question: this.publicQuestion(question),
      dailyLimit: DAILY_SEED_LIMIT,
      todayAwarded: this.demoTodayAwarded,
      remaining: Math.max(0, DAILY_SEED_LIMIT - this.demoTodayAwarded),
      seed: this.demoSeed,
    };
  }

  async answer(body: unknown) {
    const payload = this.parseBody(body);

    const questionId = this.parsePositiveInt(payload.questionId, 'questionId');
    const submittedAnswer = this.parseAnswer(payload.answer);

    const question = QUESTIONS.find((item) => item.id === questionId);
    if (!question) throw new BadRequestException('unknown question');

    const correct = question.answer === submittedAnswer;

    let seedAwarded = 0;

    if (correct && this.demoTodayAwarded < DAILY_SEED_LIMIT) {
      seedAwarded = 1;
      this.demoSeed += 1;
      this.demoTodayAwarded += 1;
    }

    return {
      correct,
      answer: question.answer,
      explanation: question.explanation,
      seedAwarded,
      dailyLimit: DAILY_SEED_LIMIT,
      todayAwarded: this.demoTodayAwarded,
      remaining: Math.max(0, DAILY_SEED_LIMIT - this.demoTodayAwarded),
      seed: this.demoSeed,
    };
  }

  async exchange(body: unknown) {
    const bundleCount = Math.floor(this.demoSeed / SEED_EXCHANGE_UNIT);

    if (bundleCount < 1) {
      throw new BadRequestException('해바라기씨가 10개 이상 필요합니다.');
    }

    const seedUsed = bundleCount * SEED_EXCHANGE_UNIT;
    const cashAdded = bundleCount * SEED_EXCHANGE_CASH;

    this.demoSeed -= seedUsed;
    this.demoCashBalance += cashAdded;
    this.demoTotalValue += cashAdded;

    return {
      seedUsed,
      cashAdded,
      seed: this.demoSeed,
      cashBalance: this.demoCashBalance,
      totalValue: this.demoTotalValue,
    };
  }

  private publicQuestion(question: QuizQuestion) {
    return {
      id: question.id,
      category: question.category,
      text: question.text,
    };
  }

  private parseBody(body: unknown): Record<string, unknown> {
    if (body instanceof Uint8Array) {
      return this.parseJsonBodyString(Buffer.from(body).toString('utf8'));
    }

    if (typeof body === 'string') {
      return this.parseJsonBodyString(body);
    }

    if (typeof body === 'object' && body !== null) {
      const record = body as Record<string, unknown>;
      const candidates = [...Object.values(record), ...Object.keys(record)];

      for (const candidate of candidates) {
        if (typeof candidate !== 'string') continue;

        const trimmed = candidate.trim();

        if (
          (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('"') && trimmed.endsWith('"'))
        ) {
          return this.parseJsonBodyString(trimmed);
        }
      }

      return record;
    }

    return {};
  }

  private parseJsonBodyString(raw: string): Record<string, unknown> {
    let parsed: unknown = raw.trim();

    for (let i = 0; i < 3; i += 1) {
      if (typeof parsed !== 'string') {
        return this.parseBody(parsed);
      }

      const trimmed = parsed.trim();
      if (!trimmed) return {};

      try {
        parsed = JSON.parse(trimmed);
      } catch {
        throw new BadRequestException('invalid request body');
      }
    }

    return typeof parsed === 'object' && parsed !== null
      ? this.parseBody(parsed)
      : {};
  }

  private parsePositiveInt(value: unknown, field: string) {
    const parsed = Number(value);

    if (!Number.isInteger(parsed) || parsed <= 0) {
      throw new BadRequestException(`${field} must be a positive integer`);
    }

    return parsed;
  }

  private parseAnswer(value: unknown): QuizAnswer {
    const normalized = String(value ?? '').trim().toUpperCase();

    if (normalized !== 'O' && normalized !== 'X') {
      throw new BadRequestException('answer must be O or X');
    }

    return normalized;
  }
}