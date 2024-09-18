{
  description = "Downloads and installs Vintage Story, cursor patch included";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs }:
  let 
    systems = ["x86_64-linux" "aarch64-linux" ];
  in
  {
    packages = nixpkgs.lib.genAttrs systems (system:
        let 
          pkgs = import nixpkgs { 
            inherit system; 
            config.allowUnfreePredicate = pkg: true;
          }; 
        # Dependencies for VS
          runtimeLibs = pkgs.lib.makeLibraryPath ([
            pkgs.gtk2
            pkgs.sqlite
            pkgs.openal
            pkgs.cairo
            pkgs.libGLU
            pkgs.SDL2
            pkgs.freealut
            pkgs.libglvnd
            pkgs.pipewire
            pkgs.libpulseaudio
          ] ++ (with pkgs.xorg; [
            libX11
            libXcursor
            libXi
          ]));

          version = "1.19.8";

      in pkgs.stdenv.mkDerivation {
          name = "vintagestory";
          pname = "vintagestory";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://cdn.vintagestory.at/gamefiles/stable/vs_client_linux-x64_${version}.tar.gz";
            hash = "sha256-R6J+ACYDQpOzJZFBizsQGOexR7lMyeoZqz9TnWxfwyM=";
          };

          nativeBuildInputs = [ 
            pkgs.makeWrapper
          ];

          buildInputs = [ 
            pkgs.dotnet-runtime_7 
          ];

          preFixup = ''
            makeWrapper ${pkgs.dotnet-runtime_7}/bin/dotnet $out/bin/vintagestory \
              --set LD_PRELOAD ${pkgs.xorg.libXcursor}/lib/libXcursor.so.1 \
              --prefix LD_LIBRARY_PATH : "${runtimeLibs}" \
              --add-flags $out/share/vintagestory/Vintagestory.dll
            
            makeWrapper ${pkgs.dotnet-runtime_7}/bin/dotnet $out/bin/vintagestory-server \
              --set LD_PRELOAD ${pkgs.xorg.libXcursor}/lib/libXcursor.so.1 \
              --prefix LD_LIBRARY_PATH : "${runtimeLibs}" \
              --add-flags $out/share/vintagestory/VintagestoryServer.dll
            
            find "$out/share/vintagestory/assets/" -not -path "*/fonts/*" -regex ".*/.*[A-Z].*" | while read -r file; do
              local filename="$(basename -- "$file")"
              ln -sf "$filename" "''${file%/*}"/"''${filename,,}"
            done
            '';


            installPhase = ''
              mkdir -p $out/share/vintagestory $out/bin $out/share/pixmaps $out/share/fonts/truetype
              cp -r * $out/share/vintagestory
              cp $out/share/vintagestory/assets/gameicon.xpm $out/share/pixmaps/vintagestory.xpm
              cp $out/share/vintagestory/assets/game/fonts/*.ttf $out/share/fonts/truetype
            '';

              meta = with pkgs.lib; {
                description = "An in-development indie sandbox game about innovation and exploration";
                homepage = "https://www.vintagestory.at/";
                license = licenses.unfree;
                maintainers = with maintainers; [ artturin gigglesquid ];

              };
            }
          );

          defaultPackage = nixpkgs.lib.genAttrs systems ( system: self.packages.${system});

        };
      }
