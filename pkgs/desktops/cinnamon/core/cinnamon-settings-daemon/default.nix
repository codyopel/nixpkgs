
{ stdenv, fetchFromGitHub, pkgconfig, autoreconfHook, glib, gettext, gnome_common, cinnamon-desktop, intltool, gtk3,
libnotify, lcms2, libxklavier, libgnomekbd, libcanberra, pulseaudio, upower, libcanberra_gtk3, colord,
systemd, libxslt, docbook_xsl, makeWrapper, gsettings_desktop_schemas
}:

stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "cinnamon-settings-daemon";
  version = "2.4.3";

  src = fetchFromGitHub {
    owner  = "linuxmint";
    repo   = "${pname}";
    rev    = "${version}";
    sha256 = "0kivqdgsf8w257j2ja6fap0dpvljcnb9gphr3knp7y6ma2d1gfv3";
  };

  #patches = [ ./systemd-support.patch ./automount-plugin.patch ./dpms.patch];

  patchPhase = ''
    patchShebangs autogen.sh
  '';

  configureFlags = "--enable-systemd" ;

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [
    autoreconfHook
    glib gettext gnome_common
    intltool gtk3 libnotify lcms2
    libgnomekbd libxklavier colord
    libcanberra pulseaudio upower
    libcanberra_gtk3 cinnamon-desktop
    systemd libxslt docbook_xsl makeWrapper
    gsettings_desktop_schemas
  ];

  # ToDo: missing org.cinnamon.gschema.xml, probably not packaged yet
  #postFixup  = ''
  #  for f in "$out/libexec/"*; do
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
