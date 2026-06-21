export function getDateKey(date = new Date()): string {
  return date.toISOString().slice(0, 10);
}

export function normalizeFriendPair(userAId: string, userBId: string) {
  return userAId < userBId
    ? { userAId, userBId }
    : { userAId: userBId, userBId: userAId };
}
