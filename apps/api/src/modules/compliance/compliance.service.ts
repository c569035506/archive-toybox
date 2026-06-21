import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ComplianceService {
  constructor(private readonly prisma: PrismaService) {}

  getPrivacyPolicy() {
    return {
      version: '2026-06-21',
      title: '隐私政策',
      content:
        '《存档玩具盒》仅收集提供服务所需的最少信息。你上传的聊天记录仅用于生成本次分析，可随时删除分析记录。请勿上传姓名、电话、地址、公司名等敏感信息。',
    };
  }

  getTerms() {
    return {
      version: '2026-06-21',
      title: '用户协议',
      content:
        '《存档玩具盒》是 AI 情绪表达与电子解压工具，不提供医疗、法律或心理咨询服务。产品中的招财猫等功能仅用于情绪放松，不构成任何现实结果承诺。',
    };
  }

  async recordAck(userId: string, docType: string, version: string) {
    const ack = await this.prisma.privacyAcknowledgement.create({
      data: { userId, docType, version },
    });
    return { id: ack.id, doc_type: ack.docType, version: ack.version };
  }
}
