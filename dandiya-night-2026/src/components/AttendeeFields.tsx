"use client";

import { AnimatePresence, motion } from "framer-motion";
import FormInput from "@/components/FormInput";
import { KID_AGE_LIMIT, type PartyCounts, totalPeople } from "@/lib/pricing";

export interface KidEntry {
  name: string;
  age: string;
}

interface AttendeeFieldsProps {
  party: PartyCounts;
  adults: string[];
  students: string[];
  kids: KidEntry[];
  leadPhone: string;
  onAdultChange: (index: number, value: string) => void;
  onStudentChange: (index: number, value: string) => void;
  onKidChange: (index: number, field: keyof KidEntry, value: string) => void;
  onLeadPhoneChange: (value: string) => void;
}

function Group({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="text-xs uppercase tracking-widest text-[var(--muted)] mb-2">{title}</p>
      <div className="flex flex-col gap-3">{children}</div>
    </div>
  );
}

export default function AttendeeFields({
  party,
  adults,
  students,
  kids,
  leadPhone,
  onAdultChange,
  onStudentChange,
  onKidChange,
  onLeadPhoneChange,
}: AttendeeFieldsProps) {
  const people = totalPeople(party);
  if (people === 0) return null;

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={`${party.adults}-${party.students}-${party.kids}`}
        initial={{ opacity: 0, y: 6 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -6 }}
        transition={{ duration: 0.2, ease: "easeInOut" }}
        className="flex flex-col gap-5 pt-1"
      >
        {adults.length > 0 && (
          <Group title={adults.length > 1 ? "Adults" : "Adult"}>
            {adults.map((value, i) => (
              <FormInput
                key={`adult-${i}`}
                id={`adult_${i}`}
                label={adults.length > 1 ? `Adult ${i + 1} — Name` : "Name"}
                value={value}
                onChange={(e) => onAdultChange(i, e.target.value)}
                required
              />
            ))}
          </Group>
        )}

        {students.length > 0 && (
          <Group title={students.length > 1 ? "Students" : "Student"}>
            {students.map((value, i) => (
              <FormInput
                key={`student-${i}`}
                id={`student_${i}`}
                label={students.length > 1 ? `Student ${i + 1} — Name` : "Name"}
                value={value}
                onChange={(e) => onStudentChange(i, e.target.value)}
                required
              />
            ))}
            <p className="text-[11px] text-[var(--muted)] -mt-1">
              Every student in the group must carry a valid student ID to the gate.
            </p>
          </Group>
        )}

        {kids.length > 0 && (
          <Group title={kids.length > 1 ? "Kids" : "Kid"}>
            {kids.map((kid, i) => (
              <div key={`kid-${i}`} className="grid grid-cols-[1fr_88px] gap-3">
                <FormInput
                  id={`kid_${i}_name`}
                  label={kids.length > 1 ? `Kid ${i + 1} — Name` : "Name"}
                  value={kid.name}
                  onChange={(e) => onKidChange(i, "name", e.target.value)}
                  required
                />
                <FormInput
                  id={`kid_${i}_age`}
                  label="Age"
                  type="number"
                  min={0}
                  max={KID_AGE_LIMIT - 1}
                  inputMode="numeric"
                  value={kid.age}
                  onChange={(e) => onKidChange(i, "age", e.target.value)}
                  required
                />
              </div>
            ))}
            <p className="text-[11px] text-[var(--muted)] -mt-1">
              Kids must be below {KID_AGE_LIMIT} and stay with a parent or guardian all night.
            </p>
          </Group>
        )}

        <Group title="Contact for this booking">
          <FormInput
            id="lead_phone"
            label="Phone Number"
            value={leadPhone}
            onChange={(e) => onLeadPhoneChange(e.target.value)}
            autoComplete="tel"
            inputMode="tel"
            required
          />
        </Group>
      </motion.div>
    </AnimatePresence>
  );
}
