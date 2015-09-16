{ callPackage, ... } @ args:

callPackage ./generic.nix (args // {
  # Short-Lived
  versionMajor = "355";
  versionMinor = "11";
  i686sha256 = "049xg5fgckqbi8p80y1jpvxl1kl9bvsbzhmafa70wibarq7d1j1m";
  x8664sha256 = "0hpqs2iqwqhdq2c2qsrg4phqwdbblnnglxgkmx217hazl1i6mk0g";
  arm32sha256 = "1ph4cb6nrk2hiy89j3kz1xj16ph0b9yixrf4f4935rnzhha8x31w";
})