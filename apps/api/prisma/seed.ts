import { PrismaClient, MeditationTrackCategory } from '@prisma/client';

const prisma = new PrismaClient();

const tracks = [
  {
    id: 'great-compassion-demo',
    title: '大悲咒静心版',
    category: MeditationTrackCategory.GREAT_COMPASSION_MANTRA,
    audioUrl: '/audio/dabei-mantra.mp3',
    durationSec: 1722,
  },
  {
    id: 'calm-breathing-demo',
    title: '三分钟呼吸练习',
    category: MeditationTrackCategory.CALM_MUSIC,
    audioUrl: '/audio/calm-breathing-demo.wav',
    durationSec: 90,
  },
  {
    id: 'soft-noise-demo',
    title: '柔和白噪音',
    category: MeditationTrackCategory.WHITE_NOISE,
    audioUrl: '/audio/soft-noise-demo.wav',
    durationSec: 120,
  },
  {
    id: 'rain-window-demo',
    title: '窗边小雨',
    category: MeditationTrackCategory.NATURE_SOUND,
    audioUrl: '/audio/rain-window-demo.wav',
    durationSec: 120,
  },
];

async function main() {
  await prisma.user.upsert({
    where: { id: 'demo-user' },
    update: {},
    create: {
      id: 'demo-user',
      shortId: 'TOYBOX001',
      email: 'demo@archive-toybox.local',
      nickname: '玩具盒用户',
    },
  });

  await prisma.user.upsert({
    where: { id: 'demo-friend' },
    update: {},
    create: {
      id: 'demo-friend',
      shortId: 'TOYBOX002',
      email: 'friend@archive-toybox.local',
      nickname: '测试好友',
    },
  });

  for (const track of tracks) {
    await prisma.meditationTrack.upsert({
      where: { id: track.id },
      update: track,
      create: track,
    });
  }
}

main()
  .finally(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
