self: super: {
  code-cursor = super.stdenvNoCC.mkDerivation rec {
    pname = "cursor";
    version = "0.50.0";

    src = super.fetchurl {
      url = "https://downloads.cursor.com/production/96e5b01ca25f8fbd4c4c10bc69b15f6228c80771/linux/x64/Cursor-0.50.5-x86_64.AppImage";
      sha256 = "sha256-DUWIgQYD3Wj6hF7NBb00OGRynKmXcFldWFUA6W8CZeM=";
    };

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      install -m755 $src $out/bin/cursor
    '';

    meta = with super.lib; {
      description = "AI-powered code editor based on VSCode";
      homepage = "https://cursor.com";
      license = licenses.unfree;
      platforms = platforms.linux;
      mainProgram = "cursor";
    };
  };
}
