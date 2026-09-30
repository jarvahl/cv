{
  description = "JSON Resume";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    handlebars = pkgs.fetchurl {
      url = "https://cdnjs.cloudflare.com/ajax/libs/handlebars.js/4.7.8/handlebars.min.js";
      hash = "sha256-DlQW8UXnvxbFhQQ1bHMv5+mWcfRpYZTFsUCiUtsC8K8=";
    };

    fonts = [ pkgs.noto-fonts pkgs.noto-fonts-color-emoji ];
    fontconfig = pkgs.makeFontsConf { fontDirectories = fonts; };
  in {
    packages.${system}.default =
      pkgs.runCommand "resume" { buildInputs = [ pkgs.nodejs pkgs.chromium pkgs.fontconfig ] ++ fonts; } ''
        # Copy theme directory
        cp -r ${./theme} theme
        chmod -R u+w theme

        # Copy Handlebars to theme directory
        cp ${handlebars} theme/handlebars.min.js

        # Render resume
        node -e "
          const theme = require('./theme/render.js');
          const fs = require('fs');
          const data = JSON.parse(fs.readFileSync('${./resume.json}', 'utf-8'));
          const html = theme.render(data);
          fs.writeFileSync('index.html', html);
        "

        cp ${./me.jpg} me.jpg
        export HOME=$PWD
        export FONTCONFIG_FILE=${fontconfig}
        chromium --headless --no-sandbox --disable-gpu --no-pdf-header-footer --print-to-pdf=resume.pdf file://$PWD/index.html

        mkdir -p $out
        cp index.html resume.pdf $out/
        cp me.jpg $out/me.jpg
      '';
  };
}