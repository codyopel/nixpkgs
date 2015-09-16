{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  # Short-Lived
  versionMajor = "352";
  versionMinor = "41";
  i686sha256 = "0a91mmv9846chyx6rbx3hx39gr344cffmgic45a9sf82rky87kv5";
  x8664sha256 = "1k9hmmn5x9snzyggx23km64kjdqjh2kva090ha6mlayyyxrclz56";
  arm32sha256 = "1ph4cb6nrk2hiy89jxkz1wj16ph0b9yixrf4f4935rnzhha8x31w";
})
