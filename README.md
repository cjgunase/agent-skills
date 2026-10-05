# Agent Skills

Reusable agent workflows developed from real projects, tested before promotion, and published with explicit safety and verification gates.

## Catalog

| Skill | Status | Version | Purpose |
|---|---|---:|---|
| [`aws-lambda-container-deploy`](skills/aws-lambda-container-deploy/SKILL.md) | Experimental | 0.1.0 | Deploy HTTP containers to AWS Lambda through Docker, ECR, and the Lambda Web Adapter |

## Install a skill

Clone the repository, then copy the skill directory into your agent's workspace skill directory:

```bash
git clone https://github.com/cjgunase/agent-skills.git
mkdir -p ~/.openclaw/workspace/skills
cp -R agent-skills/skills/aws-lambda-container-deploy ~/.openclaw/workspace/skills/
```

Restart the agent or begin a new session so it discovers the skill.

Treat all third-party skills as executable instructions: read `SKILL.md`, inspect scripts, and understand external side effects before use.

## Maturity levels

- **Experimental** — proven once; assumptions may remain.
- **Beta** — independently tested on multiple projects.
- **Stable** — repeatable, documented, and tested by external users.

## Validation

```bash
./scripts/validate-skills.sh
```

## Versioning

Skills are versioned independently with tags such as:

```text
aws-lambda-container-deploy-v0.1.0
```

## License

MIT. See [LICENSE](LICENSE).
