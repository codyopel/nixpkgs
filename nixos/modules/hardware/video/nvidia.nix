{ config, lib, pkgs, pkgs_i686, ... }:

# This module provides the proprietary NVIDIA drivers

let
  drivers = config.services.xserver.videoDrivers;

  # FIXME: should introduce an option like ‘hardware.gpu.nvidia.package’
  # for overriding the default NVIDIA driver.
  nvidiaForKernel = kernelPackages:
    if elem "nvidiaLegacy304" drivers then
      kernelPackages.nvidia-drivers_legacy304
    else if elem "nvidiaLegacy340" drivers then
      kernelPackages.nvidia-drivers_legacy340
    else if elem "nvidia" drivers then
        kernelPackages.nvidia-drivers
    else if elem "nvidiaLatest" drivers then
        kernelPackages.nvidia-drivers_latest
    else if elem "nvidiaTesting" drivers then
        kernelPackages.nvidia-drivers_testing
    else null;

  nvidia-drivers = nvidiaForKernel config.boot.kernelPackages;
  nvidia-drivers_libs32 = (nvidiaForKernel pkgs_i686.linuxPackages).override {
    libsOnly = true;
    kernel = null;
  };

  enabled = nvidia-drivers != null;
in

{

  config = mkIf enabled {

    services.xserver.drivers = singleton {
      name = "nvidia";
      modules = [ nvidia-drivers ];
      libPath = [ nvidia-drivers ];
    };

    services.xserver.screenSection = ''
      Option "RandRRotation" "on"
    '';

    hardware.opengl.package = nvidia-drivers;
    hardware.opengl.package32 = nvidia-drivers_libs32;

    environment.systemPackages = [ nvidia-drivers ];

    boot.extraModulePackages = [ nvidia-drivers ];

    # nvidia-uvm is required by CUDA applications. (x86_64 only)
    boot.kernelModules = optionals nvidia-drivers.cudaUVM [ "nvidia-uvm" ];

    # Create /dev/nvidia-uvm when the nvidia-uvm module is loaded. (x86_64 only)
    services.udev.extraRules = optionalString nvidia-drivers.cudaUVM ''
        KERNEL=="nvidia_uvm", RUN+="${pkgs.stdenv.shell} -c 'mknod -m 666 /dev/nvidia-uvm c $(grep nvidia-uvm /proc/devices | cut -d \  -f 1) 0'"
      '';

    boot.blacklistedKernelModules = [ "nouveau" "nvidiafb" "rivafb" "rivatv" ];

    services.acpid.enable = true;

    environment.etc."OpenCL/vendors/nvidia.icd".source = "${nvidia-drivers}/lib/vendors/nvidia.icd";
    environment.etc."nvidia/nvidia-application-profiles-${nvidia-drivers.version}-rc".source = 
      "${nvidia-drivers}/share/doc/nvidia-application-profiles-${nvidia-drivers.version}-rc";

  };

}
