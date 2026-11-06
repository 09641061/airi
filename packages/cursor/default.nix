{
  pkgs,
  lib,
  ...
}:

let
  pname = "cursor";
  release = lib.importJSON ./sources.json;
  inherit (release) version;

  sourceInfo = release.sources.${pkgs.stdenv.hostPlatform.system} or (throw "cursor: unsupported platform ${pkgs.stdenv.hostPlatform.system}");
  source = pkgs.fetchurl sourceInfo;

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit version pname;
    src = source;
  };

  wrappedAppimage = pkgs.appimageTools.wrapType2 {
    inherit version pname;
    src = source;
    extraPkgs = pkgs: with pkgs; [
      libsecret
      libnotify
      xdg-utils
      mesa
      vulkan-loader
    ];
  };
in
pkgs.stdenvNoCC.mkDerivation {
  inherit pname version;
  src = wrappedAppimage;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/cursor $out/share/applications $out/share/icons

    cp -r bin $out/bin

    cp -a ${appimageContents}/usr/share/cursor/locales $out/share/cursor/
    cp -a ${appimageContents}/usr/share/cursor/resources $out/share/cursor/
    cp -a ${appimageContents}/usr/share/icons $out/share/

    install -Dm 644 ${appimageContents}/cursor.desktop -t $out/share/applications/

    substituteInPlace $out/share/applications/cursor.desktop \
      --replace-quiet "Icon=co.anysphere.cursor" "Icon=cursor"

    wrapProgram $out/bin/cursor \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}} --no-update"

    runHook postInstall
  '';

  meta = with lib; {
    description = "AI-powered code editor built on VS Code";
    homepage = "https://cursor.com";
    license = licenses.unfree;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames release.sources;
    mainProgram = "cursor";
  };
}
