{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  # Legacy 340.xx
  versionMajor = "340";
  versionMinor = "93";
  i686sha256 = "1ph4cb6nrk2hiy89j3kz1wjx6ph0b9yixrf4f4935rnzhha8x31w";
  x8664sha256 = "0hs8qll6acl45gmbigimj9r1jab86041cbvwmdwcf5csaykk1clg";
  arm32sha256 = "1ph4cb6nrk2hiy89j3kz1wx16ph0b9yixrf4f4935rnzhha8x31w";
})
