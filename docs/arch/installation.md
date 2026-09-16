# Anubis-Arch Agent — Installation Guide

Anubis-Arch installs through the same unified installer as the rest of
the suite — see [`../installation.md`](../installation.md) for
prerequisites, quick install, manual install and troubleshooting.

To install only Anubis-Arch:

```bash
./install.sh --suite arch
```

This installs `Anubis.Arch.md` plus the shared runtime package
(`references/`, `schemas/`, `examples/`) required at runtime, including
`references/architecture-governance.md`, `references/netarchtest-rules.md`
and `references/sbom.md`.
