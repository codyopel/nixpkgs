{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  version = "2.99.3";
  sha256 = "116kbb1v77sbgh90j74zhvbd00q2d2kda4i7dlph67lm16caa4k2";
})
