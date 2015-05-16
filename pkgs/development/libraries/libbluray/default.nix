{ stdenv, fetchurl, autoreconfHook, pkgconfig
, fontconfig, freetype, libxml2
, withAACS ? true, libaacs ? null, jdk ? null, ant ? null
}:

assert withAACS -> jdk != null && ant != null && libaacs != null;

let
  inherit (stdenv.lib) enableFeature optional optionals optionalString;
  withFeature = optSet: flag: "--with${if optSet then "" else "out"}-${flag}";
in

stdenv.mkDerivation rec {
  name = "libbluray-${version}";
  version  = "0.8.0";

  src = fetchurl {
    url = "https://download.videolan.org/pub/videolan/libbluray/${version}/${name}.tar.bz2";
    sha256 = "027xbdbsjyp1spfiva2331pzixrzw6vm97xlvgz16hzm5a5j103v";
  };

  # Fix search path for BDJ jarfile
  #patches = optional withAACS ./BDJ-JARFILE-path.patch;

  preConfigure = optionalString withAACS ''
    export JDK_HOME=${jdk.home}
    export LIBS="$LIBS -L${libaacs} -laacs"
  '';

  configureFlags = [
    (enableFeature withAACS "bdjava")
    "--enable-udf"
    "--with-fontconfig"
    "--with-freetype"
    "--with-libxml2"
  ];

  nativeBuildInputs = [ autoreconfHook pkgconfig ]
    ++ optional withAACS ant;

  buildInputs = [ fontconfig freetype libxml2 ]
    ++ optional withAACS jdk;

  propagatedBuildInputs = optional withAACS libaacs;

  meta = with stdenv.lib; {
    description = "Library to access Blu-Ray disks for video playback";
    homepage = http://www.videolan.org/developers/libbluray.html;
    license = licenses.lgpl21;
    maintainers = with maintainers; [ abbradar ];
    platforms = platforms.all;
  };
}
