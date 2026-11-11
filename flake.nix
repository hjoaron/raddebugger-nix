{
  description = "Epic Games RAD Debugger flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    raddebugger-src = {
      url = "github:EpicGames/raddebugger";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    raddebugger-src,
  }: let
    supportedSystems = ["x86_64-linux"];
  in
    flake-utils.lib.eachSystem supportedSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        x11Libs = with pkgs; [
          libx11
          libxext
          libxrandr
          libxfixes
        ];

        raddbgPkg = pkgs.clangStdenv.mkDerivation {
          pname = "raddebugger";
          version = "${raddebugger-src.shortRev or raddebugger-src.lastModifiedDate}";

          src = raddebugger-src;

          nativeBuildInputs = with pkgs; [
            pkg-config
            makeWrapper
            copyDesktopItems
            llvmPackages.llvm
          ];

          buildInputs =
            [
              pkgs.freetype
              pkgs.libGL
            ]
            ++ x11Libs;

          desktopItems = [
            (pkgs.makeDesktopItem {
              name = "raddbg";
              desktopName = "RAD Debugger";
              comment = "Native, user-mode, multi-process, graphical debugger";
              exec = "raddbg";
              icon = "raddbg";
              terminal = false;
              categories = ["Development" "Debugger"];
            })
          ];

          postPatch = ''
            patchShebangs build.sh
            substituteInPlace build.sh \
              --replace-fail 'auto_compile_flags=""' 'auto_compile_flags="-DBUILD_GIT_HASH=\"${raddebugger-src.shortRev or "unknown"}\" "'
          '';

          buildPhase = ''
            runHook preBuild

            chmod +x ./build.sh
            ./build.sh release raddbg raddbg_server radbin

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            install -Dm755 build/raddbg $out/bin/raddbg
            install -Dm755 build/raddbg_server $out/bin/raddbg_server
            install -Dm755 build/radbin $out/bin/radbin

            install -Dm644 data/logo.png $out/share/pixmaps/raddbg.png
            install -Dm644 data/logo.png $out/share/icons/hicolor/256x256/apps/raddbg.png

            runHook postInstall
          '';

          postFixup = ''
            wrapProgram $out/bin/raddbg \
              --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.zenity pkgs.xdg-utils pkgs.llvmPackages.llvm]} \
              --set EGL_PLATFORM x11
          '';

          meta = {
            description = "Native, user-mode, multi-process, graphical debugger";
            homepage = "https://github.com/EpicGames/raddebugger";
            license = pkgs.lib.licenses.mit;
            mainProgram = "raddbg";
            platforms = supportedSystems;
          };
        };
      in {
        packages = {
          raddbg = raddbgPkg;
          raddebugger = raddbgPkg;
          default = raddbgPkg;
        };

        apps = rec {
          raddbg = {
            type = "app";
            program = "${raddbgPkg}/bin/raddbg";
            meta = raddbgPkg.meta;
          };
          raddebugger = raddbg;
          default = raddbg;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [raddbgPkg];
        };

        formatter = pkgs.alejandra;
      }
    )
    // {
      overlays.default = final: prev: {
        raddbg = self.packages.${final.system}.raddebugger;
        raddebugger = self.packages.${final.system}.raddebugger;
      };
    };
}
