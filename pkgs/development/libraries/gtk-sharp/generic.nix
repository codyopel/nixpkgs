{ stdenv, fetchurl, autoreconfHook, pkgconfig
# Autogen
, autoconf, automake, libtool, which
, atk
, glib
, gtk2
, gtk3
, libglade
, libxml2
, mono
, pango
#, GConf ? null
#, libgtkhtml ? null
#, gtkhtml ? null
#, libgnomecanvas ? null
#, libgnomeui ? null
#, libgnomeprint ? null
#, libgnomeprintui ? null
#, gnomepanel ? null
, monoDLLFixer
# Inherit generics
, version, sha256, ...
}:

let
  inherit (stdenv.lib) optional optionalString versionAtLeast versionOlder;
in

stdenv.mkDerivation rec {
  name = "gtk-sharp-${version}";
  inherit version;

  src = fetchurl {
    url = "https://github.com/mono/gtk-sharp/archive/${version}.tar.gz";
    inherit sha256;
  };

  # patch bad usage of glib, which wasn't tolerated anymore
  patchPhase = optionalString (versionOlder version "2.99.0") ''
    # Emulate the functionality of `bootstrap-2.12' (aka. autogen.sh)

    # Fix miss named configure script
    mv configure.in.in configure.ac

    export GTK_SHARP_VERSION="${version}"
    export ASSEMBLY_VERSION="2.12.0.0"
    export POLICY_VERSIONS="2.4 2.6 2.8 2.10"
    export GTK_REQUIRED_VERSION="2.12.0"
    export VERSIONCSDEFINES="-define:GTK_SHARP_2_6 -define:GTK_SHARP_2_8 -define:GTK_SHARP_2_10 -define:GTK_SHARP_2_12"
    export VERSIONCFLAGS="-DGTK_SHARP_2_6 -DGTK_SHARP_2_8 -DGTK_SHARP_2_10 -DGTK_SHARP_2_12"
    export GTK_API_TAG="2.12"

    sed -e "s/@GTK_SHARP_VERSION@/$GTK_SHARP_VERSION/" -i configure.ac
    sed -e "s/@GTK_REQUIRED_VERSION@/$GTK_REQUIRED_VERSION/" -i configure.ac
    sed -e "s/@VERSIONCSDEFINES@/$VERSIONCSDEFINES/" -i configure.ac
    sed -e "s/@VERSIONCFLAGS@/$VERSIONCFLAGS/" -i configure.ac
    sed -e "s/@POLICY_VERSIONS@/$POLICY_VERSIONS/" -i configure.ac
    sed -e "s/@ASSEMBLY_VERSION@/$ASSEMBLY_VERSION/" -i configure.ac

    ln -f ./pango/pango-api-$GTK_API_TAG.raw ./pango/pango-api.raw
    ln -f ./atk/atk-api-$GTK_API_TAG.raw ./atk/atk-api.raw
    ln -f ./gdk/gdk-api-$GTK_API_TAG.raw ./gdk/gdk-api.raw
    ln -f ./gtk/gtk-api-$GTK_API_TAG.raw ./gtk/gtk-api.raw
    ln -f ./glade/glade-api-$GTK_API_TAG.raw ./glade/glade-api.raw
  '' + optionalString (versionAtLeast version "2.99.0") ''
    #./autogen.sh
  ''+ ''    
    libtoolize --force --copy
    aclocal $ACLOCAL_FLAGS
    autoheader
    automake --add-missing --foreign
    autoconf
  '';

  configureFlags = [
    "--disable-maintainer-mode"
  ];

  builder = ./builder.sh;

  nativeBuildInputs = [ autoconf automake libtool pkgconfig ];

  buildInputs = [
    atk glib libglade libxml2 mono pango
    #GConf libgnomecanvas
    #libgtkhtml libgnomeui libgnomeprint libgnomeprintui gtkhtml
    #gnomepanel
  ] ++ (if versionOlder version "2.99.0" then [ gtk2 ] else [ gtk3 ]);

  dontStrip = true;

  inherit monoDLLFixer;

  passthru = {
    inherit gtk2;
    inherit gtk3;
  };

  meta = with stdenv.lib; {
    description = "";
    homepage = http://google.com;
    license = licenses.gpl2;
    maintainers = with maintainers; [ codyopel ];
    platforms = platforms.all;
  };
}
