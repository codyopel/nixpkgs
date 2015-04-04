{ stdenv, fetchurl, cmake
, alsaLib
, ffmpeg
, jack2
, portaudio
, pulseaudio
, qt4
libsndio
fluidsynth
}:
ffmepg (ffmpeg?)
sdl2

fluidsynth

alsa
oss
solaris
sndio
qsa
dsound
mmdevapi
winmm
portaudio
pulseaudio
coreaudio
opensl
wave

let
  inherit (stdenv) isLinux;
  inherit (stdenv.lib) optional;
in

stdenv.mkDerivation rec {
  name = "openal-${version}";
  version = "1.16.0";

  src = fetchurl {
    url = "http://kcat.strangesoft.net/openal-releases/openal-soft-${version}.tar.bz2";
    sha256 = "1nbqvg08hy5p2cxy2i2mmh2szmbpsg2dcvhr61iplyisw04rwc8i";
    name = "openal-soft-${version}.tar.bz2";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ ] ++ optional isLinux alsaLib;

  meta = {
    description = "Cross-platform 3D audio API";
    homepage = http://www.openal.org/;
    longDescription = ''
      OpenAL is a cross-platform 3D audio API appropriate for use with
      gaming applications and many other types of audio applications.

      The library models a collection of audio sources moving in a 3D
      space that are heard by a single listener somewhere in that
      space.  The basic OpenAL objects are a Listener, a Source, and a
      Buffer.  There can be a large number of Buffers, which contain
      audio data.  Each buffer can be attached to one or more Sources,
      which represent points in 3D space which are emitting audio.
      There is always one Listener object (per audio context), which
      represents the position where the sources are heard -- rendering
      is done from the perspective of the Listener.
    '';
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ codyopel ];
    platforms = platforms.all;
  };
}
