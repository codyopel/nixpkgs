{ stdenv, fetchurl, perl, pkgconfig, python3
, docutils, ffmpeg, freefont_ttf, freetype, libass, libpthreadstubs, lua, lua5_sockets, zlib
, x11Support ? true, libX11 ? null, libXext ? null, mesa ? null, libXxf86vm ? null
, xineramaSupport ? true, libXinerama ? null
# For screenshots
# for Youtube support
, alsaLib ? null
, bs2bSupport ? false, libbs2b ? null
, cacaSupport ? false, libcaca ? null
, jack2 ? null
, libbluray ? null
, libdvdnav ? null
, libdvdread ? null
, libpng ? null
, libtheora ? null
, libvdpau ? null
, libXScrnSaver ? null
, libXv ? null
, pulseaudio ? null
, SDL2 ? null
, speex ? null
, vaapiSupport ? false, libva ? null
, youtubeSupport ? false, youtubeDL ? null
}:

assert x11Support -> (libX11 != null && libXext != null && mesa != null && libXxf86vm != null);
assert xineramaSupport -> (libXinerama != null && x11Support);
assert bs2bSupport -> libbs2b != null;
assert youtubeSupport -> youtubeDL != null;
assert cacaSupport -> libcaca != null;

let
  /* Waf needs to be downloaded by bootstrap.py but for purity reasons
     it should be avoided.  This will download and package Waf, mimetizing
     bootstrap.py's behaviour. */

     /*Since b23dbb1, if buildInputs contains
a plain file it is used as a setup hook. The waf script which is used
here in mpv however isn't a setup hook and also shouldn't be included in
buildInputs as it was kind of a no-op before already.

Failed build log:

https://headcounter.org/hydra/build/582548/nixlog/1/raw

Signed-off-by: aszlig <aszlig@redmoonstudios.org>*/
  waf = fetchurl {
    url = "http://ftp.waf.io/pub/release/waf-1.8.5";
    sha256 = "0gh266076pd9fzwkycskyd3kkv2kds9613blpxmn9w4glkiwmmh5";
  };

  inherit (stdenv) isCygwin isDarwin isLinux;
  inherit (stdenv.lib) enableFeature optional optionals optionalString;
in

stdenv.mkDerivation rec {
  name = "mpv-${version}";
  version = "0.8.3";

  src = fetchurl {
    url = "https://github.com/mpv-player/mpv/archive/v${version}.tar.gz";
    sha256 = "1kw9hr957cxqgm2i94bgqc6sskm6bwhm0akzckilhs460b43h409";
  };

  patchPhase = ''
    patchShebangs ./TOOLS/
  '';

  configureFlags = [
    "--enable-manpage-build"
    "--enable-libmpv-shared"
  ] ++ optional vaapiSupport "--enable-vaapi";

  configurePhase = "python3 ${waf} configure --prefix=$out $configureFlags";

  nativeBuildInputs = [ perl pkgconfig python3 ];

  buildInputs = [
    alsaLib
    docutils
    ffmpeg
    freetype
    jack2
    libass
    libbluray
    libbs2b
    libcaca
    libdvdread
    libdvdnav
    libpng
    libpthreadstubs
    libva
    libvdpau
    libtheora
    libXScrnSaver
    libXv
    lua
    lua5_sockets
    pulseaudio
    SDL2
    speex
    youtubeDL
    zlib
  ] ++ optionals x11Support [ libX11 libXext mesa libXxf86vm ]
    ++ optional xineramaSupport libXinerama
    ;

  buildPhase = "python3 ${waf} build";

  NIX_LDFLAGS = optionalString x11Support "-lX11 -lXext";

  enableParallelBuilding = true;

  installPhase = ''
    python3 ${waf} install

    # Maybe not needed, but it doesn't hurt anyway: a standard font
    mkdir -p $out/share/mpv
    ln -s ${freefont_ttf}/share/fonts/truetype/FreeSans.ttf $out/share/mpv/subfont.ttf
  '';

  meta = with stdenv.lib; {
    description = "A movie player that supports many video formats (MPlayer and mplayer2 fork)";
    longDescription = ''
      mpv is a free and open-source general-purpose video player,
      based on the MPlayer and mplayer2 projects, with great
      improvements above both.
    '';
    homepage = http://mpv.io;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ AndersonTorres fuuzetsu ];
    platforms = platforms.linux;
  };
}

# TODO: Wayland support
# TODO: investigate caca support
# TODO: investigate lua5_sockets bug
