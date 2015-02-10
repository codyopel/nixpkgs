{ stdenv, fetchurl, fox, freetype, gcc, gettext, pkgconfig, intltool, file, libpng, x11
, xrandrSupport ? false, xrandr ? null # XRandR Support
, snSupport ? true # Starup notification support
}:

# Segmentation fault error

let
  mkFlag = optSet: flag: if optSet then "--enable-${flag}" else "--disable-${flag}";
in

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "xfe-${version}";
  version = "1.40";

  src = fetchurl {
    url = "mirror://sourceforge/xfe/${name}.tar.gz";
    sha256 = "1a32d2in4s25hr4znqvchs5sgv3wpdcnbknlbpl1q6pzpqanyirb";
  };

  # Fix hardcoded icon path
  patchPhase = ''
    sed -e 's,/usr/share/xfe,$out/share/xfe,' -i src/xfedefs.h
  '';

  configureFlags = [
    (mkFlag snSupport "sn")
  ] ++ optional xrandrSupport "--with-xrandr";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ fox freetype gettext gcc intltool file libpng x11 ]
    ++ optional xrandrSupport xrandr;

  enableParallelBuilding = true;

  meta = {
    description = "MS-Explorer like file manager for X";
    homepage    = http://roland65.free.fr/xfe/;
    license     = licenses.gpl2;
    maintainers = with maintainers; [ bbenoist codyopel ];
    platforms   = platforms.linux;
    longDescription = ''
      X File Explorer (Xfe) is an MS-Explorer like file manager for X.
      It is based on the popular, but discontinued, X Win Commander, which was developed by Maxim Baranov.
      Xfe aims to be the filemanager of choice for all the Unix addicts!
    '';
  };
}
