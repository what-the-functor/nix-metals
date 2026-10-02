{
  description = "Nix flake for Metals Scala language server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs =
    { self, nixpkgs }:
    let
      metalsVersions = {
        metals169 = {
          version = "1.6.9";
          hash = "sha256-0P9UG3STfdAkST1UrlUUtvqOGnVfea/w17mMuweY3Ag=";
        };

        metals168 = {
          version = "1.6.8";
          hash = "sha256-FUJnkYZ4nsJvbR3N13jA82Oi10fZ6B/KMpXN7ds+RI8=";
        };

        metals167 = {
          version = "1.6.7";
          hash = "sha256-bGx3PQGgaTueQ/v/Xk7gp03TzllyMs7nCx9QWXNFdt0=";
        };

        metals166 = {
          version = "1.6.6";
          hash = "sha256-Snx4JvWOTkJcihVRwj25op4BJqmChz+1fZH/PrCCbt0=";
        };

        metals165 = {
          version = "1.6.5";
          hash = "sha256-NOS1HUS4TJXnleZTEji3HAHUa9WOGmJDX2yT7zwmX08=";
        };

        metals164 = {
          version = "1.6.4";
          hash = "sha256-MuzyVyTOVWZjs+GPqrztmEilirRjxF9SJIKyxgicbXM=";
        };
        metals163 = {
          version = "1.6.3";
          hash = "sha256-H5rIpz547pXID86OUPMtKGNcC5d5kxMMEUvaqDck2yo=";
        };
        metals162 = {
          version = "1.6.2";
          hash = "sha256-WcPgX0GZSqpVVAzQ1zCxuRCkwcuR/8bwGjSCpHneeio=";
        };
        metals161 = {
          version = "1.6.1";
          hash = "sha256-OsA+AWNYBmQ9wfUq1O4WKTf4ANCvBErKLUXH6NRfMss=";
        };
        metals160 = {
          version = "1.6.0";
          hash = "sha256-+6u/nnaoCBEQCwhvPs1WQzMnppz7KEWWd1TlzbKYpAU=";
        };
      };

      defaultVersion = builtins.head (
        builtins.sort (
          a: b: builtins.compareVersions metalsVersions.${a}.version metalsVersions.${b}.version > 0
        ) (builtins.attrNames metalsVersions)
      );

      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
          }
        );

      mkMetals =
        {
          stdenv,
          lib,
          coursier,
          jre,
          makeWrapper,
          setJavaClassPath,
          version,
          hash,
        }:
        stdenv.mkDerivation (finalAttrs: {
          pname = "metals";
          inherit version jre;

          deps = stdenv.mkDerivation {
            name = "metals-deps-${version}";
            buildCommand = ''
              export COURSIER_CACHE=$(pwd)
              ${coursier}/bin/cs fetch org.scalameta:metals_2.13:${version} \
              -r bintray:scalacenter/releases \
              -r sonatype:snapshots > deps
              mkdir -p $out/share/java
              cp $(< deps) $out/share/java/
            '';
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = hash;
          };

          nativeBuildInputs = [
            makeWrapper
            setJavaClassPath
          ];
          buildInputs = [ finalAttrs.deps ];

          dontUnpack = true;

          extraJavaOpts = "-XX:+UseG1GC -XX:+UseStringDeduplication -Xss4m -Xms100m";

          installPhase = ''
            mkdir -p $out/bin

            makeWrapper ${finalAttrs.jre}/bin/java $out/bin/metals \
            --add-flags "${finalAttrs.extraJavaOpts} -cp $CLASSPATH scala.meta.metals.Main"
          '';

          meta = with lib; {
            homepage = "https://scalameta.org/metals/";
            license = licenses.asl20;
            description = "Language server for Scala";
            mainProgram = "metals";
            maintainers = [ what-the-functor ];
          };
        });

      withDefault = attrs: attrs // { default = attrs.${defaultVersion}; };
    in
    rec {
      packages = forAllSystems (
        { pkgs }:
        withDefault (
          pkgs.lib.mapAttrs (
            name: info: pkgs.callPackage mkMetals { inherit (info) version hash; }
          ) metalsVersions
        )
      );

      apps = forAllSystems (
        { pkgs }:
        withDefault (
          pkgs.lib.mapAttrs (name: pkg: {
            type = "app";
            program = "${pkg}/bin/metals";
          }) packages.${pkgs.system}
        )
      );

      devShells = forAllSystems (
        { pkgs }:
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.coursier
              formatter.${pkgs.system}
            ];
          };
        }
      );

      formatter = forAllSystems ({ pkgs }: pkgs.nixfmt-rfc-style);

      lib = {
        inherit mkMetals metalsVersions;
      };

      overlays.default =
        final: prev:
        builtins.mapAttrs (
          name: info: final.callPackage mkMetals { inherit (info) version hash; }
        ) metalsVersions
        // {
          metals = final.callPackage mkMetals {
            inherit (metalsVersions.${defaultVersion}) version hash;
          };
        };
    };
}
