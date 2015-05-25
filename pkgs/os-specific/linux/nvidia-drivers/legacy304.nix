{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  versionMajor = "304";
  versionMinor = "125";
  i686sha256 = "1ph4cb6nrk2hiy89j3kz1wj16ph0b9yixrf4f4935rnzhha8x31w";
  x8664sha256 = "08p6hikn7pbfg0apnsbaqyyh2s9m5r0ckqzgjvxirn5qcyll0g5a";
  arm32sha256 = null;
})
