
{ stdenv, fetchFromGitHub, pkgconfig
, glib, gettext, gnome_common, gtk3,intltool,
cinnamon-desktop, clutter, cogl, zenity, python, gnome_doc_utils, makeWrapper
}:

stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "muffin";
  version = "2.4.5";

  src = fetchFromGitHub {
    owner  = "linuxmint";
    repo   = "${pname}";
    rev    = "${version}";
    sha256 = "0kivqdgsf8w257j2ja6fap0dpvljcnb9gphr3knp7y6ma2d1gfv3";
  };

  #patches = [./gtkdoc.patch];

  patchPhase = ''
    patchShebangs autogen.sh
  '';

  configureFlags = [
    "--enable-compile-warnings=minium"
  ];

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [
    autoreconfHook
    glib gettext gnome_common
    gtk3 intltool cinnamon-desktop
    clutter cogl zenity python
    gnome_doc_utils makeWrapper
  ];

  #postFixup  = ''
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
