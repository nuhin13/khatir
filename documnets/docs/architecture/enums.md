# Canonical Enums

> Single source of truth for every enum used across backend (Django TextChoices), mobile (Dart enum), and admin (TS union). All three MUST match the wire values here. When a task adds/changes an enum, update this file first, then all three surfaces.

**Wire value rule:** lowercase snake_case strings. Never integers on the wire.

---

## Role
`landlord` · `manager` · `tenant` · `caretaker` · `admin`

## AdminRole
`super` · `ops` · `finance` · `compliance` · `support`

## Language
`bn` · `en`

## Area (Dhaka zones — extensible via SystemConfig later)
`uttara` · `mirpur` · `mohammadpur` · `dhanmondi` · `banasree` · `gulshan` · `banani` · `bashundhara` · `old_dhaka` · `other`

## UnitType
`apartment` · `room` · `commercial` · `garage` · `other`

## UnitStatus
`occupied` · `vacant` · `maintenance`

## VerificationStatus
`unverified` · `matched` · `not_matched` · `error`

## LeaseStatus
`draft` · `active` · `ended` · `terminated`

## RentScheduleStatus
`pending` · `requested` · `paid` · `overdue`

## RentRequestStatus
`sent` · `proof_submitted` · `verified` · `rejected`

## PaymentProofType
`bkash_txn` · `nagad_txn` · `screenshot` · `photo` · `note`

## Channel
`inapp` · `whatsapp` · `sms` · `email`

## MaintenanceCategory
`plumbing` · `electrical` · `paint` · `structural` · `appliance` · `utility` · `other`

## MaintenanceStatus
`open` · `resolved`

## ExpenseCategory
`plumbing` · `paint` · `electrical` · `structural` · `appliance` · `utility` · `other`

## ExpenseSource
`request` · `manual`

## PricingTierKey
`free` · `per_tenant` · `bundle_20` · `bundle_40` · `unlimited_monthly` · `unlimited_annual`

## BillingCycle
`monthly` · `annual`

## SubscriptionStatus
`active` · `past_due` · `cancelled`

## AIProviderCategory
`chat` · `voice` · `ocr` · `lease`

## NotificationAudienceType
`all` · `role` · `segment` · `specific`

## NotificationStatus
`draft` · `scheduled` · `sending` · `sent` · `failed`

## NotificationDeliveryStatus
`queued` · `sent` · `delivered` · `opened` · `failed`

## SystemConfigType
`int` · `money` · `text` · `bool`

## AdminAuditAction (open set, examples)
`pricing.update` · `killswitch.toggle` · `user.suspend` · `user.refund` · `feature.toggle` · `aiprovider.update` · `notification.send` · `config.update` · `admin.create` · `admin.disable`

## AuditAction (end-user, open set, examples)
`tenant.create` · `tenant.update` · `lease.create` · `rent.request` · `rent.verify` · `expense.create` · `verification.request` · `warning.issue` · `review.create` · `visitor.log`

## ErrorCode (API envelope)
`validation_error` · `not_found` · `permission_denied` · `auth_required` · `auth_invalid` · `conflict` · `rate_limited` · `upstream_unavailable` · `feature_disabled` · `payment_required` · `server_error`

## TaskStatus (epic system, not a product enum)
`todo` · `in-progress` · `blocked` · `review-requested` · `changes-requested` · `done` · `verified`

## ReviewOutcome
`approved` · `changes-requested` · `rejected`

---

## Sync checklist when changing any enum
- [ ] Update this file
- [ ] Backend `TextChoices` in the owning app's `enums.py` (or `core/enums.py` if cross-app)
- [ ] Mobile Dart `enum` with `@JsonValue` matching wire strings
- [ ] Admin TS `as const` union
- [ ] Any DB migration if a stored value changed
- [ ] Tests updated
