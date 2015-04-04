{ stdenv, fetchFromGitHub, pkgconfig, libtool, intltool
, python_2_7
, gstreamer
, clutter
, gjs
, gobjectIntrospection
, muffin
, gio
, polkit
, startup-notifications
, gio-unix-2
, gdk
, gnome-keyring
}:

stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "cinnamon";
  version = "2.4.7";

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
    pkgconfig autoreconfHook intltool
    glib gobjectIntrospection gdk_pixbuf gtk3 gnome_common
    xkeyboard_config libxkbfile libX11 libXrandr libXext
  ];

  meta = with stdenv.lib; {
    description = "";
    homepage = http://cinnamon.linuxmint.com;
    license = licenses.;
    maintainers = with maintainers; [ codyopel ];
    platforms = platforms.linux;
  };
}
