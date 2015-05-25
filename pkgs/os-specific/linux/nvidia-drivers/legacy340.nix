{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  versionMajor = "340";
  versionMinor = "76";
  i686sha256 = "1ph4cb6nrk2hiy89j3kz1wj16ph0b9yixrf4f4935rnzhha8x31w";
  x8664sha256 = "016hnsgrcm4ly0mnkcd6c1qkciy3qmbwdwy4rlwq3m6dh4ixw7jc";
  arm32sha256 = "1ph4cb6nrk2hiy89j3kz1wj16ph0b9yixrf4f4935rnzhha8x31w";
})
