{ stdenv, fetchurl, docutils, makeWrapper, perl, pkgconfig, python, which
# Required
, ffmpeg, freefont_ttf, freetype, libass, libpthreadstubs, lua, lua5_sockets
# Optional
, alsaLib ? null, jack2 ? null, libbluray ? null, libbs2b ? null, libcaca ? null, libdvdnav ? null
, libdvdread ? null, libpng ? null, libtheora ? null, libvdpau ? null
, pulseaudio ? null, SDL2 ? null, speex ? null, youtube-dl ? null


, x11Support ? true, libX11 ? null, libXext ? null, mesa ? null, libXxf86vm ? null
, xineramaSupport ? true, libXinerama ? null
, xvSupport ? true, libXv ? null

, screenSaverSupport ? true, libXScrnSaver ? null

, vaapiSupport ? false, libva ? null
}:

# zlib libdvdcss xz libgpgerror libjson-c libsndfile flac vorbis ogg dbus libcap
# xvidcore x264 libvpx theora lame gnutls 

# TODO: Wayland support
# TODO: investigate why libs are propagating to this build
# TODO: investigate lua5_sockets bug

let
  inherit (stdenv.lib) optional optionals optionalString;

  enFlag = optSet: flag: if optSet then "--enable-${flag}" else null;
  disFlag = optSet: flag: if optSet then "--disable-${flag}" else null;

  # Purity: Waf is normally downloaded by bootstrap.py, but
  # for purity reasons this behavior should be avoided.
  waf = fetchurl {
    url = http://ftp.waf.io/pub/release/waf-1.8.5;
    sha256 = "0gh266076pd9fzwkycskyd3kkv2kds9613blpxmn9w4glkiwmmh5";
  };
in

assert x11Support -> (libX11 != null && libXext != null && mesa != null && libXxf86vm != null);
assert xineramaSupport -> (libXinerama != null && x11Support);
assert xvSupport -> (libXv != null && x11Support);
assert screenSaverSupport -> libXScrnSaver != null;

stdenv.mkDerivation rec {
  name = "mpv-${version}";
  version = "0.9.2";

  src = fetchurl {
    url = "https://github.com/mpv-player/mpv/archive/v${version}.tar.gz";
    sha256 = "0la7pmy75mq92kcrawdiw5idw6a46z7d15mlkgs0axyivdaqy560";
  };

  patchPhase = ''
    patchShebangs ./TOOLS/
  '';

  NIX_LDFLAGS = optionalString x11Support "-lX11 -lXext";

  # Unfortunately features are autodetected in such a way that it will pull in
  # unintended libs, this overrides portions not explicitly enabled.
  configureFlags = [
    # Build/Install options
    "--enable-libmpv-shared"
    "--disable-libmpv-static"
    "--disable-static-build"
    "--enable-manpage-build"
    "--disable-build-date" # Purity
    "--enable-zsh-comp"
    # Optional features
    (disFlag (libiconv == null) "iconv")
    "--disable-waio"
    "--disable-termios"
    "--disable-shm" # ???
    "--disable-libguess"
    "--disable-libsmbclient"
    (disFlag (libass == null) "libass")
    (disFlag (libass == null) "libass-osd")
    "--disable-encoding" # ???
    (disFlag (libbluray == null) "libbluray")
    (disFlag (libdvdread == null) "dvdread")
    (disFlag (libdvdnav == null) "dvdnav")
    (disFlag (libcdio == null) "cdda")
    "--disable-enca"
    "--disable-ladspa"
    "--disable-rubberband"
    (disFlag (libbs2b == null) "libbs2b")
    "--disable-lcms2"
    "--disable-vapoursynth"
    "--disable-vapoursynth-lazy"
    (disFlag (ffmpeg == null) "libswresample")
    (disFlag (ffmpeg == null) "libavresample")
    (disFlag (ffmpeg == null) "libavfilter")
    (disFlag (ffmpeg == null) "libavdevice")
    "--lua=51"
    # Audio outputs
    # Video outputs
    # Hwaccels
    # TV Features
  ] ++ optional vaapiSupport "--enable-vaapi";

  configurePhase = ''
    python ${waf} configure --prefix=$out $configureFlags
  '';

  nativeBuildInputs = [ docutils perl pkgconfig python which ];

  buildInputs = [
    ffmpeg freetype libass libpthreadstubs lua lua5_sockets makeWrapper
    # Optional
    alsaLib jack2 libbluray libbs2b libcaca libdvdnav libdvdnav.libdvdread libdvdread libpng
    libtheora libvdpau pulseaudio SDL2 speex
  ] ++ optionals x11Support [ libX11 libXext mesa libXxf86vm ]
    ++ optional xvSupport libXv
    ++ optional xineramaSupport libXinerama
    ++ optional screenSaverSupport libXScrnSaver
    ++ optional vaapiSupport libva;

  enableParallelBuilding = true;

  buildPhase = ''
    python ${waf} build
  '';

  installPhase = ''
    python ${waf} install

    # Use a standard font
    mkdir -p $out/share/mpv
    ln -s ${freefont_ttf}/share/fonts/truetype/FreeSans.ttf $out/share/mpv/subfont.ttf

    # Ensure youtube-dl is available in $PATH for MPV
    wrapProgram $out/bin/mpv --prefix PATH : "${youtube-dl}/bin/youtube-dl"
  '';

  meta = with stdenv.lib;{
    description = "A media player that supports many video formats (MPlayer and mplayer2 fork)";
    homepage = http://mpv.io;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ AndersonTorres fuuzetsu ];
    platforms = platforms.linux;

    longDescription = ''
      mpv is a free and open-source general-purpose video player,
      based on the MPlayer and mplayer2 projects, with great
      improvements above both.
    '';
  };
}
