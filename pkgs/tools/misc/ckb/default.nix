{ stdenv, fetchFromGitHub, libudev, pkgconfig, qtbase, qmakeHook, zlib }:

stdenv.mkDerivation rec {
  version = "0.2.6";
  name = "ckb-${version}";

  src = fetchFromGitHub {
    owner = "ccMSC";
    repo = "ckb";
    rev = "v${version}";
    sha256 = "04h50qdzsbi77mj62jghr52i35vxvmhnvsb7pdfdq95ryry8bnwm";
  };

  buildInputs = [
    libudev
    qtbase
    zlib
  ];

  nativeBuildInputs = [
    pkgconfig
    qmakeHook
  ];

  patches = [
    ./ckb-animations-location.patch
  ];

  doCheck = false;

  installPhase = ''
    install -D --mode 0755 --target-directory $out/bin bin/ckb-daemon bin/ckb
    install -D --mode 0755 --target-directory $out/libexec/ckb-animations bin/ckb-animations/*
  '';

  meta = with stdenv.lib; {
    description = "Driver and configuration tool for Corsair keyboards and mice";
    homepage = https://github.com/ccMSC/ckb;
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ kierdavis ];
  };
}
