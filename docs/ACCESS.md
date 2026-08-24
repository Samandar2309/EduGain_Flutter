# Access — what you need, and where to keep it

Two things are handed to you outside this repository. Neither is in git, and
neither should be put there.

| What | What it opens | How you get it |
|---|---|---|
| **Documentation secret** (`X-Docs-Secret`) | one sandbox learner account, through `/api/v1/auth/docs-token` | sent to you directly |
| **Repository access** | this repo | a GitHub invitation |

## Why the secret is not in this file

Because git remembers. A secret committed once stays in the history of every
clone and every fork, and rotating it afterwards does not remove it — it only
means the old value is now a *published* dead secret and the new one has to live
somewhere else anyway. The cost of keeping it out is one message; the cost of
taking it back out later is rewriting history in every copy that exists.

That is worth saying plainly even though this particular secret is narrow: it
grants one sandbox account and nothing else. The habit is the point. The next
secret somebody is tempted to paste beside it will not be narrow.

## Where to put it instead

Keep it out of the working tree entirely — your shell profile, your password
manager, or an untracked `.env.local` that `.gitignore` already covers.

```bash
export EDUGAIN_DOCS_SECRET='...'

curl -s -X POST https://64-226-109-240.sslip.io/api/v1/auth/docs-token \
  -H "X-Docs-Secret: $EDUGAIN_DOCS_SECRET"
```

That returns a real JWT pair for the sandbox learner. Use `access_token` as
`Authorization: Bearer <token>`; it lasts 60 minutes and you can simply call the
endpoint again.

In the Swagger UI at
**https://64-226-109-240.sslip.io/app/api-docs.html** the same thing is two
fields: paste the secret into `X-Docs-Secret` on `POST /api/v1/auth/docs-token`,
run it, then paste the returned `access_token` into **Authorize** at the top.

Note the two values are different and easy to confuse: the secret is short and
fixed, the token is long, starts with `eyJ`, and changes every time.

## If you think a secret has leaked

Say so immediately — rotating this one is a single environment variable on the
server and costs nothing. A secret that is quietly suspected is worse than one
that is loudly replaced.
