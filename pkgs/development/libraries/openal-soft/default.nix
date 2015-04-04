{ stdenv, fetchurl, cmake
, alsaSupport ? true, alsaLib ? null
, coreaudioSupport ? false
, directsoundSupport ? false
, jackaudioSupport ? true, jack2 ? null
, mmdevapiSupport ? false
#, ossSupport ? false
, portaudioSupport ? true, portaudio ? null
, pulseaudioSupport ? true, pulseaudio ? null
, qsaSupport ? false
, sndioSupport ? true, libsndio ? null
, solarisSupport ? false
, wavewriterSupport ? false
, winmultimediaSupport ? false
, hrtfSupport ? true
, configUtilSupport ? true, qt4 ? null
, installConfigSupport ? false
, utilsSupport ? false
, examplesSupport ? true, ffmpeg ? null, SDL2 ? null
}:

let
  inherit (stdenv) isCygwin isDarwin isLinux isSunOS;
  inherit (stdenv.lib) optional optionals;

  mkFlag = enable: flag: "-DALSOFT_${flag}=${if enable then "ON" else "OFF"}";
in

stdenv.mkDerivation rec {
  name = "openal-soft-${version}";
  version = "1.16.0";

  src = fetchurl {
    url = "http://kcat.strangesoft.net/openal-releases/${name}.tar.bz2";
    sha256 = "1nbqvg08hy5p2cxy2i2mmh2szmbpsg2dcvhr61iplyisw04rwc8i";
  };

  cmakeFlags = [
    #(mkFlag fluidSynthMidiSupport "REQUIRE_FLUIDSYNTH")
    (mkFlag (alsaSupport && isLinux) "REQUIRE_ALSA")
    (mkFlag (coreaudioSupport && isDarwin) "REQUIRE_COREAUDIO")
    (mkFlag (directsoundSupport && isCygwin) "REQUIRE_DSOUND")
    (mkFlag jackaudioSupport "REQUIRE_JACK")
    (mkFlag (mmdevapiSupport && isCygwin) "REQUIRE_MMDEVAPI")
    #(mkFlag ossSupport "REQUIRE_OSS")
    "-DALSOFT_BACKEND_OSS=OFF"
    "-DALSOFT_REQUIRE_OSS=OFF"
    (mkFlag portaudioSupport "REQUIRE_PORTAUDIO")
    (mkFlag pulseaudioSupport "REQUIRE_PULSEAUDIO")
    (mkFlag (alsaLib != null) "REQUIRE_QSA")
    (mkFlag sndioSupport "REQUIRE_SNDIO")
    (mkFlag (solarisSupport && isSunOS) "REQUIRE_SOLARIS")
    (mkFlag wavewriterSupport "REQUIRE_WAVE")
    (mkFlag (winmultimediaSupport && isCygwin) "REQUIRE_WINMM")
    (mkFlag hrtfSupport "HRTF_DEFS")
    (mkFlag configUtilSupport "NO_CONFIG_UTIL")
    (mkFlag installConfigSupport "CONFIG")
    (mkFlag utilsSupport "UTILS")
    (mkFlag examplesSupport "EXAMPLES")
  ];

  nativeBuildInputs = [ cmake ];

  buildInputs = [ ]
    ++ optional (alsaSupport && isLinux) alsaLib
    ++ optional jackaudioSupport jack2
    #++ optional ossSupport oss
    ++ optional portaudioSupport portaudio
    ++ optional pulseaudioSupport pulseaudio
    ++ optional sndioSupport libsndio
    ++ optional configUtilSupport qt4
    ++ optionals examplesSupport [ ffmpeg SDL2 ];

  meta = with stdenv.lib; {
    description = "OpenAL Soft is an LGPL implementation of the OpenAL 3D audio API";
    homepage = http://kcat.strangesoft.net/openal.html;
    longDescription = ''
      OpenAL Soft is an LGPL-licensed, cross-platform, software implementation
      of the OpenAL 3D audio API. It's forked from the open-sourced Windows
      version available originally from openal.org's SVN repository (now defunct).
      OpenAL provides capabilities for playing audio in a virtual 3D environment.
      Distance attenuation, doppler shift, and directional sound emitters are
      among the features handled by the API. More advanced effects, including
      air absorption, occlusion, and environmental reverb, are available through
      the EFX extension. It also facilitates streaming audio, multi-channel
      buffers, and audio capture.
    '';
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [ codyopel ];
    platforms = platforms.all;
  };
}
