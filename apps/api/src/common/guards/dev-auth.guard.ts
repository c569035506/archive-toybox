import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CurrentUserPayload } from '../decorators/current-user.decorator';

type RequestWithUser = {
  headers: Record<string, string | string[] | undefined>;
  user?: CurrentUserPayload;
};

@Injectable()
export class DevAuthGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<RequestWithUser>();
    const authHeader = request.headers.authorization;
    const headerUserId = request.headers['x-user-id'];

    let userId: string | undefined;
    if (typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
      const token = authHeader.slice(7);
      if (token.startsWith('user:')) {
        userId = token.slice(5);
      }
    }

    if (!userId) {
      userId = Array.isArray(headerUserId) ? headerUserId[0] : headerUserId;
    }

    const user = await this.prisma.user.findFirst({
      where: userId ? { id: userId } : { id: 'demo-user' },
      select: {
        id: true,
        shortId: true,
        email: true,
        nickname: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Missing demo user. Run pnpm seed first.');
    }

    request.user = user;
    return true;
  }
}
