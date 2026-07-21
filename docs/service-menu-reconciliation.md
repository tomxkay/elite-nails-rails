# Service Menu — Real List

**Status:** 🟢 Menu live on the site. **Pending:** re-import the Square catalog
from the current CSV (`bin/rails content:square_csv` → `tmp/square-services.csv`)
so Square matches the 2026-07-21 revision below.

Source: in-salon letter board photo (2026-07-20) + owner clarifications.
Durations from industry research (see Sources) — starting estimates, tune once
real bookings show actual times.

> ⚠️ **`PricingItem::DEFAULTS` is the source of truth, not this file.** The
> tables below duplicate it for reasoning and history — they drift. When they
> disagree with the model, the model wins. Verify with:
> `bin/rails runner 'PricingItem.visible.ordered.each { |i| puts "#{i.name} #{i.price}" }'`

---

## Revision — 2026-07-21 (owner)

| Change | From | To | Knock-on |
|---|---|---|---|
| Manicure | $30 | **$20** | Broke the Mani+Pedi combo math — see below |
| Gel Manicure | $40 | **$35** | **Resolves** the French pricing inconsistency |
| Manicure + Pedicure | $50 | **$45** | Was going to save $0 at $50; now saves $5 |
| Nail Repair | $5 | **$5+** | Variable, matches Nail Art / Chin |
| Chin wax | $30+ | **$15+** | Still above Lip $7 and Brow $10 |
| Nail Trim | one row, $10+ | **split**: Fingers $7 / Toes $10 | Restores the board's original two lines |
| Brow + Lip combo | $15 | **removed** | Waxing service-card copy updated too |
| Dip Powder Full Set | — | **added, $55, 75m, bookable** | Dip over tips for length |
| Nail Repair | in *Acrylic, Dip & Extensions* | **moved to *Nail Care*** | Matches the Nail Care card, which already promised "quick repairs" |

**Two things worth remembering:**

1. **Dropping Manicure to $20 silently broke the combo.** At $50 the bundle
   equalled buying both separately, while its description still promised "$10
   less." Any future change to Manicure or Pedicure must re-check
   Manicure + Pedicure — the discount is a *derived* number, not an independent
   one.
2. **Two services are both named "Dip Powder"** (`Dip Powder` $40 and
   `Dip Powder Full Set` $55). Owner chose to keep the shorter name rather than
   rename to "Overlay". The **descriptions** carry the distinction — natural
   nails vs. tips for length. Preserve that contrast if either is reworded, or
   the menu becomes ambiguous.

---

## What the owner's answers resolved

- **`ACRYLIC 40` + `GEL-NAILS 55` + `SET 55`** → one service, **Acrylic Full
  Set**, priced by polish type: **$40 regular / $55 gel**. ("Set" appeared twice
  because customers ask for it by different names.)
- **`FILL-IN 25` + `GEL-FILL 40`** → one service, **Acrylic Fill**: **$25
  regular / $40 gel**.
- **`TOE NAILS CUT` + `NAILS CUT DOWN`** → originally merged into one **Nail Trim, $10+** row; **split back apart 2026-07-21** into Fingers $7 / Toes $10, matching the board.
- **Waxing** is three services: Eyebrow, Lip, Chin. (A Brow + Lip combo was added, then removed 2026-07-21.)
- **Nail art is offered** — $5+ per nail by design.

Acrylic work is always *regular vs gel*, at both set and fill stage. Worth
exposing that symmetry in the layout.

---

## The menu

📅 = bookable online · 🚶 = walk-in / phone only

### Manicures
| Service | Price | Time | | Description |
|---|---|---|---|---|
| Manicure | $20 | 30m | 📅 | Nail shaping, cuticle care, a relaxing hand massage, and your choice of classic polish. |
| Gel Manicure | $35 | 45m | 📅 | A full manicure finished with gel polish — cured to a high shine that resists chips for up to three weeks. |
| French Gel Manicure | $40 | 60m | 📅 | Our gel manicure with the timeless white-tip French finish, hand-painted and cured to last. |

### Pedicures
| Service | Price | Time | | Description |
|---|---|---|---|---|
| Pedicure | $30 | 45m | 📅 | Nail shaping, cuticle care, a light callus buff, sugar scrub, massage, hot towel, and polish. |
| Deluxe Pedicure | $40 | 60m | 📅 | Everything in the classic pedicure, plus callus treatment, paraffin wax, and an extended massage. |
| Gel Pedicure | $50 | 60m | 📅 | A full pedicure finished with long-wearing gel polish that keeps its shine for weeks. |
| Manicure + Pedicure | $45 | 75m | 📅 | Our classic manicure and pedicure together — and $5 less than booking them separately. |

### Polish & Color
| Service | Price | Time | | Description |
|---|---|---|---|---|
| Gel Polish | $25 | 30m | 📅 | Gel color applied to prepped nails — polish only, without the full manicure. |
| French Gel Polish | $30 | 40m | 📅 | Gel color with a hand-painted French tip — polish only, without the full manicure. |
| Polish Change | $12 | 15m | 🚶 | A quick change of classic polish on clean, prepped nails. |
| French Polish Change | $16 | 25m | 🚶 | A quick polish change with a hand-painted French tip. |
| Nail Art | $5+ /nail | varies | 🚶 | Hand-painted designs, from a simple accent to detailed art. Priced per nail by design. |

### Acrylic, Dip & Extensions
| Service | Price | Time | | Description |
|---|---|---|---|---|
| Dip Powder | $40 | 60m | 📅 | Color powder sealed layer by layer over your natural nails — durable, lightweight, and wears two to three weeks with no UV lamp. |
| Dip Powder Full Set | $55 | 75m | 📅 | The same dip powder finish, built over tips to add length — shaped to whatever length you like. |
| Acrylic Full Set | $40 regular | 75m | 📅 | Sculpted acrylic extensions shaped to your preferred length, finished with classic polish. |
| Acrylic Full Set (Gel) | $55 | 90m | 📅 | The same sculpted set, finished with long-wearing gel polish. |
| Acrylic Fill | $25 regular | 45m | 📅 | Rebalances your existing set as the natural nail grows out, refreshed with classic polish. |
| Acrylic Fill (Gel) | $40 | 60m | 📅 | The same fill, refreshed with gel polish. |
| Acrylic Removal | $15 | 30m | 🚶 | Gentle soak-off that lifts acrylic away without damaging the natural nail underneath. |

### Nail Care
| Service | Price | Time | | Description |
|---|---|---|---|---|
| Nail Trim (Fingers) | $7 | 10m | 🚶 | Trimming and shaping for fingernails, without polish. |
| Nail Trim (Toes) | $10 | 15m | 🚶 | Trimming and shaping for toenails — thicker and more involved than fingernails. |
| Nail Repair | $5+ | 15m | 🚶 | Repair for a cracked or broken nail, priced by the work involved. |

### Waxing — all walk-in for now
| Service | Price | Time | | Description |
|---|---|---|---|---|
| Eyebrow | $10 | 15m | 🚶 | Shaping and cleanup to define your natural brow line. |
| Lip | $7 | 10m | 🚶 | Quick, precise upper-lip waxing. |
| Chin | $15+ | 30m | 🚶 | Priced by coverage and time; a denser area than brow or lip. |

---

## Booking policy

**Online (15 of 25 services):** manicures, pedicures, the combo, gel polish, dip
powder, and all acrylic set/fill work. These are the longer, higher-value
appointments where a reserved slot matters.

**Walk-in only (10 services):** polish changes, nail art, acrylic removal, nail
repair, nail trim, and all waxing. Short or add-on work that would clutter the
booking wizard and fragment the schedule.

Waxing may move online later — deliberately excluded for now.

**Staffing:** starting with **one bookable technician**. The team is used to
pen-and-paper and phone bookings; others opt in as they adjust. The site should
make clear who takes online bookings so the other technicians' cards don't
imply a booking path that doesn't exist.

**Bookable technician: Michael** (confirmed 2026-07-20). Everyone else stays
walk-in/phone until they opt in.

**Roster expanded 2026-07-21** — three technicians were missing from the site:

| First name | Experience | Strengths |
|---|---|---|
| **Thai** | 20+ years | Same range as Michael — acrylic sets, fills, gel |
| **Trang** | 20+ years | The whole menu; specialises in **nail art** |
| **Mui** | 10+ years | **Pedicures** (the deluxe in particular) and **waxing** |

Six technicians now: Michael, Thai, Trang, Mui, Nhan, Lien. Only first names are
displayed (2026-07-20 decision); surnames live in a comment in
`app/models/team_member.rb` for internal reference only.

Several are related by marriage — the salon is genuinely family-run. Those
relationships are **not published**: they're personal details about people who
haven't been asked. Add them only on the owner's confirmation that each person
is comfortable with it.

**Thai is the natural next candidate for online booking** — his skills overlap
Michael's, so the same services could be offered without menu changes. Requires
assigning him to the service variations in Square as well as flipping
`bookable`, or availability search returns nothing for him.

### Team bios — rewritten against the real menu

The originals referenced services that don't exist. Corrected:

| | Was | Now |
|---|---|---|
| **Michael K** | "Specializes in gel, dip, and fine-line nail art" · tags `Gel Art` `Dip Powder` `Fine Line` | Specializes in **acrylic full sets**, not nail art. Tags: `Acrylic Full Set` `Acrylic Fill` `Gel Manicure` |
| **Nhan Ka** | "spa pedicures" · tag `Spa Pedicure` — **service does not exist** | Deluxe pedicures + color work. Tags: `Deluxe Pedicure` `Gel Polish` `Dip Powder` |
| **Lien Ka** | "durable acrylics" · tags `Acrylics` `Nail Shaping` `Natural Looks` | Largely accurate; tags aligned to real service names |

## Pricing notes

**~~French Gel Manicure is underpriced by $5~~ — RESOLVED 2026-07-21.** The old
problem: French Gel Polish ($30) was +$5 over Gel Polish ($25), but French Gel
Manicure ($40) matched Gel Manicure ($40) instead of exceeding it. Dropping
**Gel Manicure to $35** fixed it from the other direction — the French premium
is now a consistent **+$5** in both places. Keep that gap if either price moves.

**Chin wax is case-by-case**, not tiered. Display `$15+` (matching Nail Art and
Nail Repair) with the coverage note visible — a bare range beside a $10 brow
reads as an error.

## Naming convention

The board uses salon-floor shorthand clear to staff but not to customers or
search engines. Rules:

1. **Name the service customers search for** — "Acrylic Full Set", not "Set".
2. **Modifier first** — "French Gel Manicure", not "Gel French Manicure".
3. **Never "fake"** — "Acrylic" is accurate *and* the search term.
4. **Variants are options, not line items.**
5. **Plain noun + warm descriptor** — literal name for SEO, personality in the
   description underneath.

| Board | New name |
|---|---|
| `SET` / `GEL-NAILS` | Acrylic Full Set (Gel) |
| `FILL-IN` | Acrylic Fill |
| `GEL-FILL` | Acrylic Fill (Gel) |
| `FAKE NAILS TAKE OFF` | Acrylic Removal |
| `NAILS CUT DOWN` | Nail Trim (Fingers) |
| `TOE NAILS CUT` | Nail Trim (Toes) |
| `FRENCH` (beside polish change) | French Polish Change |
| `GEL FRENCH-MANICURE` | French Gel Manicure |

## Build plan

**Schema —** neither table can express this yet:
- `pricing_items` needs **`bookable:boolean`** (default false)
- `team_members` needs **`bookable:boolean`** (default false)

**Then:**
1. **Square catalog** — replace wholesale: delete the 12 placeholders, create
   the 14 bookable services with durations, assign the one technician.
   Square will not make a service bookable without `team_member_ids`.
2. **Site** — `PricingItem` / `Service` records via **MCP tools**. Content is
   DB-backed; editing `DEFAULTS` in code will **not** change production.
3. **UI** — mark bookable services in the pricing section; mark the bookable
   technician in the team section and remove "Book with X" from the others.
4. Re-verify `/book` and the pricing section against this list.

⚠️ **Team bios reference placeholder services.** Nhan Ka's specialty is listed
as "Spa Pedicure" — a service that does not exist on the real menu. Review all
three bios and specialty tags against this document.

## Sources

Duration research:
- [How Long Does a Manicure Take? — BTArtbox](https://btartboxnails.com/blogs/btartbox-official-guides/how-long-does-a-manicure-take)
- [How Long Does a Gel Nail Appointment Take? — Oreate](https://www.oreateai.com/blog/how-long-does-a-gel-nail-appointment-actually-take/c3b60d92cb322db0360b8925906fc31f)
- [How Long Does a Full Set of Acrylic Nails Take? — LiveThatGlow](https://www.livethatglow.com/how-long-do-acrylic-nails-take/)
- [How Long Does It Take to Do Acrylic Nails? — Bela Beauty College](https://belabeautycollege.com/blogs/blog/how-long-does-it-take-to-do-acrylic-nails)
- [How Long Does a Pedicure Take? — BTArtbox](https://btartboxnails.com/blogs/btartbox-official-guides/how-long-does-a-pedicure-take)
- [Dip Powder Manicure Guide — PLEIJ Salon + Spa](https://pleijsalon.com/dip-powder-manicure-nail-guide/)
