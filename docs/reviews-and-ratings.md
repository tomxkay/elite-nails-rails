# Reviews & Ratings — Integrity Rules

**Status:** 🟢 Six real Google reviews are live (owner-supplied 2026-07-21).
Rating is the real 4.2 / 154. **Minor pending:** posting dates and confirmed
star ratings were never captured — see "Known gaps" below.

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
2. **`Review::DEFAULTS` holds real reviews only**, quoted verbatim. Four tests
   in `test/models/review_test.rb` guard it: the fabricated author names can
   never return, every entry needs full attribution, no quote may name a service
   the salon doesn't offer, and no quote may name an unconfirmed technician.
   > *This reverses an earlier decision to keep the constant permanently empty.
   > That rule was written while the only known reviews were fake, and it had a
   > real cost: reviews would have lived solely in the production database,
   > absent from version control and lost on any reset — unlike every other
   > content model. The actual hazard was never the constant, it was
   > **fabricated content**. Real verbatim reviews in `DEFAULTS` are safe,
   > reviewable in a diff, and resilient.*
3. **Reducing a surname to an initial is the only permitted edit** ("Dorethea
   Harvey" → "Dorethea H."). No paraphrasing, no grammar fixes, no trimming to
   fit the card.
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
  154, plus "Read Reviews on Google" / "Leave a Review" buttons.
- **Six review cards** — Dorethea H., Allison S., Valerie C., Melissa K.,
  Leslie D., Heidi B. The first four were the owner's pick of ten supplied;
  Leslie D. joined once Thai was confirmed as staff, and Heidi B. rounds the set
  to six so the masonry grid fills evenly at two and three columns. The mix is
  deliberate: three long-tenure clients (20, 11 and 10 years), one first-time
  visitor, two naming technicians who actually work here (Michael, Thai), and
  one naming real menu services (full set, fill-in).

## Known gaps in the current six

Both are honest omissions, not oversights — **do not fill them by guessing.**

- **No posting dates.** They weren't captured with the review text.
  `relative_date` is left blank and the card hides it. Inventing plausible dates
  is exactly what the fabricated set did.
- **Star ratings are inferred**, not read off the profile. All six texts are
  unambiguous praise, so `rating: 5` is a safe read, but it is a read. Correct
  any that differ when someone next opens the dashboard.

## Reviews supplied but not used

Four more were provided and are fine to add later — but one names people who
are **not on the current team** (`Ty`, `Mrs. Vann`). They may be former staff,
family, or nicknames. Confirm with the owner before publishing, or a visitor
will ask for someone who isn't there. A test in `test/models/review_test.rb`
blocks those two names from being seeded.

> `Thai` was on this list until 2026-07-21, when the owner confirmed Thai Tran
> is a technician here. Leslie D.'s review moved to the published set.

| Reviewer | Note |
|---|---|
| Nina M. | Positive and generic; safe. Best of the remaining four. |
| Connie H. | Mentions buying a **gift certificate** — confirm the salon offers these. |
| Amy T. | Names **"Ty" and "Mrs. Vann"** — not current team members. |
| Rosé | Single name, no surname to reduce. Generic text. |

## To add more

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

- `app/models/review.rb` — the real reviews and the rules on them
- `test/models/review_test.rb` — the four guard tests
- `app/models/team_member.rb` — the roster reviews are checked against
- `app/views/pages/home/_testimonials.html.erb` — star-fill logic, empty state
- `app/views/shared/_structured_data.html.erb` — where the rating reaches Google
