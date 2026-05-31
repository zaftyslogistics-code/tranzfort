# TranZfort legal pages (P0-11)

Static pages for in-app URLs:

- `https://tranzfort.com/privacy` → deploy `public/privacy.html` as `/privacy` (or `/privacy/index.html`)
- `https://tranzfort.com/terms` → deploy `public/terms.html` as `/terms`

## Deploy options

1. **Cloudflare Pages / Netlify / Vercel:** set publish directory to `website/public`.
2. **Nginx:** `location = /privacy { try_files /privacy.html =404; }` (same for `/terms`).
3. **S3 + CloudFront:** upload both HTML files; map object keys to paths.

Before Play upload: replace Grievance Officer placeholders in `privacy.html` and jurisdiction in `terms.html`.

After deploy, verify HTTPS from a device and match URLs in Google Play Console Data safety + app `AppConfig` (`TranZfort/lib/src/core/config/app_config.dart`).
