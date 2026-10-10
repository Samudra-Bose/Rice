# Rice Change Control Workflow

To ensure system stability, every significant change to the Rice workspace or the underlying system must follow this disciplined cycle.

## 1. Inspect
*   Understand the code and existing behavior before touching it.
*   Identify whether an issue belongs to Rice, Caelestia, Quickshell, Hyprland, or the OS.

## 2. Establish a Baseline
*   Record the current working state, relevant package versions, and configuration.
*   Ensure the Git repository is clean (`git status`).

## 3. Plan
*   Clearly document the defect or feature.
*   Propose a minimal, coherent fix.
*   Define validation criteria (How do we know it worked?).
*   Identify risks.

## 4. Isolate
*   **Never modify live system or package-owned files directly.**
*   All work happens inside `~/Projects/VisualSCode/Rice`.
*   Diagnostic reads outside of the project workspace are permitted and encouraged to investigate issues.
*   Unauthorized writes outside of the workspace are strictly prohibited.
*   If upstream Caelestia files need modifying, patch them in a controlled, versioned manner.

## 5. Implement
*   Make the smallest coherent change necessary to achieve the goal.
*   Build reusable, composable primitives rather than monolithic blocks.

## 6. Review
*   Review the entire Git diff for unintended changes before testing.

## 7. Test
*   Run appropriate syntax checks, Qt/QML linters, or Quickshell test runs.
*   Perform functional tests (clicks, keyboard navigation).
*   Test lifecycle events if applicable (reloads, multi-monitor, sleep/wake).
*   **Explicit owner approval is required** before performing risky live-system changes, deployments, shell restarts, reboot experiments, or suspend/resume tests.
*   **Do not report a test as passed if it was not run.** 

## 8. Recover
*   Document the rollback method for any risky changes (e.g., reverting an `env.lua` variable, downgrading a package).
*   Verify the rollback path exists.

## 9. Document
*   Update relevant documentation in `docs/` reflecting the new state or the resolution of a defect.

## 10. Commit and Push
*   Once tested and reviewed, commit the changes using descriptive conventional commits.
*   Do not force-push to `main`.
