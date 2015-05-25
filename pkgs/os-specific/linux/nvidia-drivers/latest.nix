{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  # If you bump the major version, bump it for the builder in generic.nix too
  versionMajor = "349";
  versionMinor = "16";
  i686sha256 = "049xg5fgckqbi8p80y1jpvzl1kl9bvsbzhmafa70wibarq7d1j1m";
  x8664sha256 = "0vgdbdyg0awhv3yyv8n81y9vklxiimrl248szghfqlznhg6j44kx";
  arm32sha256 = "1ph4cb6nrk2hiy89j3kz1wj16ph0b9yixrf4f4935rnzhha8x31w";
})
