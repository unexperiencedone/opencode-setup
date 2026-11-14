# Global rules for opencode (every project)

- Read the relevant files before editing. Make the smallest change that does the job.
- After a change, run the project's tests or build; say plainly if you could not run them.
- Never run `sudo`, `rm -rf`, `git reset --hard`, `git push --force`, or anything that deletes
  or overwrites files outside the project. Ask first for anything that installs software.
- Never print, commit or upload secrets: `.env` files, keys, tokens.
- Commits: only when asked; one logical change each; no co-author trailer.
- End with what changed, which files, and what was verified.
