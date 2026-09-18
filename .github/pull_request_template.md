## What changed

<!-- One or two lines. -->

## Before merging

- [ ] I understand that **merging ships nothing**. Consumers pin `@v1`, a moving
      tag, so the change reaches them only when the tag is moved.

## After merging — do this now, not later

```bash
git fetch origin main
git tag -f v1 origin/main
git push -f origin v1
```

- [ ] `v1` moved to the merge commit
- [ ] Verified with `git ls-remote --tags origin v1`

A merge without a tag move is silent: every consumer keeps running the previous
code and nothing reports that anything is wrong. This checklist exists because
that failure mode has no other signal.
