/**
 * Guests sign in with a username, not an email address.
 *
 * Firebase Auth's email/password provider needs an address, so each username
 * is mapped to a synthetic one under a domain nobody can receive mail at.
 * Auth already enforces that addresses are unique, which gives us username
 * uniqueness for free — a taken username comes back as auth/email-already-in-use.
 *
 * Trade-off: with no real address on file there is no self-service password
 * reset. An organizer resets a password from the Firebase console instead
 * (Authentication → Users → ⋮ → Reset password).
 */
export const USERNAME_DOMAIN = "users.garbanight.local";

export const USERNAME_MIN = 3;
export const USERNAME_MAX = 20;

const VALID = /^[a-z0-9._]+$/;

export function normalizeUsername(input: string): string {
  return input.trim().toLowerCase();
}

/** Returns an error message, or null when the username is usable. */
export function validateUsername(input: string): string | null {
  const username = normalizeUsername(input);
  if (!username) return "Enter a username.";
  if (username.length < USERNAME_MIN)
    return `Username must be at least ${USERNAME_MIN} characters.`;
  if (username.length > USERNAME_MAX)
    return `Username must be ${USERNAME_MAX} characters or fewer.`;
  if (!VALID.test(username))
    return "Use only letters, numbers, full stops and underscores.";
  return null;
}

export function usernameToEmail(input: string): string {
  return `${normalizeUsername(input)}@${USERNAME_DOMAIN}`;
}

/** Turns a stored synthetic address back into the username, for display. */
export function emailToUsername(email: string | undefined): string {
  if (!email) return "";
  return email.endsWith(`@${USERNAME_DOMAIN}`) ? email.split("@")[0] : email;
}
