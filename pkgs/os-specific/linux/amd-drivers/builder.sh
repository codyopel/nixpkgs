# Generic builder for the AMD drivers, supports versions ???+

# What is LIBGL_DRIVERS_PATH used for?
# TODO: gentoo removes some tools because there are xorg sources (?)

. "${stdenv}/setup"

# Fail on any error
set -e

installAmdBin() {

}

installAmdHeader() {

}

installAmdLib() {

  local initial_path

  case "${1}" in
    'a') # arch/...
      if [ "${system}" == 'i686-linux' ] ; then
        initial_path="arch/x86/"
      elif [ "${system}" == 'x86_64-linux' ] ; then
        initial_path='arch/x86_64/'
      fi
      ;;
    'c') # common/...
      initial_path='common/'
      ;;
    'x') # xpic/...
      if [ "${system}" == 'i686-linux' ] ; then
        initial_path='xpic/usr/X11R6/lib/modules/'
      elif [ "${system}" == 'x86_64' ] ; then
        initial_path='xpic_64a/usr/X11R6/lib64/modules/'
      fi
      ;;
    *)
      return 1
      ;;
  esac

  if [ -z "${initial_path}" ] ; then
    return 1
  fi

  cp "${initial_path}/${2}" "${3}"

  # TODO: *.so.* versions

}

installAmdMan() {

}

unpackFile() {

  # This function prints the first 20 lines of the file, then awk's for the line
  # with `skip=' which contains the line number where the tarball begins, then
  # tails to that line and pipes the tarball to the required decompression
  # utility (gzip/lzma), which interprets the tarball, and finally pipes the
  # output to tar to extract the contents. This is exactly what the cli commands
  # in the `.run' file do, but there is an issue with some versions so it is
  # best to do it manually instead.

  local skip
  local extractedFile

  # The line you are looking for `skip=' is within the first 20 lines of the
  # file, make sure that you aren't grepping/awking/sedding the entire 60,000+
  # line file for 1 line (hense the use of `head').
  skip=$(
    head -n 20 "${src}" |
    awk -F= '/SKIP=/ { print $2 ; exit ; }' |
    grep -o '[0-9]*'
  )
  # The file actually starts one line after the skip value
  skip=$((${skip} + 1))

  # If the `skip=' value is null, more than likely the hash wasn't updated after
  # bumping the version.
  [ ! -z "${skip}" ]

  unzip "${src}"

  extractedFile="$(basename ${src})"

  tail -n +"${skip}" "${extractedFile}.run" | gzip -cd | tar xvf -

  sourceRoot="$(pwd)"
  export sourceRoot

}

buildPhase() {

}

amdKernelspace() {

  local kernelBuild
  local kernelSource

  # Handle/Build the kernel module.
  if test -n "${buildKernelspace}"; then

    kernelVersion="$(ls "${kernel}/lib/modules")"
    kernelBuild="${kernel}/lib/modules/$kernelVersion/build" # sysOut
    kernelSource="${kernel}/lib/modules/$kernelVersion/source" # sysSrc

    # note: maybe the .config file should be used to determine this ?
    # current kbuild infrastructure allows using CONFIG_* defines
    # but ati sources don't use them yet..
    # copy paste from make.sh
    setSMP(){

      linuxincludes=$kernelBuild/include

      # copied and stripped. source: make.sh:
      # 3
      # linux/autoconf.h may contain this: #define CONFIG_SMP 1

      # Before 2.6.33 autoconf.h is under linux/.
      # For 2.6.33 and later autoconf.h is under generated/.
      if [ -f $linuxincludes/generated/autoconf.h ]; then
          autoconf_h=$linuxincludes/generated/autoconf.h
      else
          autoconf_h=$linuxincludes/linux/autoconf.h
      fi
      src_file=$autoconf_h

      [ -e $src_file ] || die "$src_file not found"

      if [ `cat $src_file | grep "#undef" | grep "CONFIG_SMP" -c` = 0 ]; then
        SMP=`cat $src_file | grep CONFIG_SMP | cut -d' ' -f3`
        echo "file $src_file says: SMP=$SMP"
      fi

      if [ "$SMP" = 0 ]; then
        echo "assuming default: SMP=$SMP"
      fi

      # act on final result
      if [ ! "$SMP" = 0 ]; then
        smp="-SMP"
        def_smp=-D__SMP__
      fi

    }

    setModVersions(){
      ! grep CONFIG_MODVERSIONS=y $kernelBuild/.config ||
      def_modversions="-DMODVERSIONS"
      # make.sh contains much more code to determine this whether its enabled
    }

    # ==============================================================
    # resolve if we are building for a kernel with a fix for CVE-2010-3081
    # On kernels with the fix, use arch_compat_alloc_user_space instead
    # of compat_alloc_user_space since the latter is GPL-only

    COMPAT_ALLOC_USER_SPACE=arch_compat_alloc_user_space

    for src_file in \
      $kernelBuild/arch/x86/include/asm/compat.h \
      $linuxsources/arch/x86/include/asm/compat.h \
      $kernelBuild/include/asm-x86_64/compat.h \
      $linuxsources/include/asm-x86_64/compat.h \
      $kernelBuild/include/asm/compat.h;
    do
      if [ -e $src_file ];
      then
        break
      fi
    done
    if [ ! -e $src_file ];
      then
      echo "Warning: x86 compat.h not found in kernel headers"
      echo "neither arch/x86/include/asm/compat.h nor include/asm-x86_64/compat.h"
      echo "could be found in $kernelBuild or $linuxsources"
      echo ""
    else
      if [ `cat $src_file | grep -c arch_compat_alloc_user_space` -gt 0 ]
      then
        COMPAT_ALLOC_USER_SPACE=arch_compat_alloc_user_space
      fi
      echo "file $src_file says: COMPAT_ALLOC_USER_SPACE=$COMPAT_ALLOC_USER_SPACE"
    fi

    # make.sh contains some code figuring out whether to use these or not..
    PAGE_ATTR_FIX=0
    setSMP
    setModVersions
    CC=gcc
    MODULE=fglrx
    LIBIP_PREFIX=$TMP/arch/$arch/lib/modules/fglrx/build_mod
    [ -d $LIBIP_PREFIX ]
    GCC_MAJOR="`gcc --version | grep -o -e ") ." | head -1 | cut -d " " -f 2`"

    { # build .ko module
      cd ./common/lib/modules/fglrx/build_mod/2.6.x
      echo .lib${MODULE}_ip.a.GCC${GCC_MAJOR}.cmd
      echo 'This is a dummy file created to suppress this warning: could not find /lib/modules/fglrx/build_mod/2.6.x/.libfglrx_ip.a.GCC4.cmd for /lib/modules/fglrx/build_mod/2.6.x/libfglrx_ip.a.GCC4' > lib${MODULE}_ip.a.GCC${GCC_MAJOR}.cmd

      sed -i -e "s@COMPAT_ALLOC_USER_SPACE@$COMPAT_ALLOC_USER_SPACE@" ../kcl_ioctl.c

      make CC=${CC} \
        LIBIP_PREFIX=$(echo "$LIBIP_PREFIX" | sed -e 's|^\([^/]\)|../\1|') \
        MODFLAGS="-DMODULE -DATI -DFGL -DPAGE_ATTR_FIX=$PAGE_ATTR_FIX -DCOMPAT_ALLOC_USER_SPACE=$COMPAT_ALLOC_USER_SPACE $def_smp $def_modversions" \
        KVER=$kernelVersion \
        KDIR=$kernelBuild \
        PAGE_ATTR_FIX=$PAGE_ATTR_FIX \
        -j4

      cd $TMP
    }

  fi

}

amdUserspace() {

  # The fuck kind of structure is this amd
  #common/etc/ati/*
  #common/etc/security/console.apps/*
  #common/lib/modules/fglrx/*
  #common/lib/modules/fglrx/build_mod/*
  #common/lib/modules/fglrx/build_mod/2.6.x/*
  #common/usr/include/ATI/GL/*
  #common/usr/include/GL/*
  #common/usr/sbin/*
  #common/usr/share/applications/*
  #common/usr/share/ati/amdcccle/*
  #common/usr/share/doc/amdcccle/*
  #common/usr/share/doc/fglrx/***
  #common/usr/share/icons/*
  #common/usr/share/man/man8/*
  #common/usr/src/ati/*
  #common/usr/X11R6/bin/*
  #arch/x86/etc/OpenCL/vendors/*
  #arch/x86/lib/modules/fglrx/build_mod/*
  #arch/x86/usr/bin/*
  #arch/x86/usr/lib/*
  #arch/x86/usr/lib/fglrx/*
  #arch/x86/usr/sbin/*
  #arch/x86/usr/share/ati/lib/*
  #arch/x86/usr/X11R6/bin/*
  #arch/x86/usr/X11R6/lib/*
  #arch/x86/usr/X11R6/lib/fglrx/*
  #arch/x86/usr/X11R6/lib/modules/dri/*
  #arch/x86_64/etc/OpenCL/vendors/*
  #arch/x86_64/lib/modules/fglrx/build_mod/*
  #arch/x86_64/usr/bin/*
  #arch/x86_64/usr/lib/*
  #arch/x86_64/usr/lib/fglrx/*
  #arch/x86_64/usr/sbin/*
  #arch/x86_64/usr/share/ati/lib/*
  #arch/x86_64/usr/X11R6/bin/*
  #arch/x86_64/usr/X11R6/lib/*
  #arch/x86_64/usr/X11R6/lib/fglrx/*
  #arch/x86_64/usr/X11R6/lib/modules/dri/*
  #xpic/usr/X11R6/lib/modules/*
  #xpic/usr/X11R6/lib/modules/drivers/*
  #xpic/usr/X11R6/lib/modules/extensions/fglrx/*
  #xpic/usr/X11R6/lib/modules/linux/*
  #xpic_64a/usr/X11R6/lib64/modules/*
  #xpic_64a/usr/X11R6/lib64/modules/drivers/*
  #xpic_64a/usr/X11R6/lib64/modules/extensions/fglrx/*
  #xpic_64a/usr/X11R6/lib64/modules/linux/*

  installAmdLib "${arch}/usr/X11R6/${arch_lib}/modules/drivers/fglrx_drv.so" 'lib/xorg/modules/drivers'
  installAmdLib "${arch}/usr/X11R6/${arch_lib}/modules/extensions/fglrx/fglrx-libglx.so" 'lib/xorg/modules/drivers'
  installAmdLib "${arch}/usr/X11R6/${arch_lib}/modules/linux/libfglrxdrm.so" 'lib/xorg/modules/linux'
  installAmdLib "${arch}/usr/X11R6/${arch_lib}/modules/amdxmm.so" 'lib/xorg/modules'
  installAmdLib "${arch}/usr/X11R6/${arch_lib}/modules/glesx.so" 'lib/xorg/modules'

  installAmdBin ""

}

installPhase() {

  # Kernelspace
  if test -n "${buildKernelspace}" ; then
    amdKernelspace
  fi

  # Userspace
  if test -n "${buildUserspace}" ; then
    amdUserspace
  fi

}

genericBuild

set +e

################################################################################


eval "$patchPhase"

case "$system" in
  x86_64-linux)
    arch=x86_64
    lib_arch=lib64
    DIR_DEPENDING_ON_XORG_VERSION=xpic_64a
  ;;
  i686-linux)
    arch=x86
    lib_arch=lib
    DIR_DEPENDING_ON_XORG_VERSION=xpic
  ;;
  *) exit 1;;
esac



{ # install

  mkdir -p $out/lib/xorg

  cp -r common/usr/include $out
  cp -r common/usr/sbin $out
  cp -r common/usr/share $out
  cp -r common/usr/X11R6 $out

  # cp -r arch/$arch/lib $out/lib

  # what are those files used for?
  cp -r common/etc $out

  cp -r $DIR_DEPENDING_ON_XORG_VERSION/usr/X11R6/$lib_arch/* $out/lib/xorg

  # install kernel module
  if test -z "$libsOnly"; then
    t=$out/lib/modules/${kernelVersion}/kernel/drivers/misc
    mkdir -p $t

    cp ./common/lib/modules/fglrx/build_mod/2.6.x/fglrx.ko $t
  fi

  # should this be installed at all?
  # its used by the example fglrx_gamma only
  # don't use $out/lib/modules/dri because this will cause the kernel module
  # aggregator code to see both: kernel version and the dri direcotry. It'll
  # fail saying different kernel versions
  cp -r $TMP/arch/$arch/usr/X11R6/$lib_arch/modules/dri $out/lib
  cp -r $TMP/arch/$arch/usr/X11R6/$lib_arch/modules/dri/* $out/lib
  cp -r $TMP/arch/$arch/usr/X11R6/$lib_arch/*.so* $out/lib
  cp -r $TMP/arch/$arch/usr/X11R6/$lib_arch/fglrx/fglrx-libGL.so.1.2 $out/lib/fglrx-libGL.so.1.2

  cp -r $TMP/arch/$arch/usr/$lib_arch/* $out/lib

  # cp -r $TMP/arch/$arch/usr/$lib_arch/* $out/lib
  ln -s libatiuki.so.1.0 $out/lib/libatiuki.so.1
  ln -s fglrx-libGL.so.1.2 $out/lib/libGL.so.1
  ln -s fglrx-libGL.so.1.2 $out/lib/libGL.so

  ln -s libfglrx_gamma.so.1.0 $out/lib/libfglrx_gamma.so.1
  # make xorg use the ati version
  ln -s $out/lib/xorg/modules/extensions/{fglrx/fglrx-libglx.so,libglx.so}

  # Correct some paths that are hardcoded into binary libs.
  if [ "$arch" ==  "x86_64" ]; then
    for lib in \
      lib/xorg/modules/extensions/fglrx/fglrx-libglx.so \
      lib/xorg/modules/glesx.so \
      lib/dri/fglrx_dri.so \
      lib/fglrx_dri.so \
      lib/fglrx-libGL.so.1.2
    do
      oldPaths="/usr/X11R6/lib/modules/dri"
      newPaths="/run/opengl-driver/lib/dri"
      sed -i -e "s|$oldPaths|$newPaths|" $out/$lib
    done
  else
    oldPaths="/usr/X11R6/lib32/modules/dri\x00/usr/lib32/dri"
    newPaths="/run/opengl-driver-32/lib/dri\x00/dev/null/dri"
    sed -i -e "s|$oldPaths|$newPaths|" \
      $out/lib/xorg/modules/extensions/fglrx/fglrx-libglx.so

    for lib in \
      lib/dri/fglrx_dri.so \
      lib/fglrx_dri.so \
      lib/xorg/modules/glesx.so
    do
      oldPaths="/usr/X11R6/lib32/modules/dri/"
      newPaths="/run/opengl-driver-32/lib/dri"
      sed -i -e "s|$oldPaths|$newPaths|" $out/$lib
    done

    oldPaths="/usr/X11R6/lib32/modules/dri\x00"
    newPaths="/run/opengl-driver-32/lib/dri"
    sed -i -e "s|$oldPaths|$newPaths|" $out/lib/fglrx-libGL.so.1.2
  fi

  # libstdc++ and gcc are needed by some libs
  patchelf --set-rpath $gcc/$lib_arch $out/lib/libatiadlxx.so
  patchelf --set-rpath $gcc/$lib_arch $out/lib/xorg/modules/glesx.so
}

if test -z "$libsOnly"; then

{ # build samples
  mkdir -p $out/bin

  mkdir -p samples
  cd samples
  tar xfz ../common/usr/src/ati/fglrx_sample_source.tgz

  eval "$patchPhaseSamples"

  ( # build and install fgl_glxgears
    cd fgl_glxgears; 
    gcc -DGL_ARB_texture_multisample=1 -g \
    -I$mesa/include \
    -I$out/include \
    -L$mesa/lib -lGL -lGLU -lX11 -lm \
    -o $out/bin/fgl_glxgears -Wall  fgl_glxgears.c
  )

  true || ( # build and install

    # doesn't build  undefined reference to `FGLRX_X11SetGamma'
    # wich should be contained in -lfglrx_gamma

    cd programs/fglrx_gamma
    gcc -fPIC -I${libXxf86vm}/include \
	    -I${xf86vidmodeproto}/include \
	    -I$out/X11R6/include \
	    -L$out/lib \
	    -Wall -lm -lfglrx_gamma -lX11 -lXext -o fglrx_xgamma fglrx_xgamma.c 
  )

  { # copy binaries and wrap them:
    BIN=$TMP/arch/$arch/usr/X11R6/bin
    cp $BIN/* $out/bin
    for prog in $BIN/*; do
      patchelf --set-interpreter $(echo $glibc/lib/ld-linux*.so.2) $out/bin/$(basename $prog)
      wrapProgram $out/bin/$(basename $prog) --prefix LD_LIBRARY_PATH : $out/lib:$gcc/lib:$qt4/lib:$LD_LIBRARY_PATH
    done
  }

  rm -fr $out/lib/modules/fglrx # don't think those .a files are needed. They cause failure of the mod

}

fi

for p in $extraDRIlibs; do
  for lib in $p/lib/*.so*; do
    ln -s $lib $out/lib/
  done
done
