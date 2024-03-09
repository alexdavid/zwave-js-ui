{
  outputs = { self, nixpkgs }:
    let
      buildForSystem = system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
          src = builtins.path {
            name = "zwave-js-ui-src";
            path = ./.;
            filter = path: type:
              !builtins.elem
              (lib.lists.last (lib.strings.splitString "/" path)) [
                "flake.nix"
                "flake.lock"
              ];
          };
          zwave-js-ui-build = pkgs.runCommand "zwave-js-ui-build" {
            buildInputs = [ pkgs.nodejs ];
          } ''
            cp -r ${src} $out
            chmod -R +w $out
            cd $out
            for scriptlink in node_modules/.bin/*; do
              script=$(readlink --canonicalize "$scriptlink")
              patchShebangs --build "$script"
            done
            npm run build
          '';
          bin = pkgs.writeShellApplication {
            name = "z-wave-js-ui";
            runtimeInputs =
              [ pkgs.bash pkgs.bubblewrap pkgs.coreutils pkgs.nodejs ];
            text = ''
              STORE_DIR=''${1-}
              if [ -z "$STORE_DIR" ]; then
                echo "Usage: zwave-js-ui /path/to/store/directory"
                echo "Store directory will be created if it does not exist"
                exit 1
              fi

              mkdir -p "$STORE_DIR"
              exec bwrap \
                --ro-bind /nix/store /nix/store \
                --ro-bind ${zwave-js-ui-build} /zwave-js-ui \
                --bind "$STORE_DIR" /zwave-js-ui/store \
                --chdir /zwave-js-ui \
                --unshare-all \
                --share-net \
                --hostname zwavejsjail \
                -- \
                npm start
            '';
          };
        in bin;
    in {
      packages.x86_64-linux.default = buildForSystem "x86_64-linux";
      packages.aarch64-linux.default = buildForSystem "aarch64-linux";
    };
}
