{ stdenv, fetchurl
, libraw1394, libusb1, libXext
, examplesSupport ? true,libX11 ? null, mesa ? null, SDL ? null, v4l_utils ? null
}:

assert examplesSupport -> libX11 != null
                       && mesa != null
                       && SDL != null
                       && v4l_utils != null;

let
  inherit (stdenv) isLinux;
  inherit (stdenv.lib) optional optionals;
in

stdenv.mkDerivation rec {
  name = "libdc1394-2.2.3";

  src = fetchurl {
    url = "mirror://sourceforge/libdc1394/${name}.tar.gz";
    sha256 = "1p9b4ciy97s04gmp7656cybr1zfd79hlw0ffhfb52m3zcn07h6aa";
  };

  configureFLags = [
    "--enable-examples"
  ];

  buildInputs = [ libusb1 SDL ]
    ++ optional isLinux [ libraw1394 ]
    ++ optionals examplesSupport [ libX11 libXext mesa SDL v4l_utils ];

  meta = {
    homepage = http://sourceforge.net/projects/libdc1394/;
    description = "Capture and control API for IIDC compliant cameras";
    license = stdenv.lib.licenses.lgpl21Plus;
    maintainers = [ stdenv.lib.maintainers.viric ];
    platforms = stdenv.lib.platforms.unix;
  };
}
