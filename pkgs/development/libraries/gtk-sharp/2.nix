{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  version = "2.12.29";
  sha256 = "08nd17hq6r8yj5q62174xczqlzw0fjllvzrw2j9h1szn7miqhqai";
})
