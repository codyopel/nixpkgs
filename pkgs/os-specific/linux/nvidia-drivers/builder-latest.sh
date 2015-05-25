. $stdenv/setup

# Fail on any error
set -e

# Using --shrink-rpath removes libXv from RPATH of nvidia-settings
dontPatchELF=1

installNvidiaBin() {

  # Create the executable directory if it doesn't exist
  if [ ! -d "$out/bin" ] ; then
    mkdir -p "$out/bin"
  fi

  # Install the executable
  cp -p "$1" "$out/bin"

  patchelf \
    --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
    --set-rpath "$out/lib:$glPath:$programPath" \
    "$out/bin/$1"

  # Shrink the RPATH for all executables except `nvidia-settings'
  if [ "$1" != "nvidia-settings" ] ; then
    patchelf --shrink-rpath "$out/bin/$1"
  fi

}

installNvidiaHeader() {

  # Create the include directory if it doesn't exist
  if [ ! -d "$out/include/$2" ] ; then
    mkdir -p "$out/include/$2"
  fi

  # Install the header
  cp -p "$1.h" "$out/include/$2"

}

installNvidiaLib() {

  # installNvidiaLib <lib name> <custom so version> <orginal so version> <path to install (rel to $out/lib/)>

  # Create the lib directory if it doesn't exist
  if [ ! -d "$out/lib/$4" ] ; then
    mkdir -p "$out/lib/$4"
  fi

  local soVersion="$3"
  # If the source *.so.<version> isn't set use *.so.$version
  if [ -z "$soVersion" ] ; then
    soVersion=".$version"
  elif [ "$soVersion" == "no-ver" ] ; then
    soVersion=
  else
    soVersion=".$3"
  fi

  local outDir="$4"
  # If $outDir is set then we need to add a trailing `/'
  if [ -z "$outDir" ] ; then
    outDir=
  else
    outDir="$outDir/"
  fi

  # Handle cases where the file being installed is in a subdirectory within the source directory
  local libFile="$(basename $1)"

  # Install the library
  cp -pd "$1.so$soVersion" "$out/lib/$4"

  # Always create a symlink from the library to *.so & *.so.1
  if [ ! -z "$soVersion" ] ; then 
    ln -snf "$out/lib/$outDir$libFile.so$soVersion" "$out/lib/$outDir$libFile.so"
  fi
  ln -snf "$out/lib/$outDir$libFile.so$soVersion" "$out/lib/$outDir$libFile.so.1"

  # If $2 wasn't 1, then create a *.so.$2 symlink
  if [ ! -z "$2" ] ; then # Make sure that we don't set it if we haven't passed a value
    if [ "$2" -ne "1" ] ; then
      ln -snf "$out/lib/$outDir$libFile.so$soVersion" "$out/lib/$outDir$libFile.so.$2"
    fi
  fi

  patchelf --set-rpath "$out/lib:$allLibPath" "$out/lib/$outDir$libFile.so$soVersion"

  patchelf --shrink-rpath "$out/lib/$outDir$libFile.so$soVersion"

}

installNvidiaMan() {

  # Create the manpage directory if it doesn't exist
  if [ ! -d "$out/share/man/man1" ] ; then
    mkdir -p "$out/share/man/man1"
  fi

  # Install the manpage
  cp -p "$1.1.gz" "$out/share/man/man1"

}

unpackFile() {

  # This prints the first 20 lines of the file, the awk's for the line with `skip=' which contains the 
  # line number where the tarball begins, then tails to that line and pipes the tarball to 
  # the required decompression library (gzip/lzma) which interprets the tarball, and finally pipes
  # the output to tar to extract the contents. This is exactly what the cli commands in the `.run'
  # file do, but there is an issue with some versions so it is best to do it manually instead.

  # The line you are looking for `skip=' is within the first 20 lines of the file, make sure
  # that you aren't grepping/awking/sedding the entire 60,000+ line file for 1 line.
  local skip="$(head -n 20 "$src" | awk -F= '/skip=/ { print $2 ; exit ; }')"

  # If the `skip=' value is null, more than likely the hash wasn't updated after bumping the version.
  [ ! -z "$skip" ]

  tail -n +"$skip" "$src" | xz -d | tar xvf -

  export sourceRoot="$(pwd)"

}

buildPhase() {

  if test -n "$buildKernelModules" ; then

    # Create the kernel module
    echo "Building the NVIDIA Linux kernel modules against: $kernel"

    cd "$sourceRoot/kernel"

    kernelVersion="$(ls $kernel/lib/modules)"
    [ ! -z "$kernelVersion" ]
    local sysSrc="$kernel/lib/modules/$kernelVersion/source"
    local sysOut="$kernel/lib/modules/$kernelVersion/build"

    # $src is also used by the nv makefile
    unset src

    make SYSSRC="$sysSrc" SYSOUT="$sysOut" module

    if [ "$system" == "x86_64-linux" ] ; then
      cd "$sourceRoot/kernel/uvm"
      make SYSSRC="$sysSrc" SYSOUT="$sysOut" module
    fi

    cd "$sourceRoot"

  fi

}

installPhase() {

  # Kernel Modules
  if test -n "$buildKernelModules" ; then
    # Install the kernel module
      mkdir -p "$out/lib/modules/$kernelVersion/misc"
      cp -p "kernel/nvidia.ko" "$out/lib/modules/$kernelVersion/misc"
      if [ "$system" == "x86_64-linux" ] ; then
        cp -p "kernel/uvm/nvidia-uvm.ko" "$out/lib/modules/$kernelVersion/misc"
      fi
  fi

  # Userspace
  if test -n "$buildUserspace" ; then
    # GLX libraries
      # OpenGL API entry point
      installNvidiaLib "libGL"
      installNvidiaLib "libnvidia-glcore"
      installNvidiaLib "libEGL"
      installNvidiaLib "libnvidia-eglcore"
      installNvidiaLib "libGLESv1_CM"
      installNvidiaLib "libGLESv2" 2
      installNvidiaLib "libnvidia-glsi"
      # NVIDIA OpenGL-based inband frame readback
      installNvidiaLib "libnvidia-ifr"
      # Thread local storage libraries for NVIDIA OpenGL
      installNvidiaLib "libnvidia-tls"
      installNvidiaLib "tls/libnvidia-tls" 1 "$version" "tls"
      installNvidiaLib "tls_test_dso" 1 "no-ver"

    # VDPAU library
      # Top-level wrapper
      installNvidiaLib "libvdpau"
      # Debug trace library
      installNvidiaLib "libvdpau_trace"
      # NVIDIA VDPAU implementation
      installNvidiaLib "libvdpau_nvidia"

    # Managment & Monitoring library
      installNvidiaLib "libnvidia-ml"

    # CUDA libraries
      installNvidiaLib "libcuda"
      installNvidiaLib "libnvidia-compiler"
      # CUDA video decoder library
      installNvidiaLib "libnvcuvid"

    # OpenCL libraries
      # Vendor independent ICD loader
      installNvidiaLib "libOpenCL" 1 "1.0.0"
      # NVIDIA ICD
      installNvidiaLib "libnvidia-opencl"
      # OpenCL ICD config
      mkdir -p "$out/lib/vendors"
      cp -p "nvidia.icd" "$out/lib/vendors"

    # Linux kernel userspace driver config library
      installNvidiaLib "libnvidia-cfg"

    # Framebuffer capture library
      installNvidiaLib "libnvidia-fbc"

    # NVENC video encoding library
      installNvidiaLib "libnvidia-encode"

    if test -z "$libsOnly" ; then
      # Wrapped software rendering library
        installNvidiaLib "libnvidia-wfb" 1 "$version" "xorg/modules"

      # X.org DDX driver
        installNvidiaLib "nvidia_drv" 1 "no-ver" "xorg/modules/drivers"

      # GLX extension module for X.org
        installNvidiaLib "libglx" 1 "$version" "xorg/modules/extensions"

      # OpenGL headers
        installNvidiaHeader "gl" "GL"
        installNvidiaHeader "glext" "GL"
        installNvidiaHeader "glx" "GL"
        installNvidiaHeader "glxext" "GL"

      # Support Programs
        # System Management Interface
        installNvidiaBin "nvidia-smi"
        installNvidiaBin "nvidia-debugdump"
        installNvidiaBin "nvidia-cuda-mps-control"
        installNvidiaBin "nvidia-cuda-mps-server"
        installNvidiaBin "nvidia-persistenced"
        ###installNvidiaBin "mkprecompiled"
        ###installNvidiaBin "nvidia-bug-report.sh"
        ###installNvidiaBin "nvidia-installer"
        ###installNvidiaBin "nvidia-modprobe"
        ###installNvidiaBin "nvidia-xconfig"
        ###installNvidiaBin "tls_test" (also tls_test.so)

      # NVIDIA application profiles
        mkdir -p "$out/share/doc"
        cp -p "nvidia-application-profiles-${version}-key-documentation" "$out/share/doc"
        cp -p "nvidia-application-profiles-${version}-rc" "$out/share/doc"


      # Man Pages
        installNvidiaMan "nvidia-smi"
        installNvidiaMan "nvidia-cuda-mps-control"
        installNvidiaMan "nvidia-persistenced"
        ###installNvidiaMan "nvidia-installer"
        ###installNvidiaMan "nvidia-modprobe"
        ###installNvidiaMan "nvidia-xconfig"

      if test -n "$nvidiasettingsSupport" ; then
        installNvidiaBin "nvidia-settings"

        # NVIDIA GTK+ 2/3 libraries
          if test -n "$gtk3Support" && [ "$versionMajor" -ge "346" ] ; then
            installNvidiaLib "libnvidia-gtk3"
            patchelf --set-rpath "$out/lib:$glPath:$gtkPath" "$out/lib/libnvidia-gtk3.so.$version"
          else
            installNvidiaLib "libnvidia-gtk2"
            patchelf --set-rpath "$out/lib:$glPath:$gtkPath" "$out/lib/libnvidia-gtk2.so.$version"
          fi

        # NVIDIA Settings icon
          mkdir -p "$out/share/pixmaps"
          cp -p "nvidia-settings.png" "$out/share/pixmaps"

        # NVIDIA Settings .desktop entry
          mkdir -p "$out/share/applications"
          cp -p "nvidia-settings.desktop" "$out/share/applications"
          substituteInPlace "$out/share/applications/nvidia-settings.desktop" \
            --replace '__UTILS_PATH__' "$out/bin" \
            --replace '__PIXMAP_PATH__' "$out/share/pixmaps"

        installNvidiaMan "nvidia-settings"
      fi

      # Simple test
        $out/bin/nvidia-settings --version
    fi
  fi

}

genericBuild

set +e
