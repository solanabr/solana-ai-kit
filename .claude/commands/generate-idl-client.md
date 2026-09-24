---
description: "Generate a typed client from an Anchor or Shank IDL (Codama or Anchor TS)"
---

Generate or refresh the client for a program. `$ARGUMENTS` can name the program, the IDL path, or the output directory.

Pipeline and repo layout: [idl-codegen.md](../skills/ext/solana-dev/skills/solana-dev/references/idl-codegen.md). Using the generated client: [kit/codama.md](../skills/ext/solana-dev/skills/solana-dev/references/kit/codama.md).

## Choose the generator

- Codama (default): renders a Kit-native TypeScript client, plus a Rust client if wanted, from an Anchor or Shank IDL. Use it for new clients, `@solana/kit` frontends, and every native or Pinocchio program.
- Anchor TS client (`@anchor-lang/core`): only when the app already builds on `Program`/`AnchorProvider`. There is nothing to generate: `anchor build` writes `target/idl/<name>.json` and `target/types/<name>.ts`, and `new Program(idl as MyProgram, provider)` takes the address from `idl.address`.
- Rust client or CPI from another Anchor program: `declare_program!(<name>)` reads `idls/<name>.json`. For a deployed program, `anchor idl fetch -o idls/<name>.json <PROGRAM_ID>` (Anchor 1.x reads the IDL from Program Metadata).

## Steps

1. Build the IDL from current code:
   - Anchor: `NO_DNA=1 anchor build` writes `target/idl/<name>.json`.
   - Native or Pinocchio with Shank macros: `cargo install shank-cli`, then `shank idl -r programs/<name> -o idl` (`-p <PROGRAM_ID>` sets the address). Check that the IDL has `metadata.origin: "shank"`: Codama reads Shank IDLs through its Anchor adapter and uses that field to pick 1-byte discriminators.
2. Generate with Codama:
   - Anchor CLIs with the `codama` subcommand (check `anchor codama --help`): `anchor codama generate -l js -p clients target/idl/<name>.json`, or set `[clients] auto = true` and `js = true` in Anchor.toml to regenerate on every `anchor build`.
   - Codama CLI: `npx codama init` (asks for the IDL path and renderers, writes `codama.json`, installs `@codama/renderers-js` and, for Anchor or Shank IDLs, `@codama/nodes-from-anchor`), then `npx codama run js` (or `--all`).
   - Script form, if the project already has one: `createFromRoot(rootNodeFromAnchor(idl)).accept(renderVisitor(outDir))`, with `createFromRoot` from `codama` and `renderVisitor` from `@codama/renderers-js`.
3. Typecheck the consumers (`npx tsc --noEmit`) and run the tests that use the client.
4. Commit generated code when consumers should not have to run codegen; otherwise wire generation into the build or CI. Regenerate after every instruction or account change.

## Output

IDL source and path, generator, output directory, instruction and account counts, typecheck result.
