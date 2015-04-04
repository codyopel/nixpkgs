
{ stdenv, fetchFromGitHub, pkgconfig
, cinnamon-desktop, cinnamon-menus, cinnamon-settings-daemon
, clutter
, fontconfig
, gdk_pixbuf
, glib
, gtk3
, pulseaudio
, libcanberra #_gtk3
, libgnomekdb
, libnotify
, libX11
, libxklavier
, libxml2
, modem-manager
, network-manager
, network-manager-applet
, polkit
, systemd
, colordSupport ? false, colord ? null, gnome-color-manager ? null
, cupsSupport ? false, cups ? null, system-config-printer-gnome ? null, cups-pk-helper ? null
, wacomSupport ? false, libwacom ? null, libXi ? null
, socialwebSupport ? false
}:

let
  inherit (stdenv.lib) optional optionals enableFeature;

  withFeature = enable: flag: "--${if enable then "with" else "without"}-${flag}";
in

stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "cinnamon-control-center";
  version = "2.4.2";

  src = fetchFromGitHub {
    owner  = "linuxmint";
    repo   = "${pname}";
    rev    = "${version}";
    sha256 = "0kivqdgsf8w257j2ja6fap0dpvljcnb9gphr3knp7y6ma2d1gfv3";
  };

  #patches = [ ./region.patch];

  patchPhase = ''
    patchShebangs autogen.sh
  '';

  configureFlags = [
    "--disable-documentation" # maybe optional?
    "--enable-systemd"
    (enableFeature cupsSupport "cups")
    (withFeature socialwebSupport "libsocialweb")
    "--disable-update-mimedb"
  ];

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [
    cinnamon-desktop cinnamon-menus cinnamon-settings-daemon
  ];

  meta = with stdenv.lib; {
    description = "";
    homepage = http://cinnamon.linuxmint.com;
    license = licenses.;
    maintainers = with maintainers; [ codyopel ];
    platforms = platforms.linux;
  };
}
