{ callPackage, ... } @ args:

# WARNING: the beta (testing) drivers may be outdated and aren't guaranteed to be maintained

callPackage ./generic.nix (args // {
  versionMajor = "349";
  versionMinor = "12";
  i686sha256 = "1ph4cb6nrk2hiy89j3kz1wj16ph0b9yixrf4f4935rnzhha8x31w";
  x8664sha256 = "0vgdbdyg0awhv3yyv8n81y9vklxiimrl248szghfqlznhg6j44kx";
  arm32sha256 = "1ph4cb6nrk2hiy89j3kz1wj16ph0b9yixrf4f4935rnzhha8x31w";
})
