---
allowed-tools: Bash(bundle :*), Bash(git :*), Read, Edit, MultiEdit, Glob
description: Update Gemfile dependencies to latest minor versions
argument-hint: [gemfile] [commit]
---

Update the dependencies in the specified Gemfile (or ./Gemfile if no path provided) to their latest minor versions while
preserving major version constraints. Only update MAJOR.MINOR versions, never PATCH versions unless explicitly needed.

Steps:
1. Read the Gemfile at the specified path (or ./Gemfile if $ARGUMENTS is empty)
2. Read the corresponding Gemfile.lock to get current resolved versions
3. Run `bundle outdated --only-explicit` to check for available minor updates of explicitly declared gems
4. For each gem in Gemfile, check if Gemfile.lock has a newer minor version than the current Gemfile constraint allows
5. Update gem version constraints to match the minor version from Gemfile.lock or latest available, whichever is newer (MAJOR.MINOR format)
6. Use pessimistic version constraints (~> MAJOR.MINOR) to prevent automatic patch updates
7. Preserve any existing version operators but ensure they follow minor-only update strategy
8. Run `bundle update` to apply the changes
7. Skip step 8, 9 and 10 if --commit flag is not provided
8. Stage Gemfile (only if not gitignored)
9. Verify if Gemfile.lock is tracked and not gitignored. If both conditions are met, stage it for commit.
10. Create a git commit with message 'Update development dependencies' and a description listing all updated gems with their old and new versions like:

<commit-message>
  Updated gems:
- rubocop: 1.75.2 → 1.78.0
- rubocop-yard: 0.10.0 → 1.0.0
</commit-message>

11. If any dependencies were updated, respond only with the update message. And if the user has chose to commit,
include the update commit message. Otherwise, respond only with the no op message.

<update-message>
Updated gems:
- rbs: 3.8 → 3.9
- rubocop: 1.78 → 1.80
- rubocop-rspec: 3.6 → 3.7

<update-commit-message>The changes have been committed with the message "Update development dependencies".</update-commit-message>
</update-message>

<no-op-message>All dependencies are up to date.</no-op-message>

Key bundle outdated flags used:
- `--only-explicit`: Only show gems explicitly listed in Gemfile (not dependencies)
- No `--local` flag to ensure remote gem sources are checked for latest versions

Arguments:
- `gemfile`: Gemfile path (defaults to ./Gemfile if not provided)
- `--commit`: Create a git commit after updating dependencies with message 'Update development dependencies' and a description listing all updated gems with their old and new versions

Gemfile path: ${ARGUMENTS:-./Gemfile}
