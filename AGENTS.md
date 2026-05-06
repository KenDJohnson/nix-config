# nix-config AGENTS guide

## Tool usage
- This project uses `jj` (backed by `git`) but not `git` directly. Use `jj` commands an workflows rather than
  git.
- Use `nh search <QUERY>` to find nix packages
- Use `nh darwin build .` or `nh os build .`/`nh home build .` to test changes for darwin/nix os/home-manager

## Repository expectations

- Sensitive configuration should use `ragenix` to avoid committing sensitive information to this public repo.
  Be more cautious than lax here, err on the side of using `ragenix`, and ask when in doubt.
