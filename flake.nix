{
  description = "gsay";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
  };
  outputs = { self, nixpkgs }:
    let
      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {
      packages = forAllSystems (system:
      {
        mapwacom = with import nixpkgs { system = "x86_64-linux"; }; pkgs.writeShellApplication {
          name = "mapwacom";

          # Disable spellcheck
          checkPhase = "";

          runtimeInputs = with pkgs; [
            xf86_input_wacom # provides xsetwacom
          ];

          text = (builtins.readFile ./mapwacom);
        };


        dmenu-mapwacom = with import nixpkgs { system = "${system}"; }; pkgs.writeShellApplication {
          name = "dmenu-mapwacom";

          runtimeInputs = with pkgs; [
            dmenu
            gawk
            xorg.xrandr
            gnugrep
            toybox # provides xargs
            self.packages.${system}.mapwacom
          ];

          text = ''
            xrandr | grep " connected " | awk '{ print$1 }' | dmenu | xargs mapwacom --device-regex='Pen' -s
          '';
        };

      });

      defaultPackage = forAllSystems (system: self.packages.${system}.dmenu-mapwacom);
    };
}
