{ lib, pkgs, ... }:

let
  weather = pkgs.writeShellScriptBin "weather-widget" ''
    #!${pkgs.bash}/bin/bash
    
    # 1. Ensure the script uses standard sorting and UTF-8
    export LC_ALL=en_US.UTF-8
    export PATH="${pkgs.jq}/bin:${pkgs.curl}/bin:${pkgs.coreutils}/bin:$PATH"

    # 2. Fetch Location
    # We use -m 5 to timeout after 5 seconds if offline
    loc=$(curl -s -m 5 ipinfo.io | jq -r '.loc')

    if [ -z "$loc" ] || [ "$loc" == "null" ]; then
      echo "Offline"
      exit 0
    fi

    lat=$(echo "$loc" | cut -d',' -f1)
    long=$(echo "$loc" | cut -d',' -f2)

    # 3. Fetch Weather
    weather_json=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$long&current=temperature_2m,weather_code,is_day&temperature_unit=fahrenheit")

    # 4. Parse JSON
    # We verify variables are not empty
    temp=$(echo "$weather_json" | jq -r '.current.temperature_2m')
    code=$(echo "$weather_json" | jq -r '.current.weather_code')
    is_day=$(echo "$weather_json" | jq -r '.current.is_day')

    if [ -z "$temp" ] || [ "$temp" == "null" ]; then
      echo "No Data"
      exit 0
    fi

    # 5. Determine Icon
    icon="?" 
    case $code in
       0|1) # Clear
          if [ "$is_day" -eq 1 ]; then icon=""; else icon=""; fi ;;
       2)   # Partly Cloudy
          if [ "$is_day" -eq 1 ]; then icon=""; else icon=""; fi ;;
       3)   # Overcast
          icon="󰖐" ;;
       45|48) # Fog
          icon="󰖑" ;;
       51|53|55|56|57) # Drizzle
          icon="" ;;
       61|63|65|66|67|80|81|82) # Rain
          icon="" ;;
       71|73|75|77|85|86) # Snow
          icon="󰜗" ;;
       95|96|99) # Thunderstorm
          icon="" ;;
       *) 
          icon="" ;;
    esac

    # 6. Format Output
    # We use printf explicitly to handle rounding
    # \xc2\xb0 is the safe hex code for the degree symbol
    printf "%s %.0f\xc2\xb0\n" "$icon" "$temp"
  '';
  usage = pkgs.writeShellScriptBin "usage-widget" ''
    if [[ $(uname) == "Darwin" ]]; then
      # --- macOS Implementation ---
      
      # 1. CPU: Uses top in logging mode (-l 1), filters for CPU usage line
      CPU=$(top -l 1 | grep -E "^CPU" | grep -oE "[0-9]+\.[0-9]+% user" | awk '{print $1}')
      
      # 2. RAM: Uses vm_stat and calculates percentage (Logic: Active+Wired / Total)
      # Note: This is an approximation usually sufficient for status bars
      MEM=$(ps -A -o %mem | awk '{s+=$1} END {print "" s "%"}')
      
      # 3. Disk: Standard df
      DISK=$(df -h / | awk '/\// {print $(NF-1)}')
      
      echo "  $CPU    $MEM    $DISK"

    else
      # --- Linux Implementation (Your original script) ---
      
      CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1 "%"}')
      MEM=$(free -m | awk '/Mem:/ { printf("%3.1f%%", $3/$2*100) }')
      DISK=$(df -h / | awk '/\// {print $(NF-1)}')
      
      echo "  $CPU    $MEM    $DISK"
    fi
  '';
in
{
  home = {
    packages = with pkgs; [
      cbonsai lazygit bat fd weather usage
    ];

    username = "localaiden";
    homeDirectory = "/Users/localaiden";

    # You do not need to change this if you're reading this in the future.
    # Don't ever change this after the first build.  Don't ask questions.
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
    functions = {
    r = ''
      for cmd in $history
        if test "$cmd" != "r"
          eval $cmd
          return
        end
      end
    '';
    };
    interactiveShellInit = "set fish_greeting"; # disable greeting
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableInteractive = true;
    settings = builtins.fromTOML (builtins.readFile ./dotfiles/starship.toml);
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.git = {
    enable = true;
    settings.user.name = "Aiden Tepper";
    settings.user.email = "aidenjtep@gmail.com";
  };

  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
  };
  xdg.configFile."zellij/config.kdl".source = ./dotfiles/zellij/config.kdl;
  xdg.configFile."zellij/layouts".source = ./dotfiles/zellij/layouts;
}
