{ stdenv, fetchFromGitHub, pkgconfig, autoreconfHook, glib, gettext, gnome_common, gtk3, dbus_glib
, upower, json_glib,intltool, systemd, hicolor_icon_theme, xorg, makeWrapper, cinnamon-desktop
}:

stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "cinnamon-session";
  version = "2.4.3";

  src = fetchFromGitHub {
    owner  = "linuxmint";
    repo   = "${pname}";
    rev    = "${version}";
    sha256 = "0kivqdgsf8w257j2ja6fap0dpvljcnb9gphr3knp7y6ma2d1gfv3";
  };

  #patches = [ ./remove-sessionmigration.patch ./timeout.patch];

  patchPhase = ''
    patchShebangs autogen.sh
  '';

  configureFlags = "--enable-systemd --disable-gconf" ;

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [
    autoreconfHook
    glib gettext gnome_common
    gtk3 dbus_glib upower json_glib
    intltool systemd xorg.xtrans
    makeWrapper
    cinnamon-desktop /*gschemas*/
  ];

  #postFixup  = ''
  #  rm $out/share/icons/hicolor/icon-theme.cache
  #  for f in "$out/bin/"*; do
  #    wrapProgram "$f" --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
  #  done
  #'';

  meta = with stdenv.lib; {
    description = "";
    homepage = http://cinnamon.linuxmint.com;
    license = licenses.;
    maintainers = with maintainers; [ codyopel ];
    platforms = platforms.linux;
  };
}
