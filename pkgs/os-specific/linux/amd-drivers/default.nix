{ stdenv, fetchurl, unzip

 # Whether to build the libraries only (i.e. not the kernel module or
  # driver utils). Used to support 32-bit binaries on 64-bit
  # Linux.
, libsOnly ? false

# Kernelspace
, kernel ? null

# Userspace
, xlibs, which, imake
, mesa # for fgl_glxgears
, libXxf86vm, xf86vidmodeproto # for fglrx_gamma
, xorg, makeWrapper, glibc, patchelf

# Catalyst Control Center (amdcccle)
, qt4
}:

# If you want to use a different Xorg version probably
# DIR_DEPENDING_ON_XORG_VERSION in builder.sh has to be adopted (?)
# make sure libglx.so of ati is used. xorg.xorgserver does provide it as well
# which is a problem because it doesn't contain the xorgserver patch supporting
# the XORG_DRI_DRIVER_PATH env var.
# See http://thread.gmane.org/gmane.linux.distributions.nixos/4145 for a
# workaround (TODO)

# http://wiki.cchtml.com/index.php/Main_Page

# There is one issue left:
# /usr/lib/dri/fglrx_dri.so must point to /run/opengl-driver/lib/fglrx_dri.so

let
  inherit (stdenv.lib)
    optionalString;
in

assert (!libsOnly) -> kernel != null;

stdenv.mkDerivation {
  name = "ati-drivers-15.7" + (optionalString (!libsOnly) "-${kernel.version}");

  src = fetchurl {
    url = "http://www2.ati.com/drivers/linux/amd-driver-installer-15.20.1046-x86.x86_64.zip";
    sha256 = "ffde64203f49d9288eaa25f4d744187b6f4f14a87a444bab6a001d822b327a9d";
    curlOpts = "--referer http://support.amd.com/en-us/download/desktop?os=Linux%20x86_64";
  };

  # glibc only used for setting interpreter
  # mesa & qt4 = catalyst
  inherit libXxf86vm xf86vidmodeproto libsOnly  mesa qt4 glibc;

  builder = ./builder.sh;

  gcc = stdenv.cc.cc;

  # WHAT THE FUCK is this???
  patchPhase = "patch -p1 < ${./kernel-api-fixes.patch}";
  patchPhaseSamples = "patch -p2 < ${./patch-samples.patch}";

  # ??? does patchelf need to be an input
  nativeBuildInputs = [ patchelf unzip ];

  buildInputs = [
    xlibs.libXext
    xlibs.libX11
    xlibs.libXinerama
    xlibs.libXrandr
    which
    imake
    makeWrapper
    
    mesa qt4
  ];

  kernel = if libsOnly then null else kernel.dev;

  LD_LIBRARY_PATH = stdenv.lib.concatStringsSep ":" [
    "${xorg.libXrandr}/lib"
    "${xorg.libXrender}/lib"
    "${xorg.libXext}/lib"
    "${xorg.libX11}/lib"
    "${xorg.libXinerama}/lib"
  ];

  # without this some applications like blender won't start, but they start
  # with nvidia. This causes them to be symlinked to $out/lib so that they
  # appear in /run/opengl-driver/lib which get's added to LD_LIBRARY_PATH
  extraDRIlibs = [ xorg.libXext ];

  meta = with stdenv.lib; {
    description = "ATI drivers";
    homepage = http://support.amd.com/us/gpudownload/Pages/index.aspx;
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [  codyopel jgeerds marcweber offline ];
    platforms = [
      "i686-linux"
      "x86_64-linux"
    ];
  };
}
