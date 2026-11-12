# Security rules tests

The rules are the access control, so these run against the real
`firestore.rules` and `storage.rules` from the repository root: change a
rule and these fail, which is the only way they earn their keep.

## Running them

```bash
cd rules-tests
npm install
npm test
```

`npm test` starts the Firestore and Storage emulators, runs the suite and
shuts them down. It needs the Firebase CLI and a JDK, which the emulators
require.

## What is covered

- **members** — who reads whom, and the protected fields a member may not
  write about themselves, including smuggling one alongside a legal edit.
- **training** — the exercise library, the progress-only update on an
  assigned plan, and completion logs being append-only to everybody.
- **bookings** — booking and cancelling your own, the counters a member
  may move, the ones they may not, and the full booking transaction the
  app commits.
- **content** — events, one RSVP per member, and announcements being
  read-only from every client.
- The catch-all: a collection with no rules of its own is denied.

## Windows

The emulators need a working AF_UNIX socket, because Java's selector uses
one for its internal self-pipe. On some Windows machines that `connect`
returns `EINVAL` and the Firestore emulator dies on startup with
`failed to create a child event loop`. Ordinary TCP loopback working is
not enough — it is a different mechanism.

If that happens:

1. Try a JDK 17 build (Temurin) rather than the newest release, and point
   `JAVA_HOME` at it for the run. The emulator is tested against the
   older LTS releases.
2. Check `%TEMP%` points at a local NTFS path. Java puts the socket file
   there, and a network or removable drive will not serve one.
3. Failing both, run the suite in CI — `.github/workflows/ci.yml` runs it
   on Linux on every push, which is the same thing without the machine
   in the way.
