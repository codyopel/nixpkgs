{ stdenv, fetchurl, pkgconfig, libx11, libxproto, libxt }:

stdenv.mkDerivation rec {
  name = "appres-${version}";
  version = "";

  src = fetchurl {
    url = "mirror://xorg/app/${name}.tar.bz2";
    sha256 = "173w0pqzk2m7hjlg15bymrx7ynxxq1ciadg03hzybxwnvfi4gsmx";
  };

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ libx11 libxproto libxt ];

  meta = with stdenv.lib; {
    description = "X application resource database";
    homepage    = http://www.x.org/wiki/;
    license     = licenses.mit;
    platforms   = platforms.linux;
    maintainers = with maintainers; [ codyopel ];
  };
}
