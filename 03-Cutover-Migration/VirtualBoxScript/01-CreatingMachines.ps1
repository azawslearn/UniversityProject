# ============================================================
# CONFIGURATION
# ============================================================
$iso2016   = "C:\ISOs\Windows_Server_2016.iso"
$iso2012R2 = "C:\ISOs\Windows_Server_2012R2.iso"

# Validate ISO paths
foreach ($iso in @($iso2016, $iso2012R2)) {
    if (-not (Test-Path $iso)) {
        Write-Error "ISO not found: $iso"
        exit
    }
}

# Detect first physical NIC for bridged mode
$nic = (Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface -eq $true } |
        Select-Object -First 1).Name

if (-not $nic) {
    Write-Error "No valid physical NIC found for bridged networking."
    exit
}

# VM definitions
$vms = @(
    @{ Name = "WS2016";   OS = "Windows2016_64"; ISO = $iso2016;   Disk = "WS2016.vdi" },
    @{ Name = "WS2012R2"; OS = "Windows2012_64"; ISO = $iso2012R2; Disk = "WS2012R2.vdi" }
)

# ============================================================
# CREATE VMs
# ============================================================
foreach ($vm in $vms) {

    $name = $vm.Name
    $os   = $vm.OS
    $iso  = $vm.ISO
    $disk = $vm.Disk

    Write-Host "Creating VM: $name"

    # Create VM entry
    VBoxManage createvm --name $name --ostype $os --register

    # Configure RAM, CPU, VRAM, network
    VBoxManage modifyvm $name --memory 4200 --cpus 2 --vram 128
    VBoxManage modifyvm $name --nic1 bridged --bridgeadapter1 "$nic"

    # Create 60 GB VDI disk
    VBoxManage createmedium disk --filename $disk --size 60000 --format VDI

    # Add SATA controller
    VBoxManage storagectl $name --name "SATA" --add sata --controller IntelAhci

    # Attach the hard disk
    VBoxManage storageattach $name --storagectl "SATA" --port 0 --device 0 --type hdd --medium $disk

    # Attach the ISO for installation
    VBoxManage storageattach $name --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$iso"

    # Set boot order: DVD first, hard disk second
    VBoxManage modifyvm $name --boot1 dvd --boot2 disk

    Write-Host "VM $name created and ISO attached."
}

Write-Host "All VMs created. You can now start them and install Windows."
