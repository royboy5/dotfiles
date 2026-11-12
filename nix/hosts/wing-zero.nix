# wing-zero: Surface Pro 3, EndeavourOS (the Arch path). GUI host; the GPU
# module stays on (its default) so Nix GL/Vulkan apps work.
{ ... }:

{
  imports = [
    ../home/targets/generic-linux.nix
    ../home/gui.nix
  ];
}
