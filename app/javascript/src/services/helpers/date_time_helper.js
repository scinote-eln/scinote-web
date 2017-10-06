// @flow

export function isToday(inputDate: Date): boolean {
  const todaysDate = new Date();
  return inputDate.setHours(0, 0, 0, 0) == todaysDate.setHours(0, 0, 0, 0);
}
