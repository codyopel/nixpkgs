{ stdenv, fetchurl

, makeDesktopItem, makeWrapper, ninja, perl, pkgconfig, python, pythonPackages, which, yasm

, newScope

# default dependencies
, alsaLib, bison, bzip2, dbus_glib, expat, flac, glib, gperf, icu, libcap, libevent, libexif, libjpeg, libopus, libpng
, libusb1, libxml2, libxslt, libwebp, minizip, nspr, pciutils, snappy, speex, udev, xdg_utils

# jsoncpp re2 fontconfig freetype harfbuzz icu libvpx zlib perl JSON flex

# Python
# beautifulsoup jinja ply simplejson

# X.org
# cairo gdk-pixbuf gtk2 libx11 libxcomposite libxcursor libxdamage libxext
# libxfixes libxi libxinerama libxrandr libxrender libxscrnsaver libxtst pango
, libXcursor, libXdamage, libXtst, libXScrnSaver

# OpenGL
, mesa


, kerberos
, utillinux

, gtk2
, protobuf, speechd

# optional dependencies
, libgcrypt ? null # gnomeSupport || cupsSupport

# package customization
, channel ? "stable"
, enableSELinux ? false, libselinux ? null
, enableNaCl ? false
, useOpenSSL ? false, nss ? null, openssl ? null
, gnomeSupport ? false, gnome ? null
, gnomeKeyringSupport ? false, libgnome_keyring3 ? null
, chromeBinaryPlugins ? false, chrome-binary-plugins ? null
, proprietaryCodecs ? false
, cupsSupport ? true, cups ? null
, pulseSupport ? false, pulseaudio ? null
, hiDPISupport ? false
# Deprecated
, enableWideVine ? false
, enablePepperFlash ? false
}:

/* Maintainer notes:
 *
 * Need at least 3GB of memory and 5GB of disk space to build chromium
 */

assert (channel == "stable" || channel == "beta" || channel == "dev");
assert enableSELinux -> libselinux != null;
assert useOpenSSL -> openssl != null;
assert !useOpenSSL -> nss != null;
assert gnomeSupport -> gnome != null;
assert gnomeKeyringSupport -> libgnome_keyring3 != null;
assert pulseSupport -> pulseaudio != null;
# Deprecatation warnings
assert enableWideVine -> throw "`enableWideVine' is deprecated, use `chromeBinaryPlugins' instead";
assert enablePepperFlash -> throw "`enablePepperFlash' is deprecated, use `chromeBinaryPlugins' instead";

let
  inherit (stdenv.lib)
    attrValues concatStrings concatStringsSep mapAttrs mapAttrsToList
    optional optionalAttrs optionals optionalString versionAtLeast versionOlder;

  callPackage = newScope;

  source = builtins.getAttr channel (import ./source/sources.nix);

  sandbox = callPackage ./sandbox.nix { };

  plugins = callPackage ./plugins.nix {
    inherit enablePepperFlash enableWideVine;
  };

  mkGypFlags = (
    let sanitize = v: if v == true then "1"
                      else if v == false then "0"
                      else "${v}";
        toFlag = flag: optSet: "-D${flag}=${sanitize optSet}";
    in attrs: concatStringsSep " " (attrValues (mapAttrs toFlag attrs))
  );

  # build paths and release info
  packageName = "chromium";
  buildPath = "out/Release";
  buildTargets = [ "mksnapshot" "chrome" ];
  libExecPath = "$out/libexec/${packageName}";

  # TODO: Move override to all-packages
  opusWithCustomModes = libopus.override {
    withCustomModes = true;
  };

  transform = flags: concatStringsSep ";" (map (subst: subst + flags) [
    "s,^[^/]+(.*)$,$main\\1,"
    "s,$main/(build|tools)(/.*)?$,$out/\\1\\2,"
    "s,$main/third_party(/.*)?$,$bundled\\1,"
    "s,$main/sandbox(/.*)?$,$sandbox\\1,"
    "s,^/,,"
  ]);
in

stdenv.mkDerivation rec {
  name = "chromium${if channel != "stable" then "-${channel}" else ""}-${version}";
  version = source.version;

  src = fetchurl {
    url = "https://commondatastorage.googleapis.com/chromium-browser-official/chromium-${source.version}.tar.xz";
    inherit (source) sha256;
  };

  preHook = "unset NIX_ENFORCE_PURITY";

  #buildCommand = let
  #  browserBinary = "${out}/libexec/chromium/chromium";
  #  sandboxBinary = "${sandbox}/bin/chromium-sandbox";
  #  mkEnvVar = key: val: "--set '${key}' '${val}'";
  #  envVars = plugins.settings.envVars or {};
  #  isVer42 = !stdenv.lib.versionOlder version "42.0.0.0";
  #  flags = plugins.settings.flags or [];
  #  setBinPath = "--set CHROMIUM_SANDBOX_BINARY_PATH \"${sandboxBinary}\"";
  #in ''
  #  mkdir -p "$out/bin" "$out/share/applications"

  #  makeWrapper "${browserBinary}" "$out/bin/chromium" \
  #    ${optionalString (!isVer42) setBinPath} \
  #    ${concatStrings (mapAttrsToList mkEnvVar envVars)} \
  #    --add-flags "${concatStringsSep " " flags}"

  #  ln -s "$out/bin/chromium" "$out/bin/chromium-browser"
  #  cp -v "${desktopItem}/share/applications/"* "$out/share/applications"
  #'';

  #unpackPhase = ''
  #  tar xf "$src" -C / \
  #    --transform="${transform "xS"}" \
  #    --anchored \
  #    --no-wildcards-match-slash \
  #    --exclude='*/tools/gyp' \
  #    --exclude='*/.*'
  #'';

  patches = if (versionOlder source.version "42.0.0.0") then [
    ./source/sandbox_userns_36.patch ./source/nix_plugin_paths.patch
  ] else [
    ./source/nix_plugin_paths_42.patch
  ];

  # XXX: Wait for https://crbug.com/239107 and https://crbug.com/239181 to
  #      be fixed, then try again to unbundle everything into separate
  #      derivations.
  prePatch = ''
    #cp -dsr --no-preserve=mode "''${source.main}"/* .
    #cp -dsr --no-preserve=mode "''${source.sandbox}" sandbox
    #cp -dr "''${source.bundled}" third_party
    chmod -R u+w third_party

    ls

    # Make sure `--depth' can be passed to gyp, gyp_chromium is not passing
    # the input of `--depth' to gyp thus resulting in: https://crbug.com/462153
    sed -e 's/--depth\',/--depth\', env_name=\'GYP_DEPTH_CAUSE_FUCK_YOU_THATS_WHY\',/' -i pylib/gyp/__init__.py

    # Patch shebangs
    patchShebangs .
  '';

  postPatch = ''
    sed -i -e '/module_path *=.*libexif.so/ {
      s|= [^;]*|= base::FilePath().AppendASCII("${libexif}/lib/libexif.so")|
    }' chrome/utility/media_galleries/image_metadata_extractor.cc

    sed -i -e '/lib_loader.*Load/s!"\(libudev\.so\)!"${udev}/lib/\1!' \
      device/udev_linux/udev?_loader.cc

    sed -i -e '/libpci_loader.*Load/s!"\(libpci\.so\)!"${pciutils}/lib/\1!' \
      gpu/config/gpu_info_collector_linux.cc

    sed -i -r \
      -e 's/-f(stack-protector)(-all)?/-fno-\1/' \
      -e 's|/bin/echo|echo|' \
      -e "/python_arch/s/: *'[^']*'/: '""'/" \
      "./build/common.gypi" "./chrome/chrome_tests.gypi"
  '' + optionalString useOpenSSL ''
    cat ${openssl.patches} | patch -p1 -d "$bundled/openssl/openssl"
  '' + optionalString (versionOlder version "42.0.0.0") ''
    sed -i -e '/base::FilePath exe_dir/,/^ *} *$/c \
      sandbox_binary = base::FilePath(getenv("CHROMIUM_SANDBOX_BINARY_PATH"));
    ' sandbox/linux/suid/client/setuid_sandbox_client.cc
  '' + optionalString (versionAtLeast version "42.0.0.0") ''
    sed -i -e '/LOG.*no_suid_error/d' \
      "$main/content/browser/browser_main_loop.cc"
  '';


  configureFlags =  [(
    mkGypFlags ({
      # Use dynamic linking
      #component = "shared_library";

      # Use system libs
      use_system_bzip2 = true;
      use_system_flac = true;
      use_system_harfbuzz = false;
      use_system_icu = false; # Doesn't support ICU 52 yet.
      use_system_libevent = true;
      use_system_libexpat = true;
      use_system_libexif = true;
      use_system_libjpeg = true;
      use_system_libpng = true;
      use_system_libusb = false; # http://crbug.com/266149
      use_system_libwebp = true;
      use_system_libxml = true;
      use_system_opus = true;
      use_system_skia = false;
      use_system_snappy = true;
      use_system_speex = true;
      use_system_sqlite = false; # http://crbug.com/22208
      use_system_ssl = useOpenSSL;
      use_system_stlport = true;
      use_system_v8 = false;
      use_system_xdg_utils = true;
      use_system_yasm = true;
      use_system_zlib = false;
      use_system_protobuf = false; # needs newer protobuf
      linux_use_bundled_binutils = false;
      linux_use_bundled_gold = false;
      linux_use_gold_binary = false;
      linux_use_gold_flags = false;

      use_gnome_keyring = gnomeKeyringSupport;
      use_gconf = gnomeSupport;
      use_gio = gnomeSupport;
      use_pulseaudio = pulseSupport;
      linux_link_pulseaudio = pulseSupport;
      disable_nacl = (!enableNaCl);
      use_openssl = useOpenSSL;
      selinux = enableSELinux;
      use_cups = cupsSupport;
      enable_hidpi = hiDPISupport;
      # enable support for the AAC & AVC codecs
      proprietary_codecs = proprietaryCodecs;
      ffmpeg_branding = "${if (proprietaryCodecs || chromeBinaryPlugins) then "Chrome" else "Chromium"}";
      # Enable DRM support for Pepper Flash
      enable_pepper_cdms = chromeBinaryPlugins;
      enable_webrtc = chromeBinaryPlugins;

      werror = "";
      #clang = stdenv.cc.isClang;
      clang = false;

      # Google API keys
      # WARNING: These are for NixOS/nixpkgs use ONLY. For other distribution,
      # please provide your own set of keys.
      # See: http://www.chromium.org/developers/how-tos/api-keys
      google_api_key = "AIzaSyDGi15Zwl11UNe6Y-5XW_upsfyw31qwZPI";
      google_default_client_id = "404761575300.apps.googleusercontent.com";
      google_default_client_secret = "9rIFQjfnkykEmqb6FfjJQD1D";

    } // optionalAttrs (versionOlder version "42.0.0.0") {
      linux_sandbox_chrome_path = "${libExecPath}/${packageName}";
    } // optionalAttrs (stdenv.system == "x86_64-linux") {
      target_arch = "x64";
      ffmpeg_target_arch = "x64";
      python_arch = "x86-64";
    } // optionalAttrs (stdenv.system == "i686-linux") {
      target_arch = "ia32";
      python_arch = "ia32";
    })
  )];

  configurePhase = ''
    # Precompile .pyc files to prevent race conditions during build
    python -m compileall -q -f . || : # ignore errors

    # This ensures the expansion of $out.
    #libExecPath="${libExecPath}"

    export GYP_DEPTH_CAUSE_FUCK_YOU_THATS_WHY='.'

    echo "configureFlags: $configureFlags"

    python build/linux/unbundle/replace_gyp_files.py $configureFlags

    # Generate ninja build files
    python build/gyp_chromium -f ninja --depth "$(pwd)" $configureFlags
  '';

  nativeBuildInputs = [
    makeWrapper perl pkgconfig python pythonPackages.gyp pythonPackages.ply
    pythonPackages.jinja2 which yasm
  ];

  buildInputs = [
    # Deafult dependencies
    alsaLib
    bison
    bzip2
    dbus_glib
    expat
    flac
    glib
    gperf
    gtk2
    icu
    kerberos
    libcap
    libevent
    libexif
    libjpeg
    libpng
    libusb1
    libwebp
    libXcursor
    libXdamage
    libxml2
    libXScrnSaver
    libxslt
    libXtst
    mesa
    minizip
    nspr
    (if useOpenSSL then openssl else nss)
    opusWithCustomModes
    pciutils
    protobuf
    snappy
    speechd
    speex
    udev
    utillinux
    xdg_utils
  ] ++ optional gnomeKeyringSupport libgnome_keyring3
    ++ optionals gnomeSupport [ gnome.GConf libgcrypt ]
    ++ optional enableSELinux libselinux
    ++ optionals cupsSupport [ libgcrypt cups ]
    ++ optional chromeBinaryPlugins chrome-binary-plugins
    ++ optional pulseSupport pulseaudio;

  enableParallelBuilding = false;

  buildPhase = let
    buildCommand = target: ''
      ${ninja}/bin/ninja -C out/Release -j$NIX_BUILD_CORES -l$NIX_BUILD_CORES ${target}
    '' + optionalString (target == "mksnapshot" || target == "chrome") ''
      paxmark m "${buildPath}/${target}"
    '';
  in concatStringsSep "\n" (map buildCommand buildTargets);

  installPhase = ''
    #mkdir -p "$libExecPath"
    #cp -v "$buildPath/"*.pak "$buildPath/"*.bin "$libExecPath/"
    #cp -v "$buildPath/icudtl.dat" "$libExecPath/"
    #cp -vLR "$buildPath/locales" "$buildPath/resources" "$libExecPath/"
    #cp -v "$buildPath/libffmpegsumo.so" "$libExecPath/"
    #${optionalString (versionOlder version "42.0.0.0") ''
    #  cp -v "$buildPath/libpdf.so" "$libExecPath/"
    #''}
    #cp -v "$buildPath/chrome" "$libExecPath/$packageName"

    #mkdir -vp "$out/share/man/man1"
    #cp -v "$buildPath/chrome.1" "$out/share/man/man1/$packageName.1"

    for icon_file in chrome/app/theme/chromium/product_logo_*[0-9].png; do
      num_and_suffix="''${icon_file##*logo_}"
      icon_size="''${num_and_suffix%.*}"
      expr "$icon_size" : "^[0-9][0-9]*$" || continue
      logo_output_prefix="$out/share/icons/hicolor"
      logo_output_path="$logo_output_prefix/''${icon_size}x''${icon_size}/apps"
      mkdir -vp "$logo_output_path"
      cp -v "$icon_file" "$logo_output_path/$packageName.png"
    done
  '';

  #desktopItem = makeDesktopItem {
  #  name = "chromium";
  #  exec = "chromium";
  #  icon = "${out}/share/icons/hicolor/48x48/apps/chromium.png";
  #  comment = "An open source web browser from Google";
  #  desktopName = "Chromium";
  #  genericName = "Web browser";
  #  mimeType = stdenv.lib.concatStringsSep ";" [
  #    "text/html"
  #    "text/xml"
  #    "application/xhtml+xml"
  #    "x-scheme-handler/http"
  #    "x-scheme-handler/https"
  #    "x-scheme-handler/ftp"
  #    "x-scheme-handler/mailto"
  #    "x-scheme-handler/webcal"
  #    "x-scheme-handler/about"
  #    "x-scheme-handler/unknown"
  #  ];
  #  categories = "Network;WebBrowser";
  #};

  meta = with stdenv.lib; {
    description = "An open source web browser from Google";
    homepage = http://www.chromium.org/;
    license = licenses.bsd3;
    maintainers = with maintainers; [ aszlig chaoflow goibhniu ];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };
}
