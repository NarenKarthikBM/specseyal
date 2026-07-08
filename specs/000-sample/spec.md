# Feature Spec — 000-sample

> Fixture. See `README.md`. Structurally valid, semantically inert.

## Problem

The contracts in `docs/contracts/` describe a directory tree that, at M0, nothing has produced.
An unexercised contract is a hypothesis.

## Goal

A committed feature directory that exercises every artifact in `artifact-layout.md` §1, so that a
conformance checker written at any later milestone has something to be checked against on day one.

## Scope

- In: one valid instance of every artifact.
- Out: any implementation. `000-sample` produces no code, ever.

## Acceptance

- [x] Every artifact in `artifact-layout.md` §1 exists here.
- [x] Each validates against its contract's validation section.
- [x] Phase order (`artifact-layout.md` §2) is respected: no artifact's upstream phase is incomplete.
