{ stdenv, fetchgit, ninja, pkgconfig, python
, alsaLib, atk, dbus, glib, gtk2, libnotify
, pango, freetype, fontconfig, gdk_pixbuf , cairo, cups, expat, nspr, gconf, nss
, xlibs, libcap, unzip, pythonPackages
}:

let
  inherit (stdenv) isArm isi686 isx86_64 system;
  arch = (
    if isi686 then "ia32"
    else if isx86_64 then "x64"
    else if isArm then "arm"
    #else if isArm64 then "arm64"
    #else if isMips then "mipsel" # isMips currently mixes both 32 & 64bit mips
    #else if isMips64 then "mips64el"
    #else if isPPC64 then "ppc64" # Nix does not support PPC
    else throw "Thrust does not support the `${system}' platform"
  );
in

stdenv.mkDerivation rec {
  name = "thrust-${version}";
  version = "0.7.6";

  src = fetchgit {
    url = "https://github.com/breach/thrust.git";
    rev = "7c17e16437ad9beea99f4cd68831eba9274a4606";
    sha256 = "1754l6rnckbshqx9zkh69w4ff8dn3skv8kii43fzzliz5xdsvska";
    fetchSubmodules = true;
  };

  patchPhase = ''
    sed -e '/download\//d' -i ./vendor/brightray/brightray.gypi
  '';

  configurePhase = ''
  #ls vendor/brightray/vendor/
  #return 1
    ${pythonPackages.gyp}/bin/gyp \
      -f ninja \
      --depth . \
      thrust_shell.gyp \
      -Icommon.gypi \
      -Ivendor/brightray/brightray.gypi \
      -Dtarget_arch=${arch}
  '';

  nativeBuildInputs = [ ninja pkgconfig python ];

  buildInputs = [
    alsaLib atk dbus glib gtk2 libnotify
    pango freetype fontconfig gdk_pixbuf
    cairo cups expat alsaLib nspr gconf nss xlibs.libXrender xlibs.libX11
    xlibs.libXext xlibs.libXdamage xlibs.libXtst xlibs.libXcomposite
    xlibs.libXi xlibs.libXfixes xlibs.libXrandr xlibs.libXcursor libcap
  ];

  buildPhase = ''
    ${ninja}/bin/ninja -C out/Release -j$NIX_BUILD_CORES -l$NIX_BUILD_CORES thrust_shell
  '';

  meta = with stdenv.lib; {
    description = "Chromium-based cross-platform / cross-language application framework";
    homepage = https://github.com/breach/thrust;
    license = licenses.mit;
    maintainers = with maintainers; [ osener ];
    platforms = platforms.all;
  };
}