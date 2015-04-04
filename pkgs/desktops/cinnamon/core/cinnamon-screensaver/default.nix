{ stdenv, fetchFromGitHub, pkgconfig
}:

stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "cinnamon-screensaver";
  version = "2.4.2";

  src = fetchFromGitHub {
    owner  = "linuxmint";
    repo   = "${pname}";
    rev    = "${version}";
    sha256 = "0kivqdgsf8w257j2ja6fap0dpvljcnb9gphr3knp7y6ma2d1gfv3";
  };

  patchPhase = ''
    patchShebangs autogen.sh
  '';

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ ];

  meta = with stdenv.lib; {
    description = "";
    homepage = http://cinnamon.linuxmint.com;
    license = licenses.;
    maintainers = with maintainers; [ codyopel ];
    platforms = platforms.linux;
  };
}
