---
name: tdd-new-fn
description: Build a new devPTIpack function test-first — ask contract questions via AskUserQuestion, write failing tests (RED), then implement via Codex (GREEN).
---

# Skill: tdd-new-fn

Build any **new** exported function or substantial (>~20-line) internal
helper using strict test-first development. Small private helpers
tested indirectly by their callers are exempt.

**YAML-only registry additions are NOT exempt**: write the failing
integration test against the full pipeline first, then add the YAML.

---

## Phase 1 — Contract questions

Before writing a single line of test or code, call `AskUserQuestion`
with **3–4 questions** specific to this function. Design the questions
around four axes:

| Axis | What to ask |
|------|-------------|
| **Output shape** | Return type, key columns/names, length constraint on success |
| **Error conditions** | Which invalid inputs must produce `cli_abort()` or an error |
| **Edge cases** | Which boundary inputs are in scope (empty, NA, single element) |
| **Out of scope** | What reasonable-sounding behaviour should the function NOT do |

### Formulating options

- Offer 2–4 concrete options that match the most likely answers given
  the function's context ("Other" is automatic — do not add it).
- For output-shape questions, pre-populate options from what callers
  already expect (e.g. if a caller is `fetch_hex_data()`, one option
  is `"tibble keyed by hex_id"`).
- For error-condition questions, pre-populate from natural failure
  modes (wrong arg type, length mismatch, missing required field).

### Example (REST endpoint parser)

```r
AskUserQuestion(questions = list(
  list(
    question = "What should hex_fetch_source_timeseries() return on success?",
    header   = "Return type",
    multiSelect = FALSE,
    options  = list(
      list(label = "Wide tibble keyed by hex_id (one col per period)",
           description = "Mirrors the flat output of hex_fetch_source_rest()."),
      list(label = "Long tibble (hex_id | period | value)",
           description = "Easier to pivot later; caller reshapes.")
    )
  ),
  list(
    question = "Which inputs must produce an error?",
    header   = "Error cases",
    multiSelect = TRUE,
    options  = list(
      list(label = "hex_ids is empty",       description = "length(hex_ids) == 0"),
      list(label = "No fields resolve",      description = "Template yields 0 columns after year expansion"),
      list(label = "httr2 not installed",    description = "Dependency guard"),
      list(label = "API returns non-200",    description = "HTTP error passthrough")
    )
  )
))
```

---

## Phase 2 — Write failing tests (RED)

Using the contract answers, write a `test_that()` block per contract
point in the appropriate test file (append; never overwrite):

- Happy path (at least one)
- Each named error condition
- Each in-scope edge case

Use `mockery::stub()` for network calls; use `httptest2::with_mock_api()`
when real fixture data matters (record the fixture before writing
assertions so the fixture hash is known).

Run:

```r
Rscript -e 'devtools::load_all(quiet=TRUE)
            testthat::test_file("tests/testthat/test-<area>.R")'
```

**All new tests must fail** (or error with "could not find function").
If any pass unexpectedly, the test is too weak — strengthen it before
continuing.

**Do not proceed to Phase 3 until RED is confirmed.**

### Special case: YAML-only registry additions

Write an integration test that calls `use_hex_vars("<canonical_name>")`
and `fetch_hex_data(hex_ids, vars, ...)` against a mock/fixture for the
new variable. Confirm the test fails because the YAML entry does not
exist yet. THEN add the YAML entry and confirm the test turns GREEN.

---

## Phase 3 — Implement (GREEN)

Brief Codex with:

- The test file path + the failing test bodies (the spec)
- The target R file path and the function signature agreed in Phase 1
- Any relevant arch doc sections or existing similar functions to mirror
- The exact `Rscript` command to run after implementation

After Codex returns:

1. Read the diff.
2. Run the tests — all must PASS, no regressions in the full suite.
3. Run `R CMD check --no-manual` if any exported symbol changed.

Fix single-line issues inline; do not re-invoke Codex for typos.

---

## Phase 4 — Housekeeping

Same as `tdd-permanent-fn` steps 6–7:

- Update changelog (`Tests` row for the test file, `Code` row for the
  implementation).
- Sync `PLAN.md` — tick the relevant box, add sub-bullets for new
  files, update the progress log with the PR/branch.

---

## Hard rules

- Never write implementation before tests exist and are confirmed RED.
- Never weaken a failing test to make it pass — fix the implementation.
- Never use external network in tests; use stubs or committed fixtures.
- Small helpers (<~20 lines) tested indirectly by callers are exempt.
