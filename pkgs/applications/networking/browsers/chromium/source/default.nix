{ stdenv, fetchurl, python
, channel ? "stable"
, useOpenSSL # XXX
}:

with stdenv.lib;

with (import ./update.nix {
  inherit (stdenv) system;
}).getChannel channel;

let
  transform = flags: concatStringsSep ";" (map (subst: subst + flags) [
    "s,^[^/]+(.*)$,$main\\1,"
    "s,$main/(build|tools)(/.*)?$,$out/\\1\\2,"
    "s,$main/third_party(/.*)?$,$bundled\\1,"
    "s,$main/sandbox(/.*)?$,$sandbox\\1,"
    "s,^/,,"
  ]);

in stdenv.mkDerivation {
  name = "chromium-source-${version}";

  unpackPhase = ''
    tar xf "$src" -C / \
      --transform="${transform "xS"}" \
      --anchored \
      --no-wildcards-match-slash \
      --exclude='*/tools/gyp' \
      --exclude='*/.*'
  '';

  patchPhase = let
    diffmod = sym: "/^${sym} /{s/^${sym} //;${transform ""};s/^/${sym} /}";
    allmods = "${diffmod "---"};${diffmod "\\+\\+\\+"}";
    sedexpr = "/^(---|\\+\\+\\+) *\\/dev\\/null/b;${allmods}";
  in ''
    runHook prePatch
    for i in $patches; do
      header "applying patch $i" 3
      sed -r -e "${sedexpr}" "$i" | patch -d / -p0
      stopNest
    done
    runHook postPatch
  '';

  preferLocalBuild = true;

  passthru = {
    inherit version channel;
    plugins = fetchurl binary;
  };
}
