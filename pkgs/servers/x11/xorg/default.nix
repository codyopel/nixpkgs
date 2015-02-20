args: with args;

let
  mkDerivation = name: attrs:
  let
    newAttrs = (overrides."${name}" or (x: x)) attrs;
    stdenv = newAttrs.stdenv or args.stdenv;
  in
  stdenv.mkDerivation (removeAttrs newAttrs [ "stdenv" ]);

  #overrides = import ./overrides.nix {inherit args xorg;};

  xorg = rec {
  # DO NOT add packages here that are not a part of X11,
  # if it isn't here http://ftp.x.org/pub/individual/, or
  # http://xcb.freedesktop.org/dist/, DON'T add it

  #
  ## App (http://ftp.x.org/pub/individual/app/)
  #

  appres = (mkDerivation "appres" import ./app/appres/default.nix { });

  #bdftopcf = callPackage ./app/bdftopcf { };

  #beforelight = callPackage ./app/beforelight { };

  #bitmap = callPackage ./app/bitmap { };

  #compiz = callPackage ./app/compiz { };

  #constype = callPackage ./app/constype { };

  #editres = callPackage ./app/editres { };

  #fonttosfnt = callPackage ./app/fonttosfnt { };

  #fslsfonts = callPackage ./app/fslsfonts { };

  #fstobdf = callPackage ./app/fstobdf { };

  #grandr = callPackage ./app/grandr { };

  #iceauth = callPackage ./app/iceauth { };

  #ico = callPackage ./app/ico { };

  #intel-gpu-tools = callPackage ./app/intel-gpu-tools { };

  #lbxproxy = callPackage ./app/lbxproxy { };

  #libxft = callPackage ./app/libxft { };

  #listres = callPackage ./app/listres { };

  #luit = callPackage ./app/luit { };

  #mkcfm = callPackage ./app/mkcfm { };

  #mkcomposecache = callPackage ./app/mkcomposecache { };

  #mkfontdir = callPackage ./app/mkfontdir { };

  #mkfontscale = callPackage ./app/mkfontscale { };

  #oclock = callPackage ./app/oclock { };

  #proxymngr = callPackage ./app/proxymngr { };

  #rendercheck = callPackage ./app/rendercheck { };

  #rgb = callPackage ./app/rgb { };

  #rstart = callPackage ./app/rstart { };

  #scripts = callPackage ./app/scripts { };

  #sessreg = callPackage ./app/sessreg { };

  #setxkbmap = callPackage ./app/setxkbmap { };

  #showfont = callPackage ./app/showfont { };

  #smproxy = callPackage ./app/smproxy { };

  #transset = callPackage ./app/transset { };

  #twm = callPackage ./app/twm { };

  #viewres = callPackage ./app/viewres { };

  #x11perf = callPackage ./app/x11perf { };

  #xauth = callPackage ./app/xauth { };

  #xbacklight = callPackage ./app/xbacklight { };

  #xbiff = callPackage ./app/xbiff { };

  #xbitmaps = callPackage ./app/xbitmaps { };

  #xcalc = callPackage ./app/xcalc { };

  #xclipboard = callPackage ./app/xclipboard { };

  #xclock = callPackage ./app/xclock { };

  #xcmsdb = callPackage ./app/xcmsdb { };

  #xcompmgr = callPackage ./app/xcompmgr { };

  #xconsole = callPackage ./app/xconsole { };

  #xcursorgen = callPackage ./app/xcursorgen { };

  #xdbedizzy = callPackage ./app/xdbedizzy { };

  #xditview = callPackage ./app/xditview { };

  #xdm = callPackage ./app/xdm { };

  #xdpyinfo = callPackage ./app/xdpyinfo { };

  #xdriinfo = callPackage ./app/xdriinfo { };

  #xedit = callPackage ./app/xedit { };

  #xev = callPackage ./app/xev { };

  #xeyes = callPackage ./app/xeyes { };

  #xf86dga = callPackage ./app/xf86dga { };

  #xfd = callPackage ./app/xfd { };

  #xfindproxy = callPackage ./app/xfindproxy { };

  #xfontsel = callPackage ./app/xfontsel { };

  #xfs = callPackage ./app/xfs { };

  #xfsinfo = callPackage ./app/xfsinfo { };

  #xfwp = callPackage ./app/xfwp { };

  #xgamma = callPackage ./app/xgamma { };

  #xcompmgr = callPackage ./app/xcompmgr { };

  #xhost = callPackage ./app/xhost { };

  #xinit = callPackage ./app/xinit { };

  #xinput = callPackage ./app/xinput { };

  #xkbcomp = callPackage ./app/xkbcomp { };

  #xkbevd = callPackage ./app/xkbevd { };

  #xkbprint = callPackage ./app/xkbprint { };

  #xkbutils = callPackage ./app/xkbutils { };

  #xkill = callPackage ./app/xkill { };

  #xload = callPackage ./app/xload { };

  #xlogo = callPackage ./app/xlogo { };

  #xlsaatoms = callPackage ./app/xlsaatoms { };

  #xlsclients = callPackage ./app/xlsclients { };

  #xlsfonts = callPackage ./app/xlsfonts { };

  #xmag = callPackage ./app/xmag { };

  #xman = callPackage ./app/xman { };

  #xmessage = callPackage ./app/xmessage { };

  #xmh = callPackage ./app/xmh { };

  #xmodmap = callPackage ./app/xmodmap { };

  #xmore = callPackage ./app/xmore { };

  #xphelloworld = callPackage ./app/xphelloworld { };

  #xplsprinters = callPackage ./app/xplsprinters { };

  #xpr = callPackage ./app/xpr { };

  #xprehashprinterlist = callPackage ./app/xprehashprinterlist { };

  #xprop = callPackage ./app/xprop { };

  #xrandr = callPackage ./app/xrandr { };

  #xrdb = callPackage ./app/xrdb { };

  #xrefresh = callPackage ./app/xrefresh { };

  #xrx = callPackage ./app/xrx { };

  #xscope = callPackage ./app/xscope { };

  #xset = callPackage ./app/xset { };

  #xsetmode = callPackage ./app/xsetmode { };

  #xsetpointer = callPackage ./app/xsetpointer { };

  #xsetroot = callPackage ./app/xsetroot { };

  #xsm = callPackage ./app/xsm { };

  #xstdcmap = callPackage ./app/xstdcmap { };

  #xtrap = callPackage ./app/xtrap { };

  #xvidtune = callPackage ./app/xvidtune { };

  #xvinfo = callPackage ./app/xvinfo { };

  #xwd = callPackage ./app/xwd { };

  #xwininfo = callPackage ./app/xwininfo { };

  #xwud = callPackage ./app/xwud { };

  #
  ## Data
  #

  #xbitmaps

  #xcursor-themes

  #xkbdata

  #xkeyboard-config

  #
  ## Doc (http://ftp.x.org/pub/individual/doc/)
  #

  #xorg-docs

  #xorg-sgml-doctools

  #
  ## Driver (http://ftp.x.org/pub/individual/driver/)
  #

  #glamor-egl = callPackage ./driver/glamor-egl { };

  #xf86-input-acecad = callPackage ./driver/xf86-input-acecad { };

  #xf86-input-aiptek = callPackage ./driver/xf86-input-aiptek { };

  #xf86-input-calcomp = callPackage ./driver/xf86-input-calcomp { };

  #xf86-input-citron = callPackage ./driver/xf86-input-citron { };

  #xf86-input-digitaledge = callPackage ./driver/xf86-input-digitaledge { };

  #xf86-input-dmc = callPackage ./driver/xf86-input-dmc { };

  #xf86-input-dynapro = callPackage ./driver/xf86-input-dynapro { };

  #xf86-input-elo2300 = callPackage ./driver/xf86-input-elo2300 { };

  #xf86-input-elographics = callPackage ./driver/xf86-input-elographics { };

  #xf86-input-evdev = callPackage ./driver/xf86-input-evdev { };

  #xf86-input-fpit = callPackage ./driver/xf86-input-fpit { };

  #xf86-input-hyperpen = callPackage ./driver/xf86-input-hyperpen { };

  #xf86-input-jamstudio = callPackage ./driver/xf86-input-jamstudio { };

  #xf86-input-joystick = callPackage ./driver/xf86-input-joystick { };

  #xf86-input-keyboard = callPackage ./driver/xf86-input-keyboard { };

  #xf86-input-libinput = callPackage ./driver/xf86-input-libinput { };

  #xf86-input-magellan = callPackage ./driver/xf86-input-magellan { };

  #xf86-input-microtouch = callPackage ./driver/xf86-input-microtouch { };

  #xf86-input-mouse = callPackage ./driver/xf86-input-mouse { };

  #xf86-input-mutouch = callPackage ./driver/xf86-input-mutouch { };

  #xf86-input-palmax = callPackage ./driver/xf86-input-palmax { };

  #xf86-input-penmount = callPackage ./driver/xf86-input-penmount { };

  #xf86-input-spaceorb = callPackage ./driver/xf86-input-spaceorb { };

  #xf86-input-summa = callPackage ./driver/xf86-input-summa { };

  #xf86-input-synaptics = callPackage ./driver/xf86-input-synaptics { };

  #xf86-input-tek4957 = callPackage ./driver/xf86-input-tek4957 { };

  #xf86-input-ur98 = callPackage ./driver/xf86-input-ur98 { };

  #xf86-input-vmmouse = callPackage ./driver/xf86-input-vmmouse { };

  #xf86-input-void = callPackage ./driver/xf86-input-void { };

  #xf86-video-amd = callPackage ./driver/xf86-video-amd { };

  #xf86-video-apm = callPackage ./driver/xf86-video-apm { };

  #xf86-video-ark = callPackage ./driver/xf86-video-ark { };

  #xf86-video-ast = callPackage ./driver/xf86-video-ast { };

  #xf86-video-ati = callPackage ./driver/xf86-video-ati { };

  #xf86-video-chips = callPackage ./driver/xf86-video-chips { };

  #xf86-video-cirrus = callPackage ./driver/xf86-video-cirrus { };

  #xf86-video-cyrix = callPackage ./driver/xf86-video-cyrix { };

  #xf86-video-dummy = callPackage ./driver/xf86-video-dummy { };

  #xf86-video-fbdev = callPackage ./driver/xf86-video-fbdev { };

  #xf86-video-freedreno = callPackage ./driver/xf86-video-freedreno { };

  #xf86-video-geode = callPackage ./driver/xf86-video-geode { };

  #xf86-video-glide = callPackage ./driver/xf86-video-glide { };

  #xf86-video-glint = callPackage ./driver/xf86-video-glint { };

  #xf86-video-i128 = callPackage ./driver/xf86-video-i128 { };

  #xf86-video-i740 = callPackage ./driver/xf86-video-i740 { };

  #xf86-video-i810 = callPackage ./driver/xf86-video-i810 { };

  #xf86-video-impact = callPackage ./driver/xf86-video-impact { };

  #xf86-video-intel = callPackage ./driver/xf86-video-intel { };

  #xf86-video-mach64 = callPackage ./driver/xf86-video-mach64 { };

  #xf86-video-mga = callPackage ./driver/xf86-video-mga { };

  #xf86-video-modesetting = callPackage ./driver/xf86-video-modesetting { };

  #xf86-video-neomagic = callPackage ./driver/xf86-video-neomagic { };

  #xf86-video-newport = callPackage ./driver/xf86-video-newport { };

  #xf86-video-nouveau = callPackage ./driver/xf86-video-nouveau { };

  #xf86-video-nsc = callPackage ./driver/xf86-video-nsc { };

  #xf86-video-nv = callPackage ./driver/xf86-video-nv { };

  #xf86-video-omap = callPackage ./driver/xf86-video-omap { };

  #xf86-video-openchrome = callPackage ./driver/xf86-video-openchrome { };

  #xf86-video-opentegra = callPackage ./driver/xf86-video-opentegra { };

  #xf86-video-qxl = callPackage ./driver/xf86-video-qxl { };

  #xf86-video-r128 = callPackage ./driver/xf86-video-r128 { };

  #xf86-video-radeonhd = callPackage ./driver/xf86-video-radeonhd { };

  #xf86-video-rendition = callPackage ./driver/xf86-video-rendition { };

  #xf86-video-s3 = callPackage ./driver/xf86-video-s3 { };

  #xf86-video-s3virge = callPackage ./driver/xf86-video-s3virge { };

  #xf86-video-savage = callPackage ./driver/xf86-video-savage { };

  #xf86-video-siliconmotion = callPackage ./driver/xf86-video-siliconmotion { };

  #xf86-video-sis = callPackage ./driver/xf86-video-sis { };

  #xf86-video-sisusb = callPackage ./driver/xf86-video-sisusb { };

  #xf86-video-sunbw2 = callPackage ./driver/xf86-video-sunbw2 { };

  #xf86-video-suncg3 = callPackage ./driver/xf86-video-suncg3 { };

  #xf86-video-suncg6 = callPackage ./driver/xf86-video-suncg6 { };

  #xf86-video-suncg14 = callPackage ./driver/xf86-video-suncg14 { };

  #xf86-video-sunffb = callPackage ./driver/xf86-video-sunffb { };

  #xf86-video-sunleo = callPackage ./driver/xf86-video-sunleo { };

  #xf86-video-suntcx = callPackage ./driver/xf86-video-suntcx { };

  #xf86-video-tdfx = callPackage ./driver/xf86-video-tdfx { };

  #xf86-video-tga = callPackage ./driver/xf86-video-tga { };

  #xf86-video-trident = callPackage ./driver/xf86-video-trident { };

  #xf86-video-tseng = callPackage ./driver/xf86-video-tseng { };

  #xf86-video-v4l = callPackage ./driver/xf86-video-v4l { };

  #xf86-video-vermilion = callPackage ./driver/xf86-video-vermilion { };

  #xf86-video-vesa = callPackage ./driver/xf86-video-vesa { };

  #xf86-video-vga = callPackage ./driver/xf86-video-vga { };

  #xf86-video-via = callPackage ./driver/xf86-video-via { };

  #xf86-video-vmware = callPackage ./driver/xf86-video-vmware { };

  #xf86-video-voodoo = callPackage ./driver/xf86-video-voodoo { };

  #xf86-video-wsfb = callPackage ./driver/xf86-video-wsfb { };

  #xf86-video-xgi = callPackage ./driver/xf86-video-xgi { };

  #xf86-video-xgixp = callPackage ./driver/xf86-video-xgixp { };

  #
  ## Font (http://ftp.x.org/pub/individual/font/)
  #

  #encodings = callPackage ./font/encodings { };

  #font-adobe-75dpi = callPackage ./font/font-adobe-75dpi { };

  #font-adobe-100dpi = callPackage ./font/font-adobe-100dpi { };

  #font-adobe-utopia-75dpi = callPackage ./font/font-adobe-utopia-75dpi { };

  #font-adobe-utopia-100dpi = callPackage ./font/font-adobe-utopia-100dpi { };

  #font-adobe-utopia-type1 = callPackage ./font/font-adobe-utopia-type1 { };

  #font-alias = callPackage ./font/font-alias { };

  #font-arabic-misc = callPackage ./font/font-arabic-misc { };

  #font-bh-75dpi = callPackage ./font/font-bh-75dpi { };

  #font-bh-100dpi = callPackage ./font/font-bh-100dpi { };

  #font-bh-lucidatypewriter-75dpi = callPackage ./font/ { };

  #font-bh-lucidatypewriter-100dpi = callPackage ./font/ { };

  #font-bh-ttf = callPackage ./font/ { };

  #font-bh-type1 = callPackage ./font/ { };

  #font-bitstream-75dpi = callPackage ./font/ { };

  #font-bitstream-100dpi = callPackage ./font/ { };

  #font-bitstream-speedo = callPackage ./font/ { };

  #font-bitstream-type1 = callPackage ./font/ { };

  #font-cronyx-cyrillic = callPackage ./font/ { };

  #font-cursor-misc = callPackage ./font/ { };

  #font-daewoo-misc = callPackage ./font/ { };

  #font-dec-misc = callPackage ./font/ { };

  #font-ibm-type1 = callPackage ./font/ { };

  #font-isas-misc = callPackage ./font/ { };

  #font-jis-misc = callPackage ./font/ { };

  #font-micro-misc = callPackage ./font/ { };

  #font-misc-cyrillic = callPackage ./font/ { };

  #font-misc-ethiopic = callPackage ./font/ { };

  #font-misc-meltho = callPackage ./font/ { };

  #font-misc-misc = callPackage ./font/ { };

  #font-mutt-misc = callPackage ./font/ { };

  #font-schumacher-misc = callPackage ./font/ { };

  #font-screen-cyrillic = callPackage ./font/ { };

  #font-sony-misc = callPackage ./font/ { };

  #font-sun-misc = callPackage ./font/ { };

  #font-util = callPackage ./font/ { };

  #font-winitzki-cyrillic = callPackage ./font/ { };

  #font-xfree86-type1 = callPackage ./font/ { };

  #
  ## Lib
  #

  #libapplewm = callPackage ./lib/ { };

  #libfs = callPackage ./lib/ { };

  #libice = callPackage ./lib/ { };

  #libsm = callPackage ./lib/ { };

  #libwindowswm = callPackage ./lib/ { };

  #libx11 = callPackage ./lib/ { };

  #libxscrnsaver = callPackage ./lib/ { };

  #libxtrap = callPackage ./lib/ { };

  #libxau = callPackage ./lib/ { };

  #libxaw = callPackage ./lib/ { };

  #libxaw3d = callPackage ./lib/ { };

  #libxcomposite = callPackage ./lib/ { };

  #libxcursor = callPackage ./lib/ { };

  #libxdamage = callPackage ./lib/ { };

  #libxdmcp = callPackage ./lib/ { };

  #libxevie = callPackage ./lib/ { };

  #libxext = callPackage ./lib/ { };

  #libxfixes = callPackage ./lib/ { };

  #libxfont = callPackage ./lib/ { };

  #libxfontcache = callPackage ./lib/ { };

  #libxft = callPackage ./lib/ { };

  #libxi = callPackage ./lib/ { };

  #libxinerama = callPackage ./lib/ { };

  #libxmu = callPackage ./lib/ { };

  #libxp = callPackage ./lib/ { };

  #libxpm = callPackage ./lib/ { };

  #libxprintapputil = callPackage ./lib/ { };

  #libxprintutil = callPackage ./lib/ { };

  #libxrandr = callPackage ./lib/ { };

  #libxrender = callPackage ./lib/ { };

  #libxres = callPackage ./lib/ { };

  #libxt = callPackage ./lib/ { };

  #libxtst = callPackage ./lib/ { };

  #libxv = callPackage ./lib/ { };

  #libxvmc = callPackage ./lib/ { };

  #libxxf86dga = callPackage ./lib/ { };

  #libxxf86misc = callPackage ./lib/ { };

  #libxxf86vm = callPackage ./lib/ { };

  #libdmx = callPackage ./lib/ { };

  #libfontenc = callPackage ./lib/ { };

  #liblbxutil = callPackage ./lib/ { };

  #liboldx = callPackage ./lib/ { };

  #libpciaccess = callPackage ./lib/ { };

  #libxkbfile = callPackage ./lib/ { };

  #libxkbui = callPackage ./lib/ { };

  #libxshmfence = callPackage ./lib/ { };

  #pixman = callPackage ./lib/ { };

  #xtrans = callPackage ./lib/ { };

  #
  ## Proto
  #

  #applewmproto = callPackage ./proto/ { };

  #bigreqsproto = callPackage ./proto/ { };

  #compositeproto = callPackage ./proto/ { };

  #damageproto = callPackage ./proto/ { };

  #dmxproto = callPackage ./proto/ { };

  #dri2proto = callPackage ./proto/ { };

  #dri3proto = callPackage ./proto/ { };

  #evieext = callPackage ./proto/ { };

  #fixesproto = callPackage ./proto/ { };

  #fontcacheproto = callPackage ./proto/ { };

  #fontsproto = callPackage ./proto/ { };

  #glproto = callPackage ./proto/ { };

  #inputproto = callPackage ./proto/ { };

  #kbproto = callPackage ./proto/ { };

  #presentproto = callPackage ./proto/ { };

  #printproto = callPackage ./proto/ { };

  #randrproto = callPackage ./proto/ { };

  #recordproto = callPackage ./proto/ { };

  #renderproto = callPackage ./proto/ { };

  #resourceproto = callPackage ./proto/ { };

  #scrnsaverproto = callPackage ./proto/ { };

  #trapproto = callPackage ./proto/ { };

  #videoproto = callPackage ./proto/ { };

  #windowswmproto = callPackage ./proto/ { };

  #xcmiscproto = callPackage ./proto/ { };

  #xextproto = callPackage ./proto/ { };

  #xf86bigfontproto = callPackage ./proto/ { };

  #xf86dgaproto = callPackage ./proto/ { };

  #xf86driproto = callPackage ./proto/ { };

  #xf86miscproto = callPackage ./proto/ { };

  #xf86rushproto = callPackage ./proto/ { };

  #xf86vidmodeproto = callPackage ./proto/ { };

  #xineramaproto = callPackage ./proto/ { };

  #xproto = callPackage ./proto/ { };

  #xproxymanagementprotocol = callPackage ./proto/ { };

  #
  ## Test
  #

  #xorg-gtest = callPackage ./test/xorg-gtest { };

  #xts = callPackage ./test/xts { };

  #
  ## Util
  #

  #gccmakedep = callPackage ./util/gccmakedep { };

  #imake = callPackage ./util/imake { };

  #lndir = callPackage ./util/lndir { };

  #makedepend = callPackage ./util/makedepend { };

  #util-macros = callPackage ./util/util-macros { };

  #xorg-cf-files = callPackage ./util/xorg-cf-files { };

  #
  ## Xserver
  #

  #xorg-server = callPackage ./xserver/xorg-server { };

  #
  ## XCB (http://xcb.freedesktop.org/dist/)
  #

  #libpthread-stubs = callPackage ./xcb/libpthread-stubs { };

  #libxcb = callPackage ./xcb/libxcb { };

  #xcb-proto = callPackage ./xcb/xcb-proto { };

  #xcb-util = callPackage ./xcb/xcb-util { };

  #xcb-util-cursor = callPackage ./xcb/xcb-util-cursor { };

  #xcb-util-image = callPackage ./xcb/xcb-util-image { };

  #xcb-util-keysyms = callPackage ./xcb/xcb-util-keysyms { };

  #xcb-util-renderutil = callPackage ./xcb/xcb-util-renderutil { };

  #xcb-util-wm = callPackage ./xcb/xcb-util-wm { };

  #xpyb = callPackage ./xcb/xpyb { };

}; in xorg
