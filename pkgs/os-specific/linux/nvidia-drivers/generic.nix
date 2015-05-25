{ stdenv, fetchurl
, configBuild ? "all"

# Kernel dependencies
, kernel ? null
, allowUnsupportedKernels ? false

# Userspace dependencies
, xlibs, zlib
, libsOnly ? false
, nvidiasettingsSupport ? true, atk ? null, gdk_pixbuf ? null, glib ? null, gtk2 ? null, pango ? null
, gtk3Support ? false, gtk3 ? null, cairo ? null

# Inherit generics
, versionMajor, versionMinor
, i686sha256, x8664sha256, arm32sha256
, ...
}:

# Required Kernel Modules:
# MTRR (Memory Type Range Register) support
# Unset: Lock debugging & Lock usage statistics
# ~ZONE_DMA ~SYSVIPC
# x86: ~HIGHMEM

# SHORTLIVED:  349.xx,   xorg <=1.17.x, kernel <=4.0
# LONGLIVED:   346.xx,   xorg <=1.17.x, kernel <=4.0 (LTS) <- default
# LEGACY:      340.xx,   xorg <=1.17.x, kernel <=3.18
# LEGACY:      304.xx,   xorg <=1.16.x, kernel <=3.16
# UNSUPPORTED: 173.14.x, xorg <=1.15.x, kernel <=3.13
# UNSUPPORTED: 96.43.x,  xorg <=1.12.x, kernel <=3.7
# UNSUPPORTED: 71.86.x,  xorg <=?,      kernel <=?

# Long-Lived only recieves changes deemed as stable, it
# may not however recieve new features.

# If your gpu requires a version that is unsupported it is
# recommended to use the nouveau driver.

let
  inherit (stdenv) system isx86_64;
  inherit (stdenv.lib) any makeLibraryPath optionals optionalString versionAtLeast versionOlder;

  buildKernelModules = any (n: n == configBuild) [ "kernelspace" "all" ];
  buildUserspace = any (n: n == configBuild) [ "userspace" "all" ];

  unsupportedKernel = ( # If true the kernel is unsupported
    if versionMajor == "304" && versionOlder kernel.version "3.17" then false
    else if versionMajor == "340" && versionOlder kernel.version "3.19" then false
    else if versionAtLeast versionMajor "346" && versionOlder kernel.version "4.1" then false
    else true
  );
in

assert any (n: n == configBuild) [ "kernelspace" "userspace" "all" ];
assert buildKernelModules -> kernel != null;
assert nvidiasettingsSupport -> atk != null && gdk_pixbuf != null && glib != null && pango != null
                             && (if gtk3Support && versionAtLeast versionMajor "346" then
                                   (cairo != null && gtk3 != null)
                                 else (gtk2 != null));

# ARM32 platforms are only supported by branch 346 and up
assert system == "armv7l-linux" -> versionAtLeast versionMajor "346";

if !allowUnsupportedKernels && unsupportedKernel then
  throw ''
    NixOS only supports kernels supported by NVIDIA

    You can may override this using `allowUnsupportedKernels'
    but you will not recieve support as a result of changing
    this behavior.
  ''
else stdenv.mkDerivation rec {

  name = "nvidia-drivers-${configBuild}-${version}${optionalString buildKernelModules "-${kernel.version}"}";
  version = "${versionMajor}.${versionMinor}";

  src = (
    if system == "armv7l-linux" then
      fetchurl {
        url = "http://us.download.nvidia.com/XFree86/Linux-x86-ARM/${version}/NVIDIA-Linux-armv7l-gnueabihf-${version}.run";
        sha256 = "${arm32sha256}";
      }
    else if system == "i686-linux" then
      fetchurl {
        url = "http://us.download.nvidia.com/XFree86/Linux-x86/${version}/NVIDIA-Linux-x86-${version}.run";
        sha256 = "${i686sha256}";
      }
    else if system == "x86_64-linux" then
      fetchurl {
        url = "http://us.download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}-no-compat32.run";
        sha256 = "${x8664sha256}";
      }
    else throw "The NVIDIA drivers do not support the `${system}' platform"
  );

  # Make sure anything that isn't declared within the derivation
  # is inherited so that it is passed to the builder.
  inherit buildKernelModules buildUserspace kernel libsOnly
          gtk3Support nvidiasettingsSupport versionMajor;

  builder = (
    if versionMajor == "304" then
      ./builder304.sh
    else if versionMajor == "340" then
      ./builder340.sh
    # Latest/Testing (Short-Lived/Beta)
    else if versionAtLeast versionMajor "349" then
      ./builder-latest.sh
    # LTS (Long Lived)
    else
      ./builder.sh
  );

  dontStrip = true;

  glPath = makeLibraryPath [ xlibs.libXext xlibs.libX11 xlibs.libXrandr ];
  programPath = makeLibraryPath [ xlibs.libXv ];
  allLibPath = makeLibraryPath [ stdenv.cc.cc xlibs.libX11 xlibs.libXext xlibs.libXrandr zlib ];
  gtkPath = optionalString (!libsOnly) (
    makeLibraryPath ([
      atk pango glib gdk_pixbuf
    ] ++ (if gtk3Support && versionAtLeast versionMajor "346" then [
      cairo gtk3
    ] else [
      gtk2
    ]))
  );

  passthru = {
    inherit version versionMajor;
    nvenc = (if versionAtLeast versionMajor "340" then true else false);
    cudaUVM = (if versionAtLeast versionMajor "340" && isx86_64 then true else false);
  };

  meta = with stdenv.lib; {
    description = "Drivers and Linux kernel modules for NVIDIA graphics cards";
    homepage = http://www.nvidia.com/object/unix.html;
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [ codyopel vcunat ];
    platforms = [ "armv7l-linux" "i686-linux" "x86_64-linux" ];
  };
}