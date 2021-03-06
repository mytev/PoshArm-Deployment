function Add-ArmStorageProfile {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "vm")]
    Param(
        [PSTypeName("VirtualMachine")]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "vm")]
        $VirtualMachine,
        [PSTypeName("VirtualMachineScaleSet")]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "vmss")]
        $VirtualMachineScaleSet,
        $ImageReference
    )

    Begin {
        if (!$ImageReference) {
            $ImageReference = @{
                publisher = "MicrosoftWindowsServer"
                offer     = "WindowsServer"
                sku       = "2016-Datacenter-with-Containers"
                version   = "latest"
            }
        }
    }

    Process {
        If ($PSCmdlet.ShouldProcess("Adding storage profile to a virtual machine")) {
            $StorageProfile = @{
                osDisk         = @{
                    caching      = "ReadOnly"
                    createOption = "FromImage"
                }
                imageReference = $ImageReference
            }

            if ($PSCmdlet.ParameterSetName -eq "vm") {
                $VirtualMachine.properties.storageProfile = $StorageProfile
                return $VirtualMachine
            }
            else {
                $VirtualMachineScaleSet.properties.virtualMachineProfile.storageProfile = $StorageProfile
                return $VirtualMachineScaleSet
            }
        }
    }
}