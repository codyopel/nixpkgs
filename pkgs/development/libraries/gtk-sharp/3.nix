{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  version = "2.99.3";
  sha256 = "1l9z5yfp1vq4z2y4mh91707dhcn41c3pd505i0gvdzcdsp5j6y77";
})
