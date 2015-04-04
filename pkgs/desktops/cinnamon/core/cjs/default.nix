{ stdenv, fetchFromGitHub, pkgconfig, autoreconfHook, python
, dbus_glib, cairo, spidermonkey_185, gobjectIntrospection
}:

stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "cjs";
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

  buildInputs = [
    autoreconfHook python
    dbus_glib cairo spidermonkey_185
    gobjectIntrospection
  ];

  meta = with stdenv.lib; {
    description = "";
    homepage = http://cinnamon.linuxmint.com;
    license = licenses.;
    maintainers = with maintainers; [ codyopel ];
    platforms = platforms.linux;
  };
}
