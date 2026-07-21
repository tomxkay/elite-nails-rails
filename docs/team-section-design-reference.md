# Team Section Design Reference

Status: Reference only.

The original editorial team-section design is preserved as an annotated git tag:

```bash
design/team-section-editorial-rows
```

That tag points to commit `c2561db`:

```text
c2561db refactor(views): use salon helper for phone links instead of hardcoding
```

Use this reference when an agent or designer wants to revisit the pre-compact
team layout. It preserved the full-height alternating editorial rows, large
portrait/cutout placeholders, oversized numbering, quote-led copy, specialty
chips, and per-technician booking/call CTAs.

Useful lookup commands:

```bash
git show design/team-section-editorial-rows:app/views/pages/home/_team.html.erb
git show design/team-section-editorial-rows:app/views/shared/_team_member.html.erb
git diff design/team-section-editorial-rows -- app/views/pages/home/_team.html.erb app/views/shared/_team_member.html.erb
```

Context: on 2026-07-21 the live working design was compacted so the team section
can scale toward six team members without occupying several full mobile screens.
The tagged version is intentionally not the current production direction, but it
is the preferred reference if the larger editorial treatment is needed later.
