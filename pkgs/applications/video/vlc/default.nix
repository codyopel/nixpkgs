{ stdenv, fetchurl, perl, pkgconfig
, a52dec, alsaLib, avahi, bzip2, dbus, faad2, ffmpeg, flac, freefont_ttf
, fribidi, gnutls, jack2, libass, libbluray, libcaca, libcddb, libdc1394
, libdvbpsi, libdvdnav, libebml, libgcrypt, libkate, libmad, libmatroska
, libmodplug, libmtp, liboggz, libopus, libvpx, libraw1394, librsvg, libtheora
, libtiger, libupnp, libv4l, libva, libvdpau, libvorbis, libxml2, lua5
, mpeg2dec, pulseaudio, samba, schroedinger, SDL, SDL_image, speex, taglib
, udev, unzip, xlibs, xz, zlib
, withQt5 ? false, qt4 ? null, qt5 ? null
, onlyLibVLC ? false
}:

let
  inherit (stdenv.lib) enableFeature;
in

assert withQt5 -> qt5 != null;
assert !withQt5 -> qt4 != null;

stdenv.mkDerivation rec {
  name = "vlc-${version}";
  version = "2.2.1";

  src = fetchurl {
    url = "http://download.videolan.org/vlc/${version}/${name}.tar.xz";
    sha256 = "1jqzrzrpw6932lbkf863xk8cfmn4z2ngbxz7w8ggmh4f6xz9sgal";
  };

  patchPhase = ''
    patchShebangs ./configure
    substituteInPlace modules/text_renderer/freetype.c --replace \
      /usr/share/fonts/truetype/freefont/FreeSerifBold.ttf \
      ${freefont_ttf}/share/fonts/truetype/FreeSerifBold.ttf
  '';

  nativeBuildInputs = [ perl pkgconfig ];

  buildInputs = [
    a52dec alsaLib avahi bzip2 dbus faad2 ffmpeg flac freefont_ttf fribidi
    gnutls jack2 libass libbluray libcaca libcddb libdc1394 libdvbpsi libdvdnav
    libdvdnav.libdvdread libebml libgcrypt libkate libmad libmatroska libmodplug
    libmtp liboggz libopus libraw1394 librsvg libtheora libtiger libupnp libv4l
    libva libvdpau libvorbis libvpx libxml2 lua5 mpeg2dec pulseaudio samba
    schroedinger SDL SDL_image speex taglib udev unzip xlibs.libXpm
    xlibs.xcbutilkeysyms xlibs.libXv xlibs.libXvMC xlibs.xlibs xz zlib
  ] ++ (if withQt5 then [ qt5.base ] else [ qt4 ]);

  configureFlags = [
    "--enable-a52"
    #"--enable-aa"
    "--enable-addonmanagermodules"
    "--enable-alsa"
    #"--enable-aribsub"
    "--enable-avcodec"
    "--enable-avformat"
    #"--enable-bpg"
    #"--enable-crystalhd" Requires broadcom crystalhd
    "--enable-dbus"
    "--enable-dc1394"
    #"--enable-decklink" Requires blackmagic-design-video
    "--enable-dvdnav"
    #"--enable-faad"
    #"--enable-directfb"
    "--enable-fontconfig"
    "--enable-freetype"
    "--enable-fribidi"
    #"--enable-gme" game music emulator
    "--enable-gnutls"
    #"--enable-growl"
    "--enable-gst-decode"
    "--enable-harfbuzz"
    "--enable-httpd"
    "--enable-jack"
    "--enable-jpeg"
    "--enable-libass"
    "--enable-libcddb"
    "--enable-libgcrypt"
    "--enable-libtar"
    "--enable-libva"
    #"--enable-libx262"
    #"--enable-linsys" Linux Linear Systems Ltd. SDI and HD-SDI input cards
    #"--enable-lirc"
    #"--enable-live555" Requires live555
    "--enable-lua"
    "--enable-mad"
    "--enable-merge-ffmpeg"
    "--enable-mkv"
    "--enable-mod"
    "--enable-mpc"
    "--enable-ncurses"
    #"--enable-omxil"
    #"--enable-omxil-vout"
    "--disable-oss" # OSS not supported by Nix
    "--enable-postproc"
    "--enable-png"
    #"--enable-projectm"
    "--enable-pulse"
    (enableFeature (!onlyLibVLC) "qt")
    #"--enable-quicktime"
    #"--enable-realrtsp"
    #"--enable-screen" ???
    "--enable-sdl"
    "--enable-skins2"
    "--enable-sout"
    "--enable-swscale"
    "--enable-taglib"
    "--enable-telx"
    #"--enable-tiger"
    #"--enable-tremor"
    "--disable-update-check"
    "--enable-vdpau"
    "--enable-v4l2"
    "--enable-vcd"
    (enableFeature (!onlyLibVLC) "vlc")
    "--enable-vlm"
    "--enable-vpx"
    #"--enable-wayland"
    #"--enable-wma-fixed"
    #"--enable-x264"
    #"--enable-x26410b"
    "--enable-xcb"
    "--enable-xvideo"
    "--enable-zvbi"
    "--with-kde-solid=$out/share/apps/solid/actions"
  ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Cross-platform media player and streaming server";
    homepage = http://www.videolan.org/vlc/;
    platforms = platforms.linux;
    license = licenses.lgpl21Plus;
  };
}
