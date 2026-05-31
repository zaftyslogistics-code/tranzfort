# Super Load — Admin SOP (v1)

**RPC:** `request_super_load` (supplier app) · **Admin review:** Super Ops / verification queue

## When a request arrives

1. Open the load in Admin Super Ops (or verification-linked load view).
2. Confirm supplier is **platform access approved** and load is off marketplace or eligible per policy.
3. Review route, material, trucks needed, and any supplier notes.

## Approve path

1. Verify off-platform payment / commercial terms are **not** guaranteed by TranZfort (introduction only).
2. Set Super Load state to approved per admin RPC/workflow.
3. Notify supplier via existing notification path if configured.

## Reject path

1. Record rejection reason in admin feedback JSON.
2. Supplier sees status on load detail; support copy references admin-managed state.

## Do not

- Promise payment, delivery, or insurance in admin notes.
- Share raw Aadhaar/PAN with counterparties.

## Dead RPC check

If `request_super_load` returns an error, check migration grants and `auth.uid()` = load owner supplier. Escalate to engineering if RPC missing on environment.
