{ stdenv, fetchurl, python, pythonPackages, srcOnly }:

let
  inherit (stdenv) isArm isi686 isx86_64 system;
  arch = (
    if isi686 then "ia32"
    else if isx86_64 then "x64"
    else throw "Thrust does not support the `${system}' platform"
  );

  chromium_src = srcOnly rec {
    name = "chromium-src-${version}";
    version = "42.0.2311.107";

    src = fetchurl {
      url = "http://commondatastorage.googleapis.com/chromium-browser-official/chromium-${version}.tar.xz";
      sha256 = "05b41v7n0cr0w2fyym45gixp6md5dxrf4icpklldidjac85zga78";
    };
  };
in

stdenv.mkDerivation rec {
  name = "libchromiumcontent-${version}";
  version = "42.0.2311.107-atom-2";

  src = fetchurl {
    url = "https://github.com/atom/libchromiumcontent/archive/v${version}.tar.gz";
    sha256 = "0iqvysbhs7sfqm66sjwds0s1ccx3qb3aypnfxlbvhhn1incchm2g";
  };

  patchPhase = ''
    ls ${chromium_src}
    return 1
  '';

  configurePhase = ''
    ${pythonPackages.gyp}/bin/gyp \
      -f ninja \
      --depth . \
      chromiumcontent/chromiumcontent.gyp \
      -Ichromiumcontent/chromiumcontent.gypi \
      -Dtarget_arch=${arch} \
      -Dhost_arch=${arch} \
      -DDEPTH=${chromium_src}
  '';

  nativeBuildInputs = [ python ];
  buildInput = [ chromium_src ];

  meta = with stdenv.lib; {
    description = "Shared library build of Chromium’s content module";
    homepage = https://github.com/atom/libchromiumcontent;
    # The software is MIT licensed, but it build unfree portions of chromium
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [ codyopel ];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };
}