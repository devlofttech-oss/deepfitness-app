"use strict";
// Deep Fitness — Cloud Functions.
//
// Kept to the work a client cannot be trusted to do: privileged writes, push
// dispatch and scheduled jobs. Everything else stays client-direct against
// Firestore, with the security rules as the access control.
Object.defineProperty(exports, "__esModule", { value: true });
exports.inactivityNudge = exports.dailyReminders = exports.onBookingCancelled = exports.sendAnnouncement = exports.createMember = exports.setUserRole = exports.onMemberCreate = void 0;
var members_1 = require("./members");
Object.defineProperty(exports, "onMemberCreate", { enumerable: true, get: function () { return members_1.onMemberCreate; } });
Object.defineProperty(exports, "setUserRole", { enumerable: true, get: function () { return members_1.setUserRole; } });
Object.defineProperty(exports, "createMember", { enumerable: true, get: function () { return members_1.createMember; } });
var announcements_1 = require("./announcements");
Object.defineProperty(exports, "sendAnnouncement", { enumerable: true, get: function () { return announcements_1.sendAnnouncement; } });
var bookings_1 = require("./bookings");
Object.defineProperty(exports, "onBookingCancelled", { enumerable: true, get: function () { return bookings_1.onBookingCancelled; } });
var scheduled_1 = require("./scheduled");
Object.defineProperty(exports, "dailyReminders", { enumerable: true, get: function () { return scheduled_1.dailyReminders; } });
Object.defineProperty(exports, "inactivityNudge", { enumerable: true, get: function () { return scheduled_1.inactivityNudge; } });
//# sourceMappingURL=index.js.map