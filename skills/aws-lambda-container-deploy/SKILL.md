---
name: "aws-lambda-container-deploy"
description: "Build, test, push, and deploy HTTP containers to AWS Lambda through ECR and the Lambda Web Adapter."
license: "MIT"
metadata:
  maturity: "experimental"
  version: "0.1.0"
---

# AWS Lambda Container Deployment

Deploy an existing HTTP application as a Docker image in private Amazon ECR and run it on AWS Lambda through the AWS Lambda Web Adapter.

## Use when

- The app already runs as an HTTP server such as FastAPI, Flask, or Express.
- Static frontend files and a backend can share one container.
- Scale-to-zero is preferable to an always-on load balancer.
- A Lambda Function URL should expose the app.
- Response streaming or SSE may be required.

Do not use for persistent local disk, always-running background processes, connections beyond Lambda limits, or workloads explicitly requiring ECS/EKS.

## Required inputs

Collect project directory, image/repository name, AWS profile, region, architecture, port, public build arguments, private runtime variables, URL authentication choice, memory, timeout, and reserved concurrency.

Never request credentials in chat. Prefer short-lived `aws login` credentials. Never print secrets.

## Safety

- Confirm identity and region before creating resources.
- Use a named AWS CLI profile and private ECR repository.
- Keep secrets out of Git and image layers.
- Pass only intentionally public values as Docker build arguments.
- Cap reserved concurrency. Do not enable paid provisioned concurrency without explicit approval.
- Never replace or delete unrelated AWS resources.
- Use sanitized test data and record created resources for cleanup.

## 1. Inspect and prepare

1. Inspect framework, startup command, dependencies, API routes, Docker files, static build, and ignore rules.
2. Bind the server to `0.0.0.0` on the agreed port.
3. Add a lightweight `GET /health` endpoint.
4. If serving a static frontend, export it, copy it into the runtime image, mount static files after API routes, and verify route-to-file behavior.
5. Verify streaming locally before AWS work when required.

## 2. Add Lambda Web Adapter

Use a multi-stage Dockerfile. Include in the runtime stage:

```dockerfile
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:1.0.0 \
  /lambda-adapter /opt/extensions/lambda-adapter
ENV PORT=8000
ENV AWS_LWA_INVOKE_MODE=response_stream
```

Keep the adapter version explicit. Start the normal server, for example:

```dockerfile
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
```

Adapt the command to the inspected framework.

## 3. Local deployment gate

Build with public arguments only and run with private values supplied at runtime. Verify:

- health and expected frontend routes return 200;
- protected routes reject unauthenticated requests;
- authenticated end-to-end behavior succeeds when applicable;
- streaming arrives incrementally rather than buffered;
- logs contain no exposed secrets.

Do not create AWS resources until local verification passes.

## 4. Authenticate to AWS

Prefer short-lived console credentials:

```bash
aws configure set region REGION --profile PROFILE
aws login --remote --region REGION --profile PROFILE
aws sts get-caller-identity --profile PROFILE
```

Use `--remote` for SSH/headless hosts. The user completes browser authentication and enters the one-time code directly in their terminal.

## 5. Build for Lambda

```bash
docker build \
  --platform linux/amd64 \
  --provenance=false \
  --build-arg PUBLIC_VALUE="$PUBLIC_VALUE" \
  -t IMAGE_NAME .
```

Match the function architecture. Verify a single supported image manifest, not an unsupported multi-platform or attestation manifest list.

## 6. Push to private ECR

Create or reuse only the intended repository; enable scan-on-push when supported.

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --profile PROFILE --query Account --output text)
REGISTRY="$ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com"
aws ecr get-login-password --region REGION --profile PROFILE |
  docker login --username AWS --password-stdin "$REGISTRY"
docker tag IMAGE_NAME:latest "$REGISTRY/REPOSITORY:latest"
docker push "$REGISTRY/REPOSITORY:latest"
```

Verify tag, digest, size, architecture, and media type. Log Docker out afterward.

## 7. Create the execution role

Create a dedicated Lambda-trusted role with minimum permissions. Basic logging normally uses `AWSLambdaBasicExecutionRole`.

IAM is eventually consistent. If a new role cannot be assumed, verify its trust policy, wait briefly, and retry a bounded number of times. Do not broaden permissions first.

## 8. Create or update Lambda

Use package type Image, the verified ECR URI, matching architecture, explicit memory and timeout, bounded reserved concurrency, and runtime environment variables.

Reasonable small-project starting values:

- memory: 1024 MB;
- timeout: 300 seconds;
- reserved concurrency: 4;
- provisioned concurrency: off.

Wait for Active/Successful. Pushing `latest` does not update Lambda; run `update-function-code` after every image push.

## 9. Create the Function URL

When application-level authentication protects sensitive routes:

- auth type: `NONE`;
- invoke mode: `RESPONSE_STREAM` for streaming/SSE;
- minimum required public Function URL permissions;
- one CORS layer, avoiding duplicate application and platform configuration.

Explain that `NONE` makes the endpoint reachable; it does not bypass application JWT/session checks.

## 10. Production verification

Verify, in order:

1. function is Active;
2. health returns 200;
3. root and application routes return 200;
4. protected API rejects unauthenticated access;
5. sign-in and authenticated request succeed;
6. streaming is incremental;
7. CloudWatch receives logs;
8. metrics show no unexpected errors or throttles.

Inspect CloudWatch before changing configuration after a 502/503.

## Failure map

- `exec format error` → architecture mismatch.
- Unsupported image/media type → one platform plus `--provenance=false`.
- Static route 404 → compare generated file layout with server resolution.
- Role cannot be assumed immediately → verify trust, then allow IAM propagation.
- Output arrives at once → buffered Function URL or intermediary.
- 401/403 → inspect token retrieval, JWT issuer/JWKS, audience, and authorization.
- Startup crash → missing or malformed runtime variable.
- New ECR image has no effect → update Lambda to the new image digest.
- Local works, Lambda fails → compare architecture, port, environment, manifest, and logs.

## Update cycle

Test source → rebuild target image → test locally → push ECR → update Lambda code → wait → repeat health/auth/streaming checks → inspect logs/metrics → record digest.

## Handoff

Report profile and region without account IDs, resource names, image digest/architecture, Lambda limits, Function URL mode, verification evidence, known risks, cleanup commands, and whether temporary containers, firewall rules, and registry sessions were removed.

Never claim completion until the meaningful production flow has been tested.
