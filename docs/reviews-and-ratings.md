# Reviews & Ratings — Integrity Rules

**Status:** 🔴 **Action required from the owner.** The testimonials section
currently renders **no review cards** by design. It needs real reviews.

---

## What happened (2026-07-21)

The site was shipping **six fabricated testimonials** and an **invented star
rating**. Both were placeholder content from the original build that was never
replaced, and both were live in production.

**The fake reviews** lived in `Review::DEFAULTS`. They were labelled
`source: "Google"` and attributed to named people — "Sarah M.", "Jennifer L.",
"Michelle R.", "Ana P.", "Karen T.", "Denise W." Tells that they were written,
not collected:

- Uniform 5★ across all six.
- Generic first-name-plus-initial pattern.
- Two praised **services the salon has never offered**: a "spa pedicure" (never
  on the menu) and Michael doing "fine-line art" (the owner confirmed he does
  acrylic full sets, not nail art).

**The fake rating** lived in `SiteSetting::DEFAULTS` as `4.9 / 120 reviews`. The
real Google figures are **4.2 / 154** (owner-confirmed). This mattered more than
the cards, because that number is emitted into the **`LocalBusiness` JSON-LD**
(`shared/_structured_data`) — an inflated `aggregateRating` in structured data
is a false claim made to search engines, not just to visitors.

**A third bug in the same section:** the rating panel drew **five solid gold
stars unconditionally**, so any rating displayed as a perfect score. A 4.2 was
rendered as 5★. Fixed to fill stars from the real value.

## The rules

1. **Never write a testimonial.** Not as a placeholder, not "for layout", not
   "we'll replace it later". Placeholder reviews are indistinguishable from real
   ones once shipped — that is exactly how these survived to production.
2. **`Review::DEFAULTS` stays empty.** Enforced by a test in
   `test/models/review_test.rb`. Anything in that constant is auto-seeded into
   every environment, so it must never hold stand-in content.
3. **Real reviews go in the database**, added verbatim via the MCP
   `CreateReviewTool` — actual reviewer name, actual date, actual star rating,
   text copied exactly. No paraphrasing, no "cleaning up" grammar, no trimming
   to fit the card.
4. **Never edit an existing review's text.** Altering a real customer's words is
   fabrication regardless of intent. Hide it with `SetReviewApprovedTool` if it
   must come down.
5. **`aggregate_rating` / `review_count` must match the live Google Business
   Profile.** Update both together when they change. Don't round up.
6. **Don't reuse other platforms' reviews as Google reviews.** Yelp, Birdeye and
   the directory aggregators each carry their own separate pools with different
   scores (checked 2026-07-21: Yelp 3.4/15, Birdeye 3.3/7, Chamber 4.1/67).
   Relabelling one as another is false attribution.

## What the section renders now

- **Aggregate panel** — real 4.2 rating, star fill derived from it, real count of
  154, plus "Read Reviews on Google" / "Leave a Review" buttons. All genuine, so
  the section still works with zero cards.
- **Review cards** — nothing, until real reviews are added.

## To add the real ones

Google reviews can't be scraped programmatically — the Maps page is JS-rendered
and blocks fetching, and there is no free API for arbitrary place reviews. So
this is a manual copy-paste, done once:

1. Google Business Profile → **Reviews** → **Manage reviews**.
2. Pick a handful of strong, recent ones. Favour reviews that name a real
   service on the current menu, and ideally a technician.
3. For each, capture **exactly**: reviewer name as displayed, star rating, date
   (a relative form like "3 weeks ago" is fine), full text unmodified.
4. Add via the MCP `CreateReviewTool`, `source: "Google"`.

**Note on the 4.2 average:** it means real negative reviews exist. Showing only
5★ cards beside a 4.2 is legitimate — every business features its best — but the
gap is visible to anyone who clicks through to Google. Reviews that read as
specific and human do more for trust than uniformly glowing ones, which is the
failure mode of the set that was just removed.

## Related

- `app/models/review.rb` — the empty constant and why
- `test/models/review_test.rb` — the guard test
- `app/views/pages/home/_testimonials.html.erb` — star-fill logic, empty state
- `app/views/shared/_structured_data.html.erb` — where the rating reaches Google
