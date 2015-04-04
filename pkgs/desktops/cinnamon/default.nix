{ callPackage, pkgs }:

#  cinnamon = recurseIntoAttrs (callPackage ../desktops/cinnamon {
#    callPackage = pkgs.newScope pkgs.cinnamon;
#  });

rec {
  inherit (pkgs) glib gtk2 gtk3 gnome2;

#### Core

  #cinnamon-bluetooth       = callPackage ./core/cinnamon-bluetooth { };

  cinnamon-control-center  = callPackage ./core/cinnamon-control-center { };

  cinnamon-desktop         = callPackage ./core/cinnamon-desktop { };

  cinnamon-menus           = callPackage ./core/cinnamon-menus { };

  cinnamon-session         = callPackage ./core/cinnamon-session { };

  cinnamon-settings-daemon = callPackage ./core/cinnamon-settings-daemon { };

  cinnamon-screensaver     = callPackage ./core/cinnamon-screensaver { };

  cinnamon-themes          = callPackage ./core/cinnamon-themes { };

  cinnamon-translations    = callPackage ./core/cinnamon-translations { };

  cjs                      = callPackage ./core/cjs { };

  muffin                   = callPackage ./core/muffin { };

#### Apps

  #nemo

#### Dev

#### Misc

}
