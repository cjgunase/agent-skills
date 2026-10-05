# Contributing

Contributions should improve a skill through evidence from real use.

## Requirements

1. Keep every skill self-contained under `skills/<skill-name>/`.
2. Include YAML frontmatter with `name` and a quoted `description`.
3. Never include credentials, account IDs, private URLs, personal paths, or proprietary material.
4. Distinguish destructive actions and external side effects.
5. Include verification gates; do not define “command completed” as success.
6. Run `./scripts/validate-skills.sh` before opening a pull request.
7. Describe the project or failure that supports the change.

Experimental skills should not be described as stable until they have been tested independently on multiple projects.
