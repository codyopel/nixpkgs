# TODO: look into glPath & openclPath variables for anything that might use it


source $stdenv/setup

dontPatchELF=1 # must keep libXv, $out in RPATH

verReq() {
  local reqVer="$2"
  case "$1" in
    'eq')
      [ "$versionMajor" -eq "$reqVer" ] && return 0
      ;;
    'ge')
      [ "$versionMajor" -ge "$reqVer" ] && return 0
      ;;
    'le')
      [ "$versionMajor" -le "$reqVer" ] && return 0
      ;;
  esac
  return 1
}

installNvidiaBin() {
  # Create the executable directory if it doesn't exist
  [ -d "$out/bin" ] || {
    mkdir -p "$out/bin" || {
      echo "ERROR: Failed to create directory \`$out/bin'"
      return 1
    }
  }
  # Install the executable
  cp -a "$1" "$out/bin" || {
    echo "ERROR: Failed to install \`$1' to \`$out/bin'" 
    return 1
  }
  patchelf \
    --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
    --set-rpath "$out/lib:$programPath:$glPath" \
    "$out/bin/$1" || {
    echo "ERROR: Failed to patch \`$out/bin/$1'"
    return 1
  }
  return 0
}

installNvidiaHeader() {
  # Create the include directory if it doesn't exist
  [ -d "$out/include/$2" ] || {
    mkdir -p "$out/include/$2" || {
      echo "ERROR: Failed to create directory \`$out/include/$2'"
      return 1
    }
  }
  # Install the header
  cp -a "$1.h" "$out/include/$2" || {
    echo "ERROR: Failed to install \`$1.h' to \`$out/include/$2'"
    return 1
  }
  return 0
}

installNvidiaLib() {
  # Create the lib directory if it doesn't exist
  [ -d "$out/lib/$4" ] || {
    mkdir -p "$out/lib/$4" || {
      echo "ERROR: Failed to create directory \`$out/lib/$4'"
      return 1
    }
  }
  local soVersion="$3"
  # If the source *.so.<version> isn't set use *.so.$versionNumber
  [ -z "$soVersion" ] && [ ] && { soVersion="$versionNumber" ; }
  if [ -z "$soVersion" ] ; then
    soVersion=".$versionNumber"
  elif [ "$soVersion" == "no-ver" ] ; then
    soVersion=
  else
    soVersion=".$3"
  fi
  # This is for cases where the file being installed is in a subdirectory in the source directory
  local libFile="$(basename $1)"
  # Install the library
  cp -a "$1.so$soVersion" "$out/lib/$4$libFile.so$soVersion" || {
    echo "ERROR: Failed to install \`$1.so.$soVersion' to \`$out/lib/$4'"
    return 1
  }
  # Always create a symlink from the library to *.so & *.so.1
  [ -z "$soVersion" ] || {  
    ln -snf "$out/lib/$4$libFile.so$soVersion" "$out/lib/$4$libFile.so" || {
      echo "ERROR: Failed to symlink \`$out/lib/$4$libFile.so$soVersion' to \`$out/$4/$libFile.so'"
      return 1
    }
  }
  ln -snf "$out/lib/$4$libFile.so$soVersion" "$out/lib/$4$libFile.so.1" || {
    echo "ERROR: Failed to symlink \`$out/lib/$4$libFile.so$soVersion' to \`$out/$4/$libFile.so.1'"
    return 1
  }
  # If $2 wasn't 1, then we need to create a *.so.$2 symlink
  [ -z "$2" ] || { # Make sure that we don't set it if we don't pass a value
    [ "$2" -ne "1" ] && {
      ln -snf "$out/lib/$4$libFile.so$soVersion" "$out/lib/$4/$libFile.so.$2" || {
        echo "ERROR: Failed to symlink \`$out/lib/$4$libFile.so$soVersion' to \`$out/$4/$libFile.so.$2'"
        return 1
      }
    }
  }
  return 0
}

installNvidiaMan() {
  # Create the manpage directory if it doesn't exist
  [ -d "$out/share/man/man1" ] || {
    mkdir -p "$out/share/man/man1" || {
      echo "ERROR: Failed to create directory \`$out/share/man/man1'"
      return 1
    }
  }
  # Install the manpage
  cp -a "$1.1.gz" "$out/share/man/man1" || {
    echo "ERROR: Failed to install \`$1' to \`$out/share/man/man1"
    return 1
  }
  return 0
}

unpackFile() {
  # This prints the first 20 lines of the file, the awk's for the line with `skip=' which gets the 
  # line number where the binary tarball begins, then tails to that point and pipes the binary to 
  # the required decompression library (gzip/lzma) to interpret the binary, and finally pipes
  # the output to tar to extract the contents. This is exactly what the cli commands in the `.run'
  # file do, but there is an issue with some versions so it is best to do it manually instead.

  # The line you are looking for `skip=' is within the first ~20 lines of the file, make sure
  # that you aren't grepping/awking/sedding the entire 60,000+ line file for 1 line.

  # If the `skip=' value is null, more than likely the hash wasn't updated after bumping the version.
  # Change a character in the hash an re-reun the build to force nix to rehash the file.
  local checkSkip="$(head -n 20 "$src" | awk -F= '/skip=/ { print $2 ; exit ; }')"
  [ -z "$checkSkip" ] && {
    echo "ERROR: Make sure the sha256 hash has been updated for the version you are trying to build"
    return 1
  }
  # <=304.xx
  if verReq "le" "304" ; then
    tail -n +$(head -n 20 "$src" | awk -F= '/skip=/ { print $2 ; exit ; }') "$src" | gzip -cd | tar xvf - || {
      echo "ERROR: Failed to unpack \`$src'"
      return 1
    }
  # >=340.xx
  else
    tail -n +$(head -n 20 "$src" | awk -F= '/skip=/ { print $2 ; exit ; }') "$src" | xz -d | tar xvf - || {
      echo "ERROR: Failed to unpack \`$src'"
      return 1
    }
  fi
  sourceRoot="$(pwd)"
  return 0
}

buildPhase() {
  test -z "$libsOnly" && {
    # Create the kernel module
    echo "Building the NVIDIA Linux driver against kernel: $kernel"
    cd "$sourceRoot/kernel" || return 1
    local kernelVersion=$(cd $kernel/lib/modules && ls)
    local sysSrc="$kernel/lib/modules/$kernelVersion/source"
    local sysOut="$kernel/lib/modules/$kernelVersion/build"
    # $src is also used by the nv makefile
    unset src || return 1
    make SYSSRC=$sysSrc SYSOUT=$sysOut module || return 1
    verReq "ge" "340" && [ "$system" == "x86_64-linux" ] && {
      cd "$sourceRoot/kernel/uvm/" || return 1
      make SYSSRC=$sysSrc SYSOUT=$sysOut module || return 1
    }
    cd "$sourceRoot" || return 1
  }
  return 0
}

installPhase() {
  # GLX libraries
    installNvidiaLib libGL || return 1
    patchelf --set-rpath $out/lib:$glPath $out/lib/libGL.so.$versionNumber || return 1
    cp -a "libGL.la" "$out/lib" || return 1
  verReq "ge" "304" && {
    installNvidiaLib libnvidia-glcore || return 1
    installNvidiaLib libnvidia-tls || return 1
  }
  verReq "eq" "340" && {
    installNvidiaLib libGLcore || return 1
  }
  verReq "ge" "340" && {
    installNvidiaLib libEGL || return 1
    installNvidiaLib libGLESv1_CM || return 1
    installNvidiaLib libnvidia-eglcore || return 1
    installNvidiaLib libnvidia-glsi || return 1
    installNvidiaLib libnvidia-ifr || return 1
  }

  # VDPAU library
  verReq "ge" "304" && {
    installNvidiaLib libvdpau_nvidia || return 1
    patchelf --set-rpath $out/lib:$glPath $out/lib/libvdpau_nvidia.so.$versionNumber || return 1
  }

  # GLES v2 libraries (.so.2)
  verReq "ge" "340" && {
    installNvidiaLib libGLESv2 2 || return 1
  }
    ### glPath ???

  # Nvidia monitoring library
  verReq "ge" "304" && {
    installNvidiaLib libnvidia-ml || return 1
  }

  # CUDA & OpenCL libraries
    installNvidiaLib libcuda || return 1
    patchelf --set-rpath $cudaPath $out/lib/libcuda.so.$versionNumber || return 1
  verReq "ge" "304" && {
    installNvidiaLib libnvidia-compiler || return 1
    installNvidiaLib libOpenCL 1 1.0.0 || return 1
    installNvidiaLib libnvidia-opencl || return 1
    patchelf --set-rpath $openclPath $out/lib/libnvidia-opencl.so.$versionNumber || return 1
  }

  # Nvidia OpenCL ICD
  verReq "ge" "111" && {
    mkdir -p $out/lib/vendors || return 1
    cp -a nvidia.icd $out/lib/vendors/ || return 1
  }

  # Nvidia kernel userspace driver config library
  installNvidiaLib libnvidia-cfg || return 1

  # Nvidia framebuffer capture library
  verReq "ge" "340" && {
    installNvidiaLib libnvidia-fbc || return 1
  }

  # Nvidia CUDA/NVENC video encode/decode libraries
  verReq "ge" "111" && { # 304?
    installNvidiaLib libnvcuvid || return 1
  }
  verReq "ge" "340" && {
    installNvidiaLib libnvidia-encode || return 1
  }

  # NVIDIA GTK2/3 libraries
  if test -n "$gtk3Support" ; then
    installNvidiaLib libnvidia-gtk3
    patchelf --set-rpath "$glPath:$gtkPath" "$out/lib/libnvidia-gtk3.so.$versionNumber"
  else
    installNvidiaLib libnvidia-gtk2
    patchelf --set-rpath "$glPath:$gtkPath" "$out/lib/libnvidia-gtk2.so.$versionNumber"
  fi


  # ??? tls directory
  #cp -ard tls $out/lib/
  installNvidiaLib libnvidia-tls
  installNvidiaLib libnvidia-tls 1 "$versionNumber" "tls/"

  test -z "$libsOnly" && {
    # Install the kernel module
    mkdir -p "$out/lib/modules/$kernelVersion/misc"
    cp -a "kernel/nvidia.ko" "$out/lib/modules/$kernelVersion/misc"
    verReq "ge" "340" && [ "$system" == "x86_64-linux" ] && {
      cp -a "kernel/uvm/nvidia-uvm.ko" "$out/lib/modules/$kernelVersion/misc"
    }

    # ??? something xorg related ??? Gentoo doesn't touch this file
    installNvidiaLib libnvidia-wfb 1 "$versionNumber" "xorg/modules/"

    # Xorg DDX driver
    installNvidiaLib nvidia_drv 1 "no-ver" "xorg/modules/drivers/"

    # GLX driver
    installNvidiaLib libglx 1 $versionNumber xorg/modules/extensions/
    patchelf --set-rpath $out/lib $out/lib/xorg/modules/extensions/libglx.so.$versionNumber

    # XvMC driver library
    verReq "le" "111" && {
      installNvidiaLib libXvMCNVIDIA 1 $versionNumber lib/xorg/lib
    }

    # CUDA headers
    verReq "le" "111" && {
      installNvidiaHeader cuda cuda || return 1
      installNvidiaHeader cudaGL cuda || return 1
    }

    # OpenGL headers
    installNvidiaHeader gl GL || return 1
    installNvidiaHeader glext GL || return 1
    installNvidiaHeader glx GL || return 1
    installNvidiaHeader glxext GL || return 1

    # Support Programs
    #installNvidiaBin nvidia-bug-report.sh
    #installNvidiaBin nvidia-installer
    installNvidiaBin nvidia-settings
    installNvidiaBin nvidia-smi
    installNvidiaBin nvidia-xconfig
    installNvidiaBin tls_test
    verReq "eq" "304" && {
      installNvidiaBin nvidia-cuda-proxy-control
      installNvidiaBin nvidia-cuda-proxy-server
    }
    verReq "ge" "304" && {
      installNvidiaBin nvidia-debugdump
    }
    verReq "ge" "340" && {
      installNvidiaBin nvidia-cuda-mps-control
      installNvidiaBin nvidia-cuda-mps-server
      #installNvidiaBin nvidia-modprobe
      installNvidiaBin nvidia-persistenced
    }

    # NVIDIA application profiles
    mkdir -p $out/share/nvidia
    cp -a nvidia-application-profiles-${versionNumber}-key-documentation $out/share/nvidia
    cp -a nvidia-application-profiles-${versionNumber}-rc $out/share/nvidia

    # Nvidia Settings icon
    mkdir -p $out/share/icons
    cp -a nvidia-settings.png $out/share/icons

    # Nvidia Settings .desktop file
    mkdir -p $out/share/applications
    cp -a nvidia-settings.desktop $out/share/applications
    substituteInPlace $out/share/applications/nvidia-settings.desktop \
      --replace '__UTILS_PATH__' $out/bin \
      --replace '__PIXMAP_PATH__' $out/share/icons \
      --replace 'Application;' ""

    # Man Pages
    mkdir -p $out/share/man/man1
    #installNvidiaMan nvidia-installer
    installNvidiaMan nvidia-settings
    installNvidiaMan nvidia-smi
    #installNvidiaMan nvidia-xconfig
    verReq "eq" "304" && {
      installNvidiaMan nvidia-cuda-proxy-control
    }
    #if [ "$versionMajor" -ge "304" ]; then
    #fi
    verReq "ge" "340" && {
      installNvidiaMan nvidia-cuda-mps-control
      #installNvidiaMan nvidia-modprobe
      installNvidiaMan nvidia-persistenced
    }

    # Simple test
    #cd "$out/bin"
    #ls
    #bash nvidia-settings --version || return 1
  }
  return 0
}

genericBuild
