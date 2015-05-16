{ stdenv, fetchurl, flex, yacc
, libgcrypt, libgpgerror
}:

# Info on how to use / obtain aacs keys:
# http://vlc-bluray.whoknowsmy.name/
# https://wiki.archlinux.org/index.php/BluRay

stdenv.mkDerivation rec {
  name = "libaacs-${version}";
  version  = "0.8.1";

  src = fetchurl {
    url = "https://download.videolan.org/pub/videolan/libaacs/${version}/${name}.tar.bz2";
    sha256 = "1s5v075hnbs57995r6lljm79wgrip3gnyf55a0y7bja75jh49hwm";
  };

  nativeBuildInputs = [ flex yacc ];

  buildInputs = [ libgcrypt ];

  meta = with stdenv.lib; {
    description = "Implementation of the Advanced Access Content System";
    homepage = http://www.videolan.org/developers/libbluray.html;
    license = licenses.lgpl21;
    maintainers = with maintainers; [ abbradar ];
    platforms = platforms.all;
  };
}
