# raddebugger-nix

Nix packaging for [RAD Debugger](https://github.com/EpicGames/raddebugger).

## Run directly

```bash
nix run github:hjoaron/raddebugger-nix
```

## Flake configuration

Add to inputs in `flake.nix`:

```nix
inputs.raddebugger.url = "github:hjoaron/raddebugger-nix";
```

Add to system or user packages:

```nix
environment.systemPackages = [
  inputs.raddebugger.packages.${pkgs.system}.default
];
```

Or via overlay:

```nix
nixpkgs.overlays = [
  inputs.raddebugger.overlays.default
];
