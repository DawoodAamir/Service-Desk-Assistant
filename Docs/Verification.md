# Verification

October 1, 2026: Mac and iOS Simulator builds passed. Core checks cover retrieval, bounded relevant excerpts, persistence, stale edits, idempotent sample loading, and preservation of corrupt files.

The final iPhone 18 Pro/iOS 27 native workflow passed: load sample guides, compose an issue, review and edit ticket notes, save, relaunch, and open the persisted case. The README screenshot is an actual attachment from this run.

The Mac Model Evaluations target compiled and its default run passed with one intentional opt-in model test skip. This establishes evaluation integration, not model response quality. Configure a ready on-device model and enable the test environment variable to run the original dataset.

The standalone `Scripts/test-model.sh` check exercised the production ticket profile and prompt builder against the ready on-device model on this Mac. All three original cases passed: 789, 770, and 929 characters; no selected false-completion phrase was present. This check establishes actual text response execution and basic heuristic results, not factual grounding or comprehensive safety.

Remaining hardware/manual checks: photo responses, model availability transitions, multilingual requests, extended document libraries, VoiceOver, maximum accessibility text sizes, iPad resizing, and Mac keyboard navigation. No cloud generation or ticket-provider service was exercised or claimed.
