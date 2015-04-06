{ stdenv, fetchFromGitHub, pkgconfig, autoreconfHook
, pcre, libxml2, sqlite, libev, libuuid, libiconv
# Optional dependencies
, taglib ? null
, ffmpegthumbnailer ? null
, imagemagick ? null
, exiv2 ? null
, curl ? null
, ffmpeg ? null
, mp4v2 ? null
, lame ? null
, twolame ? null
, libvorbis ? null
, libmpcdec ? null
, flac ? null
, libmad ? null
, faad2 ? null
, libopus ? null
, inotify ? null # Linux only
, dbus
}:

let
  inherit (stdenv) isCygwin isLinux;
  inherit (stdenv.lib) optional optionals enableFeature;
in

stdenv.mkDerivation rec {
  name = "fuppes-${version}";
  version = "2014-1-22";

  src = fetchFromGitHub {
    owner  = "u-voelkel";
    repo   = "fuppes";
    rev    = "1c9b4cc78e2dd3f424face74d06ac3918ea38180";
    sha256 = "0lv8xl0dkm8ych8rvxqsadrwr6mpimm2rpc8ai9kdnwfdbmzz9r6";
  };

  # FFmpeg is explictly disable in the configure script, this will re-enable
  # it, but it will fail with a symbol lookup error
  #patchPhase = optional (ffmpeg != null) ''
  #  sed -e 's,have_libavformat=no,have_libavformat=yes,' -i configure.ac
  #'';

  nativeBuildInputs = [ pkgconfig  autoreconfHook ];

  buildInputs = [
    pcre libxml2 sqlite libev libuuid libiconv

    taglib ffmpegthumbnailer imagemagick exiv2 curl ffmpeg mp4v2 lame twolame
    libvorbis libmpcdec flac libmad faad2 libopus dbus
  ] ++ optionals isLinux [
    inotify
  ];

  configureFlags = [
    (enableFeature isCygwin "windows-service")
    (enableFeature (taglib != null) "taglib")
    (enableFeature (ffmpegthumbnailer != null) "ffmpegthumbnailer")
    (enableFeature (imagemagick != null) "magickwand")
    (enableFeature (exiv2 != null) "exiv2")
    (enableFeature (ffmpeg != null) "libavformat")
    (enableFeature (mp4v2 != null) "mp4v2")
    (enableFeature (lame != null) "lame")
    (enableFeature (twolame != null) "twolame")
    (enableFeature (libvorbis != null) "vorbis")
    "--disable-tremor"
    (enableFeature (libmpcdec != null) "musepack")
    (enableFeature (flac != null) "flac")
    (enableFeature (libmad != null) "mad")
    (enableFeature (faad2 != null) "faad")
    (enableFeature (libopus != null) "opus")
  ];

  # Old fix, not sure if this is needed
  #postFixup = ''
  #  patchelf --set-rpath "$(patchelf --print-rpath $out/bin/fuppes):${faad2}/lib" $out/bin/fuppes
  #  patchelf --set-rpath "$(patchelf --print-rpath $out/bin/fuppesd):${faad2}/lib" $out/bin/fuppesd
  #'';

  meta = with stdenv.lib; {
    description = "UPnP A/V Media Server";
    homepage = http://fuppes.ulrich-voelkel.de/;
    longDescription = ''
      FUPPES is a free, multiplatform UPnP A/V Media Server. It supports
      a wide range of UPnP MediaRenderers as well as on-the-fly transcoding
      of various audio, video and image formats. FUPPES also includes basic
      DLNA support.
    '';
    license = licenses.gpl2;
    maintainers = with maintainers; [ codyopel ];
    platforms = platforms.cygwin ++ platforms.linux;
  };
}
