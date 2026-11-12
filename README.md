# MonOA profile workshop

A 45-minute Quarto/reveal.js working session that helps EBS staff inspect what the MonOA public-evidence corpus currently sees, then improve their Monash Research Portal, ORCID and Google Scholar profiles.

The session is deliberately weighted toward action:

- 12 minutes of context
- 30 minutes of guided profile work
- 3 minutes to record unresolved corrections and priorities

## Render locally

Install [Quarto](https://quarto.org/), then run:

```bash
quarto render
quarto preview
```

The slide deck is `index.qmd`. The participant checker is `profile-check.qmd`.

## Refresh the participant checker

The published `data/people.json` contains only public professional evidence from the generated MonOA corpus. It does not include curated Hub judgements, funding suggestions or internal notes.

From this repository, point the script at the Obsidian vault root:

```bash
Rscript scripts/build-profile-data.R "/path/to/vault"
quarto render
```

The script reads:

- `MonOA Hub/Corpus/roster.csv`
- `MonOA Hub/Corpus/profiles.csv`
- `MonOA Hub/Corpus/publications.csv`
- `MonOA Hub/Corpus/profile_items.csv`

Review the generated JSON before publishing a refresh. Source pages and search indexes can lag behind profile edits.

## Facilitation

Open the speaker view with `S`. The notes contain timekeeping and facilitation prompts. Keep the opening section brief and start the participant work by minute 12.

## Sources and design

The visual rhythm takes inspiration from [AgenttiX/ai-workshop](https://github.com/AgenttiX/ai-workshop): large type, strong section changes and clear workshop tasks. This deck uses a lighter, warm-paper palette suited to a bright room.

Profile update guidance links to [Monash myResearch](https://www.monash.edu/myResearch/home), the [Monash Library researcher-profile guide](https://www.monash.edu/library/researchers/researcher-profiles), [ORCID](https://orcid.org/my-orcid) and [Google Scholar](https://scholar.google.com/citations).

