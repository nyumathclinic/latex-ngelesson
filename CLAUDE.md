# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The NGE Lesson Bundle: a LaTeX package that produces four related class files for
running a class session, all generated from a single literate source file,
[ngelesson.dtx](ngelesson.dtx):

- `ngelessonslides.cls` — projected slides (derives from `beamer`)
- `ngelessonhandout.cls` — handout version of the slides (`beamer` with the `handout` option)
- `ngelessonplan.cls` — lecture notes for the instructor (`article` + `beamerarticle`)
- `ngelessonworksheet.cls` — in-class worksheets/assessments (`article`)

There is no separate source per class file — everything lives in `ngelesson.dtx` and is
split apart by `docstrip` guards.

## Build commands

The build system is [l3build](https://ctan.org/pkg/l3build) (config in [build.lua](build.lua),
module name `ngelesson`), driven by `texlua`/`l3build` on the CLI.

- `l3build doc` — typeset `ngelesson.dtx` into documentation (`ngelesson.pdf`)
- `l3build unpack` — run `docstrip` to extract `ngelesson.ins` and the four `.cls` files
  into `build/unpacked` (and the `README`)
- `l3build check` — run the regression test suite (compiles `testfiles/*.lvt` and diffs
  the log against the matching `testfiles/*.tlg`)
- `l3build check <name>` — run a single test, e.g. `l3build check ws1`
- `l3build save` — regenerate the `.tlg` reference log(s) after an intentional change
  (use `l3build save <name>` for a single test); review the diff before committing
- `l3build save -e luatex test` — save an engine-specific reference log when output
  differs under LuaTeX (see the comment block at the top of `build.lua`); engine-specific
  `.tlg` files exist for tests where pdfTeX/XeTeX and LuaTeX genuinely diverge (e.g.
  `ws1s.luatex.tlg` vs `ws1s.xetex.tlg` vs `ws1s.tlg`)
- `l3build clean` — remove build artifacts

Test sources (`*.lvt`) and reference logs (`*.tlg`) live in [testfiles/](testfiles/).
A test is a minimal document using one of the four classes; the `.tlg` is the expected
compilation log/transcript to diff against.

## Tagging a release

`build.lua` defines a `tag_hook` invoked by l3build's tagging support. Tagging a version
(tag name must match `v<major>.<minor>.<patch>`, e.g. `v2.1.1`):

1. Requires a clean working tree (`git diff-index --quiet HEAD`).
2. Rewrites version/date strings inside `ngelesson.dtx` (`update_tag`): the `%<classes>[...]`
   line, the most recent `\changes{unreleased}` entry, `\fileversion`, and `\filedate`.
3. Commits the result as "Log changes for version `<tag>`" and creates an annotated git tag.

Because of this, new entries in the changelog inside `ngelesson.dtx` should be added under
a `\changes{unreleased}{...}{...}` heading (see the `\changes` list near the top of the
`driver`/documentation section of the .dtx) — the tag hook promotes `unreleased` to the
real version string automatically.

## Version control info in output (`vc`)

`ngelesson.ins` shells out to `./vc` (a CTAN `vc` bundle script) during docstrip processing
to write `vc.tex`, embedding the current git commit info into generated documentation.
`vc-git.awk` does the formatting. This only runs when docstrip's `\write18` is enabled
(shell escape).

## Code architecture inside ngelesson.dtx

The `.dtx` file is a single docstrip/doc literate source split into named guarded regions
(`%<*name>` ... `%</name>`), combined with `|` for shared code:

- `internal` / `install` / `driver` — bootstrapping regions that generate `ngelesson.ins`,
  the `README`, and the documentation driver; not part of the classes themselves.
- `classes` — code common to all four class files.
- `slides`, `handout`, `plan`, `worksheet` — code specific to one class file.
- Combined guards like `slides|handout` or `plan|worksheet` mark code shared by exactly
  those two variants (e.g. base class selection, theorem-like environments).

Key structural points when editing:

- The base class per variant is chosen via `\ngelesson@baseclass`, conditionally defined
  per guard (`beamer` for slides/handout, `article` for plan/worksheet), then loaded with
  `\LoadClass{\ngelesson@baseclass}`. `handout` additionally passes the `handout` option to
  `beamer`; `plan` additionally loads `beamerarticle` so beamer-style markup still works in
  plain article mode.
- Class options are declared with `\DeclareOption` before the base class is loaded; unknown
  options are passed straight through to the base class via `\DeclareOption*`.
  `bigmath`/`nobigmath` toggle display-style vs text-style inline math and apply to all
  variants; `solutions` is worksheet-only and sets the `worksheetsolutions` boolean used
  later to show/hide solution content.
- Documentation for each macro/environment is interleaved with the code using standard
  `doc`/`ldoc` conventions (`\begin{macro}{...}` blocks, `\section`/`\subsection` headers,
  `\changes{version}{date}{description}` entries) — keep new macros documented the same way
  so `l3build doc` output and `\PrintChanges`/`\PrintIndex` stay accurate.

When making a change that affects only one class variant, edit inside that variant's guard;
when it affects several, either duplicate inside each guard or use a combined guard
(`a|b`) if the code is identical across those variants.
