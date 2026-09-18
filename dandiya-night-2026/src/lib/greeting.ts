export function timeOfDay(date: Date = new Date()): "morning" | "afternoon" | "evening" | "night" {
  const hour = date.getHours();
  if (hour >= 5 && hour < 12) return "morning";
  if (hour >= 12 && hour < 17) return "afternoon";
  if (hour >= 17 && hour < 21) return "evening";
  return "night";
}

export function greetingFor(name: string) {
  const firstName = name.trim().split(" ")[0];
  return `Namaste ${firstName}, good ${timeOfDay()}.`;
}
