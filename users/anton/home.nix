{ config, pkgs, ... }:

{
  home.stateVersion = "25.11";
  
  home.packages = with pkgs; [
    git
  ];

  programs.git = {
    enable = true;
    userName = "Anton Schieber";
    userEmail = "antonschieber@gmail.com";
  };
}