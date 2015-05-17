{ stdenv, fetchgit, makeDesktopItem, makeWrapper, ninja, python, python26
, alsaLib, atk, cairo, cups, dbus, glib, expat, fontconfig, freetype #, gconf
, gdk_pixbuf, gtk, libcap, libgnome_keyring3, libgpgerror, nspr, nss, pango
, xlibs, zlib
, pythonPackages, git
}:

/* Maintainer notes:
 *
 * The Atom developers do not understand how to write a build system or
 * python for that matter. Instead of using their broken python scripts
 * call the build utilities manually.
 */

let
  inherit (stdenv) isx86_64;
in

# Currently 32bit arches such as i686 & ARM32 are not supported
# https://github.com/atom/electron/issues/366
assert isx86_64;

stdenv.mkDerivation rec {
  name = "electron-${version}";
  version = "0.26.0";

  src = fetchgit {
    url = "https://github.com/atom/electron.git";
    rev = "827741a9c602bc3b811bf56f61322a50ae9e882f";
    sha256 = "1rzv15wx9lflngsmy6bs5prg150lsw43rfz1df16cjvrgx473mn3";
    fetchSubmodules = true;
  };

  patchPhase = ''
    patchShebangs ./script/
    patchShebangs ./tools/
    #patchShebangs ./vendor/depot_tools/gym_main.py
    echo
    echo
    echo
    echo
    echo
    ls vendor/depot_tools
  '';

  nativeBuildInputs = [
    ninja python python26 pythonPackages.gyp
  ];

  buildInputs = [ git
    alsaLib atk cairo cups dbus glib expat fontconfig freetype
    gdk_pixbuf gtk libcap libgnome_keyring3 libgpgerror nspr nss pango
    xlibs.libXrender xlibs.libX11 xlibs.libXext xlibs.libXdamage xlibs.libXtst
    xlibs.libXcomposite xlibs.libXi xlibs.libXfixes xlibs.libXrandr
    xlibs.libXcursor
    zlib
  ];

  configureFlags = [
    "-Dlibrary=static_library"
  ];

  configurePhase = ''
    gyp -f ninja --depth . atom.gyp -Icommon.gypi $configureFlags
  '';

  buildPhase = ''
    ninja -C out/Release -j$NIX_BUILD_CORES -l$NIX_BUILD_CORES electron
  '';

  meta = with stdenv.lib; {
    description = "Framework for writing desktop applications using JavaScript, HTML and CSS";
    homepage = http://electron.atom.io/;
    license = licenses.mit;
    maintainers = with maintainers; [ codyopel ];
    platforms = [ "x86_64-linux" ];
  };
}
