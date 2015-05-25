{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  # If you bump the major version, bump it for the builder in generic.nix too
  versionMajor = "346";
  versionMinor = "59";
  i686sha256 = "0a91mmv9846chyx6rbf3hx39gr344cffmgic45a9sf82rky87kv5";
  x8664sha256 = "0rz7pdzdviz1086w8ks6qiv83ah84y13h3051xr1p4wa4kll2yac";
  arm32sha256 = "1ph4cb6nrk2hiy89j3kz1wj16ph0b9yixrf4f4935rnzhha8x31w";
})
