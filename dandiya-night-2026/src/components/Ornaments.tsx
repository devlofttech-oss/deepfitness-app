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
  kids: FamilyIcon,
  event: CameraIcon,
};

/** Maps a highlight line from lib/event.ts onto an ornament. */
export const HIGHLIGHT_ICONS: Record<string, (p: IconProps) => React.JSX.Element> = {
  "Complimentary Dandiya Sticks": DandiyaIcon,
  "Live Music & DJ": SpeakerIcon,
  "Food": ThaliIcon,
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
 * A swagged string of festival bulbs, the kind hung across a garba ground.
 * Each bulb glows on a staggered cycle so the string twinkles slowly.
 */
export function StringLights({ className = "" }: { className?: string }) {
  const swags = Array.from({ length: 16 });
  const span = 30;

  return (
    <svg viewBox="0 0 480 30" preserveAspectRatio="none" className={className} aria-hidden>
      <style>
        {"@keyframes bulb-glow{0%,100%{opacity:.45}50%{opacity:1}}" +
          "@media (prefers-reduced-motion: reduce){.bulb{animation:none!important;opacity:.85}}"}
      </style>
      {swags.map((_, i) => {
        const x = i * span;
        return (
          <path
            key={`w${i}`}
            d={`M${x} 2 Q ${x + span / 2} 15 ${x + span} 2`}
            stroke="currentColor"
            strokeWidth="1"
            fill="none"
            opacity="0.5"
          />
        );
      })}
      {swags.map((_, i) => {
        const x = i * span + span / 2;
        return (
          <g key={`b${i}`} className="bulb" style={{ animation: `bulb-glow ${2.6 + (i % 4) * 0.5}s ease-in-out ${(i % 5) * 0.3}s infinite` }}>
            <path d={`M${x} 9.4v2.4`} stroke="currentColor" strokeWidth="1" opacity="0.6" />
            <circle cx={x} cy="15" r="3" fill={i % 2 === 0 ? "var(--marigold)" : "var(--gold-2)"} />
            <circle cx={x} cy="15" r="6" fill={i % 2 === 0 ? "var(--marigold)" : "var(--gold-2)"} opacity="0.18" />
          </g>
        );
      })}
    </svg>
  );
}

/** A hanging lantern, lit from within. Sways gently where it is used. */
export function Lantern({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 48 96" className={className} aria-hidden fill="none">
      {/* chain */}
      <path d="M24 0v16" stroke="currentColor" strokeWidth="1.4" strokeDasharray="3 3" opacity="0.7" />
      <path d="M14 20h20" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
      <path d="M17 20c2-3 12-3 14 0" stroke="currentColor" strokeWidth="1.3" />
      {/* body */}
      <path
        d="M13 26h22c3 6 3 22 0 30H13c-3-8-3-24 0-30Z"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinejoin="round"
      />
      <path d="M13 26h22" stroke="currentColor" strokeWidth="1.6" />
      <path d="M13 56h22" stroke="currentColor" strokeWidth="1.6" />
      {/* lit panels */}
      <path d="M19 30v22M29 30v22" stroke="currentColor" strokeWidth="1" opacity="0.55" />
      <ellipse cx="24" cy="41" rx="7" ry="9" fill="var(--marigold)" opacity="0.28" />
      <path
        d="M24 36c2.4 2.8 3.4 4.6 3.4 6.2a3.4 3.4 0 0 1-6.8 0c0-1.6 1-3.4 3.4-6.2Z"
        fill="var(--marigold)"
        opacity="0.9"
      />
      {/* base + tassel */}
      <path d="M17 60h14l-2 5H19l-2-5Z" stroke="currentColor" strokeWidth="1.4" strokeLinejoin="round" />
      <path d="M24 65v9" stroke="currentColor" strokeWidth="1.2" />
      <path d="M24 74c-2.6 3-2.6 7 0 10 2.6-3 2.6-7 0-10Z" fill="currentColor" opacity="0.6" />
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
