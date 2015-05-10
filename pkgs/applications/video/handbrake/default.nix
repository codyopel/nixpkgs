
{ stdenv, config, fetchurl, autoconf, automake, libtool, m4, python, pkgconfig, yasm
, a52dec, bzip2, faac, fdk_aac, ffmpeg, fontconfig, freetype, fribidi, lame
, libass, libbluray, libdvdcss, libdvdnav, libdvdread, libmkv, libogg
, libsamplerate, libtheora, libvorbis, libvpx, libxml2, mp4v2, mpeg2dec, x264, x265
, useGtk ? true, dbus_glib ? null, glib ? null, gtk ? null, gst_all_1 ? null
  , intltool ? null, libnotify ? null, udev ? null
# This prevents ghb from starting in my tests
, useWebKitGtk ? false, webkitgtk ? null
}:

# Handbrake normally vendors copies of libraries it uses, for better control
# over library patches.  This derivation patches HB so it doesn't do that. The
# relevant patches are added to Nix packages and proposed upstream instead.
# In several cases upstream already incorporated these patches.
# This has the benefits of providing improvements to other packages,
# making licenses more clear and reducing compile time/install size.
#
# For compliance, the unfree codec faac is optionally spliced out.

let
  inherit (stdenv.lib) enableFeature optional optionals;
  allowUnfree = config.allowUnfree or false;
in

stdenv.mkDerivation rec {
  name = "handbrake-${version}";
  version = "0.10.1";

  src = fetchurl {
    url = "http://download.handbrake.fr/releases/${version}/HandBrake-${version}.tar.bz2";
    sha256 = "1x93i8snngx9s67z0yvg7ga0ziajr5wsx6isj02gspjdzlqj193y";
  };

  patches = optional (!allowUnfree) ./disable-unfree.patch;

  configureFlags = [
    "--prefix=$(out)"
    "--force"
    "--verbose"
    #"--enable-asm"
    "--disable-gtk-update-checks"
    (if useGtk then "" else "--disable-gtk")
    #"--enable-qsv"
    #"--enable-hwd"
    "--enable-x265"
    "--enable-fdk-aac"
    #"--enable-local-yasm"
    #"--enable-local-autotools"
    #"--enable-local-cmake"
    #"--enable-local-pkgconfig"
  ];

  preConfigure = ''
    # Fake wget to prevent downloads
    mkdir wget
    echo "#!/bin/sh" > wget/wget
    echo "echo ===== Not fetching \$*" >> wget/wget
    echo "exit 1" >> wget/wget
    chmod +x wget/wget
    export PATH=$PATH:$PWD/wget

    # Force using nixpkgs dependencies
    sed -i 's:.*\(/contrib\|contrib/\).*::g' make/include/main.defs
    #sed -i '/MODULES += contrib/d' make/include/main.defs
    #sed -i '/PKG_CONFIG_PATH=/d' gtk/module.rules

    # disable faac if non-free
    if [ -z "$allowUnfree" ]; then
      rm -f libhb/encfaac.c
    fi
  '';

  buildInputsX = optionals useGtk [
    glib gtk intltool libnotify
    gst_all_1.gstreamer gst_all_1.gst-plugins-base dbus_glib udev
  ] ++ optional useWebKitGtk webkitgtk;

  # Did not test compiling with it
  unfreeInputs = optional allowUnfree faac;

  nativeBuildInputs = [ autoconf automake libtool m4 pkgconfig python yasm ];

  buildInputs = [
    fribidi fontconfig freetype
    libass libsamplerate libxml2 bzip2
    libogg libtheora libvorbis libdvdcss a52dec libmkv fdk_aac
    lame ffmpeg libdvdread libdvdnav libbluray mp4v2 mpeg2dec x264 x265
  ] ++ buildInputsX ++ unfreeInputs;

  preBuild = ''
    cd build
  '';

  meta = with stdenv.lib; {
    description = "A tool for ripping and transcoding video";
    longDescription = ''
      Handbrake is a versatile transcoding DVD ripper. This package
      provides the cli HandbrakeCLI and the GTK+ version ghb.
      The faac library is disabled if you're compiling free-only.
    '';
    homepage = http://handbrake.fr/;
    license = licenses.gpl2;
    maintainers = with maintainers; [ wmertens ];
    platforms = platforms.linux;
  };
}
