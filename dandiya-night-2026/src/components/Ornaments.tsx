/**
 * Hand-drawn festival ornaments, all inline SVG so they inherit currentColor
 * and never cost a network round trip. Used across the hero, event details
 * and ticket.
 */

type IconProps = { size?: number; className?: string };

function svgProps({ size = 20, className = "" }: IconProps) {
  return {
    width: size,
    height: size,
    viewBox: "0 0 24 24",
    fill: "none",
    className,
    "aria-hidden": true as const,
  };
}

/**
 * Two crossed dandiya sticks: thick rods, a decorative band near each grip and
 * a bulb at every tip, so it still reads as sticks — not a close icon — at
 * 20px.
 */
export function DandiyaIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <g stroke="currentColor" strokeWidth="2.1" strokeLinecap="round">
        <path d="M6.6 17.4 17.4 6.6" />
        <path d="M6.6 6.6 17.4 17.4" />
      </g>
      <g fill="currentColor">
        <circle cx="5.2" cy="18.8" r="2.2" />
        <circle cx="18.8" cy="5.2" r="2.2" />
        <circle cx="5.2" cy="5.2" r="2.2" />
        <circle cx="18.8" cy="18.8" r="2.2" />
      </g>
      <g stroke="currentColor" strokeWidth="1.1" strokeLinecap="round" opacity="0.55">
        <path d="M7.6 14.6 9.4 16.4" />
        <path d="M14.6 16.4 16.4 14.6" />
        <path d="M7.6 9.4 9.4 7.6" />
        <path d="M14.6 7.6 16.4 9.4" />
      </g>
    </svg>
  );
}

/** A lit diya. */
export function DiyaIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path
        d="M11.9 4c1.9 2 2.8 3.4 2.8 4.7a2.8 2.8 0 0 1-5.6 0C9.1 7.4 10 6 11.9 4Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <path
        d="M3.5 13.5h17c-.6 3.4-3.9 5.8-8.5 5.8s-7.9-2.4-8.5-5.8Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <path d="M12 11.5v2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

/** Dhol / drum. */
export function DholIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path d="M6 8h12l-1.2 8.5H7.2L6 8Z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
      <ellipse cx="12" cy="8" rx="6" ry="2.2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M7 11l10 3M7 14l10-3" stroke="currentColor" strokeWidth="1.1" strokeLinecap="round" opacity="0.7" />
      <path d="M4 6.5 6 8M20 6.5 18 8" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" />
    </svg>
  );
}

/** Speaker / DJ. */
export function SpeakerIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <rect x="5" y="3" width="14" height="18" rx="2.5" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="12" cy="14.5" r="3.6" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="12" cy="6.8" r="1.5" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

/** Thali of food. */
export function ThaliIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <circle cx="12" cy="12" r="8.5" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="12" cy="12" r="4.6" stroke="currentColor" strokeWidth="1.2" opacity="0.7" />
      <circle cx="9.3" cy="9.3" r="1.2" fill="currentColor" />
      <circle cx="14.7" cy="9.3" r="1.2" fill="currentColor" />
      <circle cx="12" cy="15.2" r="1.2" fill="currentColor" />
    </svg>
  );
}

/** Dancing figure — the choreographer. */
export function DancerIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <circle cx="12.6" cy="4.6" r="2" stroke="currentColor" strokeWidth="1.5" />
      <path
        d="M12.4 6.8 10.6 12l2.6 2.4.8 6.4"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path d="m10.6 12-4 3.2m6.6-.8-3.8 6.4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      <path d="M11.4 8.4 6.6 7M13 8.2l4.8-2.2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

/** Selfie / camera. */
export function CameraIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path
        d="M4 8h3l1.5-2h7L17 8h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <circle cx="12" cy="14" r="3.3" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

/** Marigold / decoration flower. */
export function MarigoldIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.5" />
      {Array.from({ length: 8 }).map((_, i) => (
        <ellipse
          key={i}
          cx="12"
          cy="5.6"
          rx="1.7"
          ry="2.7"
          stroke="currentColor"
          strokeWidth="1.3"
          transform={`rotate(${i * 45} 12 12)`}
        />
      ))}
    </svg>
  );
}

/** Open field / ground. */
export function FieldIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path d="M2.5 17.5 12 12l9.5 5.5-9.5 4-9.5-4Z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
      <path d="M8 10.5V4.6M16 10.5V6.6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      <path d="M8 4.6c2.4-1.6 3.4.9 5 0M16 6.6c1.6-1.1 2.3.6 3.4 0" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
    </svg>
  );
}

export function CalendarIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <rect x="3" y="5" width="18" height="16" rx="2" stroke="currentColor" strokeWidth="1.6" />
      <path d="M3 9.5h18M8 3v4M16 3v4" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
    </svg>
  );
}

export function ClockIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.6" />
      <path d="M12 7v5l3.5 2" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function PinIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path
        d="M12 21s7-6.5 7-11.5A7 7 0 0 0 5 9.5C5 14.5 12 21 12 21Z"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinejoin="round"
      />
      <circle cx="12" cy="9.5" r="2.3" stroke="currentColor" strokeWidth="1.6" />
    </svg>
  );
}

export function PhoneIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path
        d="M6.5 3.5h3l1.5 4-2 1.5a12 12 0 0 0 6 6l1.5-2 4 1.5v3a2 2 0 0 1-2.2 2A16.5 16.5 0 0 1 4.5 5.7 2 2 0 0 1 6.5 3.5Z"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function TicketIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path
        d="M3 7.5A1.5 1.5 0 0 1 4.5 6h15A1.5 1.5 0 0 1 21 7.5v2a2.5 2.5 0 0 0 0 5v2a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 16.5v-2a2.5 2.5 0 0 0 0-5v-2Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <path d="M14 8v8" stroke="currentColor" strokeWidth="1.3" strokeDasharray="2 2.4" strokeLinecap="round" />
    </svg>
  );
}

/** Peacock feather. */
export function PeacockIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      {/* barbs fanning out around the eye */}
      <g stroke="currentColor" strokeWidth="1.1" strokeLinecap="round" opacity="0.75">
        {[-58, -38, -19, 0, 19, 38, 58].map((deg) => (
          <path key={deg} d="M12 6.4V1.4" transform={`rotate(${deg} 12 9)`} />
        ))}
        <path d="M8.4 13.6 5 15.4M15.6 13.6 19 15.4M8.8 16.4 6 18.6M15.2 16.4 18 18.6" />
      </g>
      {/* the eye */}
      <ellipse cx="12" cy="9" rx="4.6" ry="5.2" stroke="currentColor" strokeWidth="1.5" />
      <ellipse cx="12" cy="8.6" rx="2.2" ry="2.6" stroke="currentColor" strokeWidth="1.2" />
      <circle cx="12" cy="8.6" r="0.9" fill="currentColor" />
      {/* quill */}
      <path d="M12 14.2v7.4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

/** Kalash — pot with coconut and mango leaves. */
export function KalashIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path
        d="M8 10.6h8c1.1 2.1 1.1 4.2 0 6.3-1.1 1.7-2.4 2.5-4 2.5s-2.9-.8-4-2.5c-1.1-2.1-1.1-4.2 0-6.3Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <rect x="7" y="8.8" width="10" height="1.9" rx="0.95" stroke="currentColor" strokeWidth="1.3" />
      <circle cx="12" cy="4.6" r="1.7" stroke="currentColor" strokeWidth="1.3" />
      <path
        d="M12 6.3c-1.7-.5-2.8-1.7-3.2-3.4 1.7.1 2.8.9 3.2 2.3.4-1.4 1.5-2.2 3.2-2.3-.4 1.7-1.5 2.9-3.2 3.4Z"
        stroke="currentColor"
        strokeWidth="1.3"
        strokeLinejoin="round"
      />
      <path d="M12 6.3v2.5" stroke="currentColor" strokeWidth="1.3" />
    </svg>
  );
}

/** Lotus in bloom. */
export function LotusIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path
        d="M12 5.5c1.9 2.3 2.8 4.3 2.8 6.2 0 1.3-1 2.2-2.8 2.2s-2.8-.9-2.8-2.2c0-1.9.9-3.9 2.8-6.2Z"
        stroke="currentColor"
        strokeWidth="1.4"
        strokeLinejoin="round"
      />
      <path
        d="M12 13.9c-2.8 0-4.9-1.2-6.3-3.5 3-.5 5.2.2 6.3 2.1 1.1-1.9 3.3-2.6 6.3-2.1-1.4 2.3-3.5 3.5-6.3 3.5Z"
        stroke="currentColor"
        strokeWidth="1.4"
        strokeLinejoin="round"
      />
      <path
        d="M3 13.2c2.1 3.4 5.2 5.1 9 5.1s6.9-1.7 9-5.1"
        stroke="currentColor"
        strokeWidth="1.4"
        strokeLinecap="round"
      />
    </svg>
  );
}

/** Paisley / ambi motif. */
export function PaisleyIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path
        d="M14.8 2.8c3.9 1.7 5.6 5.6 4.4 9.5-1.2 4-4.8 6.7-8.8 6.7-3 0-5.4-1.9-5.4-4.6 0-2.5 1.9-4.3 4.3-4.3 1.9 0 3.3 1.2 3.3 2.8 0 1.3-.9 2.2-2.1 2.2"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="10.4" cy="14.6" r="1" fill="currentColor" />
    </svg>
  );
}

/** Ghungroo — a string of ankle bells. */
export function GhungrooIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path d="M3 6.5c3 2.6 6 3.9 9 3.9s6-1.3 9-3.9" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" />
      {[
        { x: 6, y: 13 },
        { x: 12, y: 15.4 },
        { x: 18, y: 13 },
      ].map((b, i) => (
        <g key={i}>
          <path
            d={`M${b.x} ${b.y - 3.6}v1.4`}
            stroke="currentColor"
            strokeWidth="1.2"
            strokeLinecap="round"
          />
          <circle cx={b.x} cy={b.y} r="2.6" stroke="currentColor" strokeWidth="1.3" />
          <path d={`M${b.x - 1.4} ${b.y + 1.9}h2.8`} stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
        </g>
      ))}
    </svg>
  );
}

/** Shield — safety and security. */
export function ShieldIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <path
        d="M12 3l7 2.6v5.6c0 4.3-2.9 8-7 9.8-4.1-1.8-7-5.5-7-9.8V5.6L12 3Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <path d="m9 12 2.2 2.2L15.4 10" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

/** Two adults and a child — family rules. */
export function FamilyIcon(props: IconProps) {
  return (
    <svg {...svgProps(props)}>
      <circle cx="7" cy="6" r="2.1" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="16.4" cy="6" r="2.1" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="12" cy="13.4" r="1.6" stroke="currentColor" strokeWidth="1.4" />
      <path
        d="M3.6 20c0-3 1.5-5 3.4-5s3.4 2 3.4 5M13 20c0-3 1.5-5 3.4-5s3.4 2 3.4 5"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
      <path d="M9.6 20.5c0-1.9 1.1-3.1 2.4-3.1s2.4 1.2 2.4 3.1" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" />
    </svg>
  );
}

/** Maps a rule group from lib/rules.ts onto an ornament. */
export const RULE_ICONS: Record<string, (p: IconProps) => React.JSX.Element> = {
  entry: TicketIcon,
  safety: ShieldIcon,
  conduct: MarigoldIcon,
  family: FamilyIcon,
  floor: DancerIcon,
  media: CameraIcon,
};

/** Maps a highlight line from lib/event.ts onto an ornament. */
export const HIGHLIGHT_ICONS: Record<string, (p: IconProps) => React.JSX.Element> = {
  "Complimentary Dandiya Sticks": DandiyaIcon,
  "Live Music & DJ": SpeakerIcon,
  "Delicious Dinner": ThaliIcon,
  "Expert Choreographer to Help You Move": DancerIcon,
  "Selfie Booth": CameraIcon,
  "Attractive Decorations": MarigoldIcon,
  "Spacious Outdoor Field for Group Performances": FieldIcon,
};

/**
 * A concentric mandala. Sits behind the hero at low opacity and turns very
 * slowly — the CSS animation is declared inline so no keyframes leak into
 * the global sheet.
 */
export function Mandala({ className = "", spin = 90 }: { className?: string; spin?: number }) {
  const petals = Array.from({ length: 16 });
  const inner = Array.from({ length: 8 });

  return (
    <svg
      viewBox="0 0 200 200"
      className={className}
      aria-hidden
      style={{ animation: `mandala-spin ${spin}s linear infinite` }}
    >
      <style>{"@keyframes mandala-spin{from{transform:rotate(0)}to{transform:rotate(360deg)}}"}</style>
      <g stroke="currentColor" fill="none" strokeWidth="0.9">
        <circle cx="100" cy="100" r="96" strokeDasharray="3 5" />
        <circle cx="100" cy="100" r="78" />
        <circle cx="100" cy="100" r="44" />
        <circle cx="100" cy="100" r="16" />
        {petals.map((_, i) => (
          <ellipse
            key={`p${i}`}
            cx="100"
            cy="38"
            rx="9"
            ry="24"
            transform={`rotate(${i * 22.5} 100 100)`}
          />
        ))}
        {inner.map((_, i) => (
          <path
            key={`i${i}`}
            d="M100 84c7 6 7 14 0 20-7-6-7-14 0-20Z"
            transform={`rotate(${i * 45} 100 100)`}
          />
        ))}
        {petals.map((_, i) => (
          <circle key={`d${i}`} cx="100" cy="60" r="1.8" transform={`rotate(${i * 22.5} 100 100)`} fill="currentColor" />
        ))}
      </g>
    </svg>
  );
}

/**
 * A rangoli corner flourish — quarter arcs and petals, meant to sit in the
 * corner of a card or section at low opacity.
 */
export function RangoliCorner({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 80 80" className={className} aria-hidden fill="none">
      <g stroke="currentColor" strokeWidth="1">
        <path d="M0 76a76 76 0 0 0 76-76" strokeDasharray="3 4" />
        <path d="M0 58a58 58 0 0 0 58-58" />
        <path d="M0 38a38 38 0 0 0 38-38" />
        {[10, 30, 50, 70].map((deg) => (
          <ellipse
            key={deg}
            cx="0"
            cy="0"
            rx="6"
            ry="22"
            transform={`rotate(${deg}) translate(0 46)`}
          />
        ))}
        <circle cx="0" cy="0" r="10" />
      </g>
      <circle cx="0" cy="0" r="3.5" fill="currentColor" />
    </svg>
  );
}

/**
 * A horizontal rule with an ornament in the middle, for breaking sections
 * apart the way a wedding card would.
 */
export function SectionDivider({
  icon: Icon = LotusIcon,
  className = "",
}: {
  icon?: (p: IconProps) => React.JSX.Element;
  className?: string;
}) {
  return (
    <div className={`flex items-center justify-center gap-3 text-[var(--gold-3)] ${className}`}>
      <span className="h-px flex-1 max-w-24 bg-gradient-to-r from-transparent to-[var(--gold-4)]" />
      <Icon size={18} />
      <span className="h-px flex-1 max-w-24 bg-gradient-to-l from-transparent to-[var(--gold-4)]" />
    </div>
  );
}

/**
 * The hero illustration: two dancers mid-garba under an arch, sticks raised,
 * diyas along the ground. Drawn once and mirrored, so both figures stay in
 * step.
 */
export function GarbaScene({ className = "" }: { className?: string }) {
  const dancer = (
    <g fill="none" strokeLinecap="round" strokeLinejoin="round">
      {/* dupatta */}
      <path d="M84 58c2-9 20-9 22 0" stroke="currentColor" strokeWidth="1.6" opacity="0.8" />
      <circle cx="95" cy="62" r="9" stroke="currentColor" strokeWidth="1.8" />
      {/* braid */}
      <path d="M87 68c-4 5-5 10-4 15" stroke="currentColor" strokeWidth="1.4" opacity="0.7" />
      {/* torso */}
      <path d="M95 71v18" stroke="currentColor" strokeWidth="1.8" />
      {/* chaniya */}
      <path d="M95 88 75 126q20 8 40 0Z" stroke="currentColor" strokeWidth="1.8" />
      <path d="M81 114q14 6 28 0" stroke="currentColor" strokeWidth="1.2" opacity="0.6" />
      {/* arms */}
      <path d="M96 79 118 66" stroke="currentColor" strokeWidth="1.8" />
      <path d="M94 79 74 71" stroke="currentColor" strokeWidth="1.8" />
      {/* dandiya sticks in each hand */}
      <g stroke="currentColor" strokeWidth="1.8">
        <path d="M112 58 126 72" />
        <path d="M68 64 80 78" />
      </g>
      <g fill="currentColor">
        <circle cx="111" cy="57" r="2" />
        <circle cx="127" cy="73" r="2" />
        <circle cx="67" cy="63" r="2" />
        <circle cx="81" cy="79" r="2" />
      </g>
    </g>
  );

  return (
    <svg viewBox="0 0 260 170" className={className} aria-hidden fill="none">
      {/* arch */}
      <path
        d="M22 162V78a108 108 0 0 1 216 0v84"
        stroke="currentColor"
        strokeWidth="1.2"
        opacity="0.5"
      />
      <path
        d="M34 162V80a96 96 0 0 1 192 0v82"
        stroke="currentColor"
        strokeWidth="1"
        strokeDasharray="4 5"
        opacity="0.4"
      />
      {/* ground */}
      <path d="M18 162h224" stroke="currentColor" strokeWidth="1.2" opacity="0.5" />

      {dancer}
      <g transform="translate(260 0) scale(-1 1)">{dancer}</g>

      {/* diyas along the ground */}
      {[46, 130, 214].map((x) => (
        <g key={x} transform={`translate(${x} 150)`}>
          <path d="M-8 4h16c-.8 4.4-4 7-8 7s-7.2-2.6-8-7Z" stroke="currentColor" strokeWidth="1.3" />
          <path d="M0 3c1.8-2 2.6-3.4 2.6-4.6A2.6 2.6 0 0 0 0-4a2.6 2.6 0 0 0-2.6 2.4C-2.6-.4-1.8 1 0 3Z" fill="currentColor" opacity="0.85" />
        </g>
      ))}

      {/* sparkles */}
      {[
        [60, 40],
        [200, 36],
        [130, 24],
        [96, 30],
        [168, 46],
      ].map(([x, y]) => (
        <path
          key={`${x}-${y}`}
          d={`M${x} ${y - 5}l1.4 3.6L${x + 5} ${y}l-3.6 1.4L${x} ${y + 5}l-1.4-3.6L${x - 5} ${y}l3.6-1.4Z`}
          fill="currentColor"
          opacity="0.65"
        />
      ))}
    </svg>
  );
}

/**
 * Toran — the strip of leaves and bells hung across a doorway. Rendered as a
 * repeating scallop so it stretches to any width.
 */
export function Toran({ className = "" }: { className?: string }) {
  const segments = Array.from({ length: 24 });

  return (
    <svg
      viewBox="0 0 480 26"
      preserveAspectRatio="none"
      className={className}
      aria-hidden
    >
      <line x1="0" y1="2" x2="480" y2="2" stroke="currentColor" strokeWidth="1.4" />
      {segments.map((_, i) => {
        const x = i * 20 + 10;
        const long = i % 2 === 0;
        return (
          <g key={i} stroke="currentColor" fill="none" strokeWidth="1.2">
            <path d={`M${x - 10} 2 Q ${x} ${long ? 16 : 11} ${x + 10} 2`} />
            <path
              d={`M${x} ${long ? 12 : 8} l0 ${long ? 6 : 4}`}
              strokeLinecap="round"
            />
            {long ? (
              <path
                d={`M${x} 18 q -3.4 3 0 6 q 3.4 -3 0 -6 Z`}
                fill="currentColor"
                fillOpacity="0.55"
              />
            ) : (
              <circle cx={x} cy="14" r="1.8" fill="currentColor" fillOpacity="0.55" />
            )}
          </g>
        );
      })}
    </svg>
  );
}
