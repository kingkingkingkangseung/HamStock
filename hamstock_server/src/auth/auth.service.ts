import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { pbkdf2Sync, randomBytes, timingSafeEqual } from 'crypto';
import { PrismaService } from '../prisma.service';

const INITIAL_BALANCE = 10_000_000;

type AuthBody = {
  email?: string;
  password?: string;
  nickname?: string;
};

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  async signup(body: unknown) {
    const payload = this.parseAuthBody(body);
    const email = this.normalizeEmail(payload.email);
    const password = this.validatePassword(payload.password);
    const nickname = this.validateNickname(payload.nickname);

    const existingNickname = await this.prisma.user.findFirst({
      where: {
        nickname,
        NOT: { email },
      },
    });
    if (existingNickname) {
      throw new ConflictException('already registered nickname');
    }

    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      if (existing.passwordHash) {
        throw new BadRequestException('already registered email');
      }

      const user = await this.prisma.user.update({
        where: { id: existing.id },
        data: {
          nickname,
          passwordHash: this.hashPassword(password),
          asset: existing.id
            ? {
                upsert: {
                  create: {
                    balance: INITIAL_BALANCE,
                    totalValue: INITIAL_BALANCE,
                    seed: 0,
                  },
                  update: {},
                },
              }
            : undefined,
        },
        include: { asset: true },
      });

      return this.authResponse(user);
    }

    const user = await this.prisma.user.create({
      data: {
        email,
        nickname,
        passwordHash: this.hashPassword(password),
        asset: {
          create: {
            balance: INITIAL_BALANCE,
            totalValue: INITIAL_BALANCE,
            seed: 0,
          },
        },
      },
      include: { asset: true },
    });

    return this.authResponse(user);
  }

  async login(body: unknown) {
    const payload = this.parseAuthBody(body);
    const email = this.normalizeEmail(payload.email);
    const password = this.validatePassword(payload.password);

    const user = await this.prisma.user.findUnique({
      where: { email },
      include: { asset: true },
    });

    if (!user?.passwordHash || !this.verifyPassword(password, user.passwordHash)) {
      throw new UnauthorizedException('invalid email or password');
    }

    const asset =
      user.asset ??
      (await this.prisma.asset.create({
        data: {
          userId: user.id,
          balance: INITIAL_BALANCE,
          totalValue: INITIAL_BALANCE,
          seed: 0,
        },
      }));

    return this.authResponse({ ...user, asset });
  }

  private parseAuthBody(body: unknown): AuthBody {
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

      return {
        email: typeof record.email === 'string' ? record.email.trim() : undefined,
        password:
          typeof record.password === 'string' ? record.password.trim() : undefined,
        nickname:
          typeof record.nickname === 'string' ? record.nickname.trim() : undefined,
      };
    }

    return {};
  }

  private parseJsonBodyString(raw: string): AuthBody {
    let parsed: unknown = raw.trim();

    for (let i = 0; i < 3; i += 1) {
      if (typeof parsed !== 'string') {
        return this.parseAuthBody(parsed);
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
      ? this.parseAuthBody(parsed)
      : {};
  }

  private authResponse(user: {
    id: number;
    email: string;
    nickname: string;
    createdAt: Date;
    asset: { balance: number; totalValue: number; seed: number } | null;
  }) {
    return {
      user: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        createdAt: user.createdAt,
      },
      asset: user.asset,
    };
  }

  private normalizeEmail(email?: string) {
    const normalized = email?.trim().toLowerCase();
    if (
      !normalized ||
      normalized.includes('{') ||
      normalized.includes('}') ||
      !normalized.includes('@')
    ) {
      throw new BadRequestException('valid email is required');
    }
    return normalized;
  }

  private validateNickname(nickname?: string) {
    const normalized = nickname?.trim();
    if (!normalized || normalized.length < 2) {
      throw new BadRequestException('nickname must be at least 2 characters');
    }
    return normalized;
  }

  private validatePassword(password?: string) {
    const normalized = password?.trim();
    if (!normalized || normalized.length < 6) {
      throw new BadRequestException('password must be at least 6 characters');
    }
    return normalized;
  }

  private hashPassword(password: string) {
    const salt = randomBytes(16).toString('hex');
    const hash = pbkdf2Sync(password, salt, 100_000, 32, 'sha256').toString('hex');
    return `${salt}:${hash}`;
  }

  private verifyPassword(password: string, stored: string) {
    const [salt, hash] = stored.split(':');
    if (!salt || !hash) return false;

    const actual = Buffer.from(
      pbkdf2Sync(password, salt, 100_000, 32, 'sha256').toString('hex'),
      'hex',
    );
    const expected = Buffer.from(hash, 'hex');

    return actual.length === expected.length && timingSafeEqual(actual, expected);
  }
}
