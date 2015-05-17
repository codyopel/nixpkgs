{ stdenv, fetchurl, makeDesktopItem, makeWrapper, ninja, python
, alsaLib, atk, cairo, cups, dbus, glib, expat, fontconfig, freetype #, gconf
, gdk_pixbuf, gtk, libcap, libgnome_keyring3, libgpgerror, nspr, nss, pango
, xlibs, zlib
}:

stdenv.mkDerivation rec {
  name = "electron-${version}";
  version = "0.26.0";

  src = fetchurl {
    url = "https://github.com/atom/electron/archive/v${version}.tar.gz";
    sha256 = "1bwpc8fx9xz3l22fn6dq8sgf6qflmfn3gqdbxfx2viq74jqm8yrn";
  };

  patchPhase = ''
    patchShebangs .
  '';

  nativeBuildInputs = [ ninja python ];

  buildInputs = [
    alsaLib atk cairo cups dbus glib expat fontconfig freetype
    gdk_pixbuf gtk libcap libgnome_keyring3 libgpgerror nspr nss pango
    xlibs zlib
  ];

  buildPhase = ''
    ./script/build.py
  '';

  meta = with stdenv.lib; {
    description = "Framework for writing desktop applications using JavaScript, HTML and CSS";
    homepage = http://electron.atom.io/;
    license = licenses.mit;
    maintainers = with maintainers; [ codyopel ];
    platforms = platforms.all;
  };
}
