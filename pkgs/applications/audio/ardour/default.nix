{ stdenv, fetchgit, makeWrapper, perl, pkgconfig, python
, alsaLib, aubio, boost, cairomm, curl, dbus, fftw, fftwSinglePrec, flac, glibc
, glibmm, gtk, gtkmm, jack2, libgnomecanvas, libgnomecanvasmm, liblo, libltc
, libmad, libogg, librdf, librdf_raptor, librdf_rasqal, libsamplerate, libsigcxx
, libsndfile, libusb, libuuid, libxml2, libxslt, lilv, lv2, pango, rubberband
, serd, sord, sratom, suil, taglib, vampSDK
}:

# TODO: Add windows vst support via wine

stdenv.mkDerivation rec {
  name = "ardour-${version}";
  version = "${major}.${minor}${if rev != "" then ".${rev}" else ""}";
  # <major>.<minor>.<rev>
  major = "4";
  minor = "0";
  rev   = ""; # Leave empty if no revsion, e.g. "" for 4.0

  src = fetchgit {
    url = git://git.ardour.org/ardour/ardour.git;
    rev = "refs/tags/${version}";
    sha256 = "0k0bhk7qhjzlzjbknpzfyz6x03w91s9q1n7hg588z9hnj7xnhrir";
  };

  patchPhase = ''
    # The version string compiled in to the binary uses the format:
    # <major>.<minor>-<rev>
    printf '#include "libs/ardour/ardour/revision.h"\nnamespace ARDOUR { const char* revision = \"${major}.${minor}${if rev != "" then "-${rev}" else ""}\"; }\n' > libs/ardour/revision.cc

    sed 's|/usr/include/libintl.h|${glibc}/include/libintl.h|' -i wscript

    patchShebangs ./tools/
  '';

  configureFlags = [
    "--with-backend=alsa,jack"
    "--fpu-optimization"
    "--optimize"
    "--debug-symbols"
    "--freedesktop"
    "--use-external-libs"
    "--lv2"
    "--lxvst"
    "--nls"
    "--no-phone-home"
    "--cxx11"
    "--address-sanitizer"
  ];

  configurePhase = "python waf configure --prefix=$out $configureFlags";

  nativeBuildInputs = [ makeWrapper perl pkgconfig python ];

  buildInputs = [
    alsaLib aubio boost cairomm curl dbus fftw fftwSinglePrec flac glibc glibmm
    gtk gtkmm jack2 libgnomecanvas libgnomecanvasmm liblo libltc libmad libogg
    librdf librdf_raptor librdf_rasqal libsamplerate libsigcxx libsndfile libusb
    libuuid libxml2 libxslt lilv lv2 pango rubberband serd sord sratom suil
    taglib vampSDK
  ];

  buildPhase = "python waf";

  installPhase = ''
    python waf install

    # For the custom ardour clearlooks gtk-engine to work, it must be
    # moved to a directory called "engines" and added to GTK_PATH
    mkdir -pv $out/gtk2/engines
    cp build/libs/clearlooks-newer/libclearlooks.so $out/gtk2/engines/
    wrapProgram $out/bin/ardour4 --prefix GTK_PATH : $out/gtk2

    # Install desktop entry file
    mkdir -p "$out/share/applications"
    cat > "$out/share/applications/ardour.desktop" << EOF
    [Desktop Entry]
    Name=Ardour 4
    GenericName=Ardour Digital Audio Workstation
    Comment=Multitrack harddisk recorder
    Exec=ardour4
    Icon=ardour4
    Terminal=false
    MimeType=application/x-ardour4;
    Type=Application
    X-MultipleArgs=false
    Categories=Audio;AudioVideo;AudioEditing;X-Recorders;X-Multitrack;X-Jack;
    EOF
  '';

  meta = with stdenv.lib; {
    description = "Multi-track hard disk recording software";
    longDescription = ''
      Ardour is a digital audio workstation (DAW), You can use it to
      record, edit and mix multi-track audio and midi. Produce your
      own CDs. Mix video soundtracks. Experiment with new ideas about
      music and sound.

      Please consider supporting the ardour project financially:
      https://community.ardour.org/node/8288
    '';
    homepage = http://ardour.org/;
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = [ maintainers.goibhniu ];
  };
}
