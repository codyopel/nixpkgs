{ stdenv, fetchurl, cmake, pkgconfig
, sqlite, systemd
, tlsSupport ? true, openssl ? null
}:

let
  inherit (stdenv.lib) optional;
  mkFlag = optset: flag: if optset then "-D${flag}=ON" else "-D${flag}=OFF";
in

assert tlsSupport -> openssl != null;

stdenv.mkDerivation rec {
  name = "uhub-${version}";
  version = "0.5.0";

  src = fetchurl {
    url = "https://github.com/janvidar/uhub/archive/${version}.tar.gz";
    sha256 = "0ai6fvv075nk64al79piqj5i26ll2cq7wlzbrh6caigw9v59l5lf";
  };

  patchPhase = ''
    # Install plugins to $out/lib/uhub/ instead of /usr/lib/uhub/
    sed -e 's,/usr/lib/uhub/,lib/uhub/,' -i CMakeLists.txt
    # Install configs to $out/share/doc/ instead of /etc/uhub
    sed -e 's,/etc/uhub,doc/,' -i CMakeLists.txt
  '';

  cmakeFlags = [
    (mkFlag tlsSupport "SSL_SUPPORT")
    (mkFlag tlsSupport "USE_OPENSSL")
    "-DSYSTEMD_SUPPORT=ON"
  ];

  nativeBuildInputs = [ cmake pkgconfig ];

  buildInputs = [ sqlite systemd ]
    ++ optional tlsSupport openssl;

  meta = with stdenv.lib; {
    description = "High performance peer-to-peer hub for the ADC network";
    homepage = https://www.uhub.org/;
    license = licenses.gpl3;
    maintainers = with maintainers; [ emery ];
    platforms = platforms.unix;
  };
}