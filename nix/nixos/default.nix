# The NixOS system layer shared by every NixOS host (ticket 09).
{ pkgs, username, ... }:

{
  # --- Nix itself ---
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.gc = {
    automatic = true;
    dates = "Sun 03:00";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;
  # Free software only: the allowlist is empty on purpose.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ ];

  # --- The user (ticket 09) ---
  # isNormalUser also makes home-manager take home.homeDirectory from
  # /home/roy. No password hash lives in the repo: set one with `passwd`.
  #
  # SSH keys are managed by hand in ~/.ssh/authorized_keys, which sshd reads by
  # default. Password login is off, so until that file exists, ssh login is
  # impossible (use the console).
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "audio"
    ];
  };

  # --- System zsh (ticket 04) ---
  # zsh-autocomplete runs compinit itself and starship draws the prompt, so
  # the system must do neither.
  programs.zsh = {
    enable = true;
    enableCompletion = false;
    enableBashCompletion = false;
    promptInit = "";
  };

  # --- Services ---
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  virtualisation.docker.enable = true;

  # Run unpatched dynamic binaries (ticket 08), with the default libraries.
  programs.nix-ld.enable = true;
}
