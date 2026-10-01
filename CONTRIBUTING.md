# Contributing

Use Xcode 27 and Swift 6. Keep UI state on the main actor, mutations within DeskStore, and bounded image work off the UI actor. Preserve atomic writes, revision checks, cancellation, and user review.

Add regression tests for changed matching or storage behavior. Run Debug/Release core tests and the native workflow. Changes to prompts or model profiles should also be evaluated on supported hardware with original representative fixtures; record model/settings and review results manually.

Use focused Conventional Commits. Include no private signing team, credentials, real client cases, or build output. Document new model routing, data handling, or provider integrations accurately.
