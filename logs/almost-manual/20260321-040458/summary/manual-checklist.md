# Admin manual checklist

- Sign in with the approved admin account.
- Run pwsh -NoProfile -File scripts/verify_admin_access_row.ps1 -Email zaftyslogistics@gmail.com with service-role env configured and save the output.
- Verify dashboard metrics, especially pending verifications.
- Open verification queue.
- Switch supplier, trucker, and truck tabs.
- Open supplier, trucker, and truck verification details where available.
- Validate uploaded/missing document rows and structured feedback truth.
- Verify approve path.
- Verify reject path with explicit reason / structured document feedback when safe for the target live case.
- Verify status sync back into supplier and trucker apps after review decisions.
- Open users, support, operational cases, Super Ops, load management, and audit logs.
- Record every mismatch in the failure table format from docs/almost-manual-testing.md.
