# Security Policy

SpecSeyal is a spec-driven development orchestrator (GitHub Spec Kit +
graphify): a governed pipeline that takes a project from spec through a
council-defended plan to specialized, parallel implementation and testing.
This document explains how to report a security vulnerability and what is
in scope for this project.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub
issues, discussions, or pull requests.**

Instead, report vulnerabilities privately using **GitHub's private security
advisories**:

1. Go to the repository's **Security** tab.
2. Select **"Report a vulnerability"** (also labeled "Privately report a
   vulnerability").
3. Fill in as much detail as you can (see below).

This creates a private advisory visible only to the maintainer and you,
until a fix is ready and the advisory is published.

### What to include in a report

To help us triage and fix the issue quickly, please include:

- A clear description of the vulnerability and its potential impact.
- Steps to reproduce, or a minimal proof of concept.
- The affected component (e.g. a specific pipeline extension under
  `extensions/`, the `.claude/` or `.specify/` tooling it installs, or a
  generated artifact template).
- The version or commit SHA you tested against.
- Any suggested remediation, if you have one.

### Response and disclosure

- We will acknowledge new reports as promptly as we can and aim to keep you
  updated as the issue is investigated.
- We follow a coordinated (good-faith) disclosure approach: please give us
  a reasonable opportunity to investigate and address a report before any
  public disclosure, and avoid accessing or modifying data that isn't yours
  when investigating an issue.
- Once a fix is available, we will credit reporters who wish to be credited
  when the advisory is published, unless anonymity is requested.

## Supported Scope

SpecSeyal is a **pre-1.0** project under active development. There are no
long-term-support release branches yet; security fixes are made against the
default branch and the most recent tagged release, where applicable.

In scope for security reports:

- The pipeline extensions under `extensions/` (e.g. `graphify`, `council`,
  `git`, `workforce`, `deck-render`, `testing`).
- The `.claude/` and `.specify/` tooling and templates this project
  installs into a working repository (skills, agents, workflow scripts,
  and generated configuration).
- Any script or workflow in this repository that executes code, handles
  file paths, or shells out to external tools on a user's behalf.

Out of scope:

- Vulnerabilities in third-party tools this project orchestrates (e.g. the
  Claude Code CLI, git, or other external dependencies) — please report
  those upstream to their respective maintainers.
- Issues that require an already-compromised local machine or an untrusted
  spec/task input that the user deliberately chose to run.

### A note on attack surface

SpecSeyal is designed to be **subscription-only and local-first**: it does
not require or use an API key, and it does not run a hosted service. Most
of the pipeline executes as local CLI/agent sessions operating on files in
a user's own repository. This keeps the attack surface small, but reports
about path traversal, unsafe shell invocation, unintended file writes
outside the working repository, or leakage of local file contents into
generated artifacts are all very much welcome.

## Questions

If you're unsure whether something is a security issue, err on the side of
reporting it privately via the Security tab above rather than opening a
public issue.
