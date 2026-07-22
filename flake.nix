{
  description = "Portable Home Manager and nix-darwin modules";

  outputs = { self }: {
    homeManagerModules.default = import ./nix/home/common.nix;
    darwinModules.default = import ./nix/darwin/common.nix;
  };
}
