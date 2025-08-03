# nix-metals

[![CI](https://github.com/what-the-functor/nix-metals/workflows/CI/badge.svg)](https://github.com/what-the-functor/nix-metals/actions)

Nix flake for [Metals](https://scalameta.org/metals/), Scala language server.

This flake tracks the latest Metals releases, providing more current updates than nixpkgs. Inspired by the upstream package in nixpkgs.

## Usage

### Run directly
```bash
# Latest version (1.6.1)
nix run github:what-the-functor/nix-metals

# Specific version
nix run github:what-the-functor/nix-metals#metals160
```

### Use in a flake
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-metals.url = "github:what-the-functor/nix-metals";
  };
  
  outputs = { nixpkgs, nix-metals, ... }:
    let
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        overlays = [ nix-metals.overlays.default ];
      };
    in {
      devShells.aarch64-darwin.default = pkgs.mkShell {
        packages = [
          pkgs.metals      # Latest (1.6.1)
          # pkgs.metals160  # Specific version
        ];
      };
    };
}
```

## Available packages

- `metals161` - Metals 1.6.1 (default)
- `metals160` - Metals 1.6.0

## Development

```bash
nix develop
```
