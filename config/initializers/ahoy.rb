class Ahoy::Store < Ahoy::DatabaseStore
end

# First-party, anonymized analytics — see docs/analytics-plan.md.

# We track from Ruby, not JavaScript (dodges ad-blockers, no npm dep). Visits
# are created lazily — only when we actually track something (a page view or a
# KPI event) — so health checks (/up) and API calls never create phantom visits.
Ahoy.api = false
Ahoy.server_side_visits = :when_needed

# Privacy: mask IPs (last IPv4 octet / IPv6 zeroed) and never geocode. Coarse
# city/region columns stay null until we opt into geocoding later.
Ahoy.mask_ips = true
Ahoy.geocode = false

# Don't record automated traffic (bots/crawlers) as real visits.
Ahoy.track_bots = false
# First-party cookies are kept (default) for visit stitching / new-vs-returning.
# Do Not Track is honored in ApplicationController#track_pageview.
