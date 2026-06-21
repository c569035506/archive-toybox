import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { FriendRequestStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { normalizeFriendPair } from '../../common/utils/date-key';

@Injectable()
export class FriendsService {
  constructor(private readonly prisma: PrismaService) {}

  async searchByShortId(shortId: string) {
    const found = await this.prisma.user.findUnique({
      where: { shortId },
      select: { id: true, shortId: true, nickname: true, avatarUrl: true },
    });

    return {
      users: found
        ? [
            {
              id: found.id,
              short_id: found.shortId,
              nickname: found.nickname,
              avatar_url: found.avatarUrl,
            },
          ]
        : [],
    };
  }

  async sendRequest(fromUserId: string, toUserId: string) {
    if (fromUserId === toUserId) {
      throw new BadRequestException('Cannot add yourself.');
    }

    const target = await this.prisma.user.findUnique({ where: { id: toUserId } });
    if (!target) {
      throw new NotFoundException('User not found.');
    }

    const pair = normalizeFriendPair(fromUserId, toUserId);
    const existingFriendship = await this.prisma.friendship.findUnique({
      where: { userAId_userBId: pair },
    });
    if (existingFriendship) {
      throw new BadRequestException('Already friends.');
    }

    const pending = await this.prisma.friendRequest.findFirst({
      where: {
        fromUserId,
        toUserId,
        status: FriendRequestStatus.PENDING,
      },
    });

    if (pending) {
      return { request_id: pending.id, status: pending.status };
    }

    const request = await this.prisma.friendRequest.create({
      data: { fromUserId, toUserId },
    });

    return { request_id: request.id, status: request.status };
  }

  async listRequests(userId: string) {
    const [incoming, outgoing] = await Promise.all([
      this.prisma.friendRequest.findMany({
        where: { toUserId: userId, status: FriendRequestStatus.PENDING },
        include: {
          fromUser: { select: { id: true, shortId: true, nickname: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.friendRequest.findMany({
        where: { fromUserId: userId, status: FriendRequestStatus.PENDING },
        include: {
          toUser: { select: { id: true, shortId: true, nickname: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return {
      incoming: incoming.map((item) => ({
        id: item.id,
        from_user: {
          id: item.fromUser.id,
          short_id: item.fromUser.shortId,
          nickname: item.fromUser.nickname,
        },
        created_at: item.createdAt,
      })),
      outgoing: outgoing.map((item) => ({
        id: item.id,
        to_user: {
          id: item.toUser.id,
          short_id: item.toUser.shortId,
          nickname: item.toUser.nickname,
        },
        created_at: item.createdAt,
      })),
    };
  }

  async acceptRequest(userId: string, requestId: string) {
    const request = await this.prisma.friendRequest.findFirst({
      where: { id: requestId, toUserId: userId, status: FriendRequestStatus.PENDING },
    });

    if (!request) {
      throw new NotFoundException('Friend request not found.');
    }

    const pair = normalizeFriendPair(request.fromUserId, request.toUserId);

    await this.prisma.$transaction([
      this.prisma.friendRequest.update({
        where: { id: requestId },
        data: { status: FriendRequestStatus.ACCEPTED },
      }),
      this.prisma.friendship.create({ data: pair }),
    ]);

    return { status: 'accepted' };
  }

  async rejectRequest(userId: string, requestId: string) {
    const request = await this.prisma.friendRequest.findFirst({
      where: { id: requestId, toUserId: userId, status: FriendRequestStatus.PENDING },
    });

    if (!request) {
      throw new NotFoundException('Friend request not found.');
    }

    await this.prisma.friendRequest.update({
      where: { id: requestId },
      data: { status: FriendRequestStatus.REJECTED },
    });

    return { status: 'rejected' };
  }

  async listFriends(userId: string) {
    const friendships = await this.prisma.friendship.findMany({
      where: { OR: [{ userAId: userId }, { userBId: userId }] },
      include: {
        userA: { select: { id: true, shortId: true, nickname: true, totalMerit: true } },
        userB: { select: { id: true, shortId: true, nickname: true, totalMerit: true } },
      },
    });

    return {
      friends: friendships.map((item) => {
        const friend = item.userAId === userId ? item.userB : item.userA;
        return {
          id: friend.id,
          short_id: friend.shortId,
          nickname: friend.nickname,
          total_merit: friend.totalMerit,
        };
      }),
    };
  }
}
