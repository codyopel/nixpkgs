{ stdenv, fetchurl, pkgconfig
, libraw1394, libusb1
, examplesSupport ? true, libX11 ? null, libXext ? null, libXv ? null, mesa ? null, SDL ? null, libv4l ? null
}:

# not detecting libusb1

let
  inherit (stdenv) isLinux;
  inherit (stdenv.lib) optional optionals;
in

assert examplesSupport -> libX11 != null
                       && libXext != null
                       && libXv != null
                       && mesa != null
                       && SDL != null
                       && libv4l != null
                       && isLinux;

stdenv.mkDerivation rec {
  name = "libdc1394-2.2.3";

  src = fetchurl {
    url = "mirror://sourceforge/libdc1394/${name}.tar.gz";
    sha256 = "1p9b4ciy97s04gmp7656cybr1zfd79hlw0ffhfb52m3zcn07h6aa";
  };

  configureFLags = [
    "--enable-examples"
  ];

  nativeBuildInput = [ pkgconfig ];

  buildInputs = [ libusb1 ]
    ++ optional isLinux [ libraw1394 ]
    ++ optionals (examplesSupport && isLinux) [ libX11 libXext libXv mesa SDL libv4l ];

  meta = with stdenv.lib; {
    homepage = http://sourceforge.net/projects/libdc1394/;
    description = "Capture and control API for IIDC compliant cameras";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ codyopel viric ];
    platforms = platforms.unix;
  };
}
