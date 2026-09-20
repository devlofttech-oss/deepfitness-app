export const PRESENTER = "SK Presents";
export const EVENT_NAME = "Dandiya Night 2026";
export const EVENT_TAGLINE = "Feel the Rhythm of Tradition!";
export const EVENT_SUBTAGLINE = "Dance · Connect · Celebrate";

export const EVENT_DATE = "17th October 2026";
export const EVENT_TIME = "5:30 PM onwards";
/** Doors open — drives the countdown on the landing and event pages. */
export const EVENT_AT = new Date("2026-10-17T17:30:00+05:30").getTime();

export const VENUE_NAME = "Perfect X Arena";
export const VENUE_ADDRESS =
  "Sy 85/2, near sea food joint, Bogadi 2nd Stage, Bogadi 2nd Stage North, Mysuru, Karnataka 570026";
export const VENUE_SHORT = "Perfect X Arena · Bogadi, Mysuru";
export const VENUE_MAP_URL =
  "https://www.google.com/maps/search/?api=1&query=" +
  encodeURIComponent("Perfect X Arena, Bogadi 2nd Stage, Mysuru, Karnataka 570026");

/** Hard cap on passes for the night — drives the scarcity copy on the site. */
export const TOTAL_SLOTS = 400;

/** Most people one booking may cover; bigger groups book twice or call us. */
export const MAX_PARTY_SIZE = 12;

export const CONTACT_PHONES = ["9019550010", "9743625871"];

/**
 * UPI payment QR shown on the booking page. Drop the image in at
 * public/payment-qr.jpeg and flip `ready` to true — until then the booking
 * page shows a "call us for payment details" placeholder instead.
 */
export const PAYMENT_QR = {
  src: "/payment-qr.jpeg",
  ready: true,
};

/** Optional: shown under the QR if set, e.g. "skevents@okicici". */
export const UPI_ID = "arjunkariyappa1990@oksbi";

export const HIGHLIGHTS = [
  "Complimentary Dandiya Sticks",
  "Live Music & DJ",
  "Food",
  "Expert Choreographer to Help You Move",
  "Selfie Booth",
  "Attractive Decorations",
  "Spacious Outdoor Field for Group Performances",
];

export const ABOUT =
  "One night of garba under the open sky — live music and a DJ driving the beat, a choreographer on the floor to get every pair of feet moving, dinner served hot, and a field wide enough for your whole group to perform. Dandiya sticks are on us. Come in your finest chaniya choli and kediyu. Let's garba!";
