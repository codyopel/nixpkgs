{ stdenv, fetchurl }:

let
  inherit (stdenv.lib) system;
  source = builtins.getAttr channel (import ./source/sources.nix);

  binary = let
    pname = if channel == "dev"
            then "google-chrome-unstable"
            else "google-chrome-${channel}";
    arch = if stdenv.is64bit then "amd64" else "i386";
    relpath = "${pname}/${pname}_${source.chan.version}-1_${arch}.deb";
  in lib.optionalAttrs (source.chan.? sha256bin64) {
    urls = map (url: "${url}/${relpath}") ([ debURL ] ++ debMirrors);
    sha256 = if stdenv.is64bit
             then source.chan.sha256bin64
             else source.chan.sha256bin32;
  };
in

stdenv.mkDerivation rec {
    name = "chrome-binary-plugins-${source.version}";

    src = fetchurl {
      url = [
        "https://dl.google.com/linux/chrome/deb/pool/main/g"
        # Untrusted mirrors, don't try to update from them!
        "http://95.31.35.30/chrome/pool/main/g"
        "http://mirror.pcbeta.com/google/chrome/deb/pool/main/g"
      ];
      sha256 = if system == "i686-linux" then source.sha256bin32
          else if system == "x86_64-linux" then source.sha256bin64
          else throw "Chrome binary plugins are not supported on the `${system}' platform";
    };

    unpackCmd = let
      chan = if source.channel == "dev"    then "chrome-unstable"
        else if source.channel == "stable" then "chrome"
        else "chrome-${source.channel}";
    in ''
      mkdir -p plugins
      ar p "$src" data.tar.${if versionOlder source.version "41.0.0.0" then "lzma" else "xz"} | tar xJ -C plugins --strip-components=4 \
        ./opt/google/${chan}/PepperFlash \
        ./opt/google/${chan}/libwidevinecdm.so \
        ./opt/google/${chan}/libwidevinecdmadapter.so
    '';

    doCheck = true;

    checkPhase = ''
      ! find -iname '*.so' -exec ldd {} + | grep 'not found'
    '';

    patchPhase = let
      mkrpath = p: "${makeSearchPath "lib64" p}:${makeSearchPath "lib" p}";
    in ''
      for sofile in PepperFlash/libpepflashplayer.so \
                    libwidevinecdm.so libwidevinecdmadapter.so; do
        chmod +x "$sofile"
        patchelf --set-rpath "${mkrpath stdenv.cc.cc}" "$sofile"
      done

      patchelf --set-rpath "$widevine/lib:${mkrpath stdenv.cc.cc}" \
        libwidevinecdmadapter.so
    '';

    installPhase = ''
      flashVersion="$(sed -n -r 's/.*"version": "([^"]+)",.*/\1/p' PepperFlash/manifest.json)"

      install -vD PepperFlash/libpepflashplayer.so "$out/lib/libpepflashplayer.so"
      mkdir -p "$out/nix-support"
      cat > "$flash/nix-support/chromium-plugin.nix" <<NIXOUT
        { flags = [
            "--ppapi-flash-path='$flash/lib/libpepflashplayer.so'"
            "--ppapi-flash-version=$flashVersion"
          ];
        }
      NIXOUT      
    '';

    installWideVine = let
      wvName = "Widevine Content Decryption Module";
      wvDescription = "Playback of encrypted HTML audio/video content";
      wvMimeTypes = "application/x-ppapi-widevine-cdm";
      wvInfo = "#${wvName}#${wvDescription}:${wvMimeTypes}";
    in ''

      install -vD libwidevinecdm.so "$out/lib/libwidevinecdm.so"
      install -vD libwidevinecdmadapter.so "$out/lib/libwidevinecdmadapter.so"
      mkdir -p "$out/nix-support"
      cat > "$out/nix-support/chromium-plugin.nix" <<NIXOUT
        { flags = [ "--register-pepper-plugins='${chrome-binary-plugins}/lib/libwidevinecdmadapter.so#Widevine Content Decryption Module#Playback of encrypted HTML audio/video content:application/x-ppapi-widevine-cdm'" ];
          envVars.NIX_CHROMIUM_PLUGIN_PATH_WIDEVINE = "$out/lib";
        }
      NIXOUT
    '';

  meta = with stdenv.lib; {
    description = "";
    homepage = ;
    license = ;
    maintainers = with maintainers; [ chromium.meta.maintainers ];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };
}
