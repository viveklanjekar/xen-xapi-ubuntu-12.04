#!/bin/bash
dom0_mem='2G'
dom0_max_vcpus='2'
log_file="/root/xen_setup.log"
reboot_required_file='/tmp/setup_xen_host_requires_reboot'


function log()
{
	echo -e "$(date +%b\ %d\ %H:%M:%S) $(hostname -s) xen-setup: $@" >> $log_file
	echo -e "$(date +%b\ %d\ %H:%M:%S) $(hostname -s) xen-setup: $@"
}

if !  dpkg --get-selections | grep  -i xen-hypervisor &> /dev/null ; then
	log "Xen Hypervisor not found - attempting to install Xen"
	if  apt-get -y install xen-hypervisor &> /dev/null ; then
		touch $reboot_required_file
	else	
		log "FATAL: failed to install Xen Hypervisor"
		exit 1
	fi
fi

if ! grep -q "GRUB_DEFAULT=\"Xen 4.1-amd64\"" /etc/default/grub;  then
	log "Setting Xen as default boot entry"
	if sed -i 's/GRUB_DEFAULT=.*\+/GRUB_DEFAULT="Xen 4.1-amd64"/' /etc/default/grub; then
		touch $reboot_required_file
	else 
		log "FATAL: failed to set Xen as dfault boot entry"
		exit 1
	fi
fi

if ! grep -q "GRUB_CMDLINE_LINUX=\"apparmor=0\"" /etc/default/grub; then
	log "Disabling Apparomor"
	if sed -i 's/GRUB_CMDLINE_LINUX=.*\+/GRUB_CMDLINE_LINUX="apparmor=0"/' /etc/default/grub; then
		touch $reboot_required_file
	else
		log "FATAL: could not disable apparmor"
		exit 1
	fi
fi

if ! grep -q "GRUB_CMDLINE_XEN" /etc/default/grub; then
	log "Setting dom0 memory and vcpu"
	if  sed -i "/GRUB_CMDLINE_LINUX=\"apparmor=0\"/ a\GRUB_CMDLINE_XEN=\"dom0_mem=${dom0_mem},max:${dom0_mem} dom0_max_vcpus=2 \"" /etc/default/grub  ; then
		touch $reboot_required_file
	else 
		log "FATAL: failed to set dom0 memory and vcpu"
	fi
elif ! grep -q "GRUB_CMDLINE_XEN=\"dom0_mem=${dom0_mem},max:${dom0_mem} dom0_max_vcpus=2 \"" /etc/default/grub ; then
	touch $reboot_required_file
	if  sed -i 's/GRUB_CMDLINE_XEN=.*\+/GRUB_CMDLINE_XEN="dom0_mem=${dom0_mem},max:${dom0_mem} dom0_max_vcpus=2 "' /etc/default/grub  ; then
		touch $reboot_required_file
	else
		log "FATAL: failed to set dom0 memory and vcpu"
	fi
fi
	
if [ -e $reboot_required_file ] ; then
	log "Updating GRUB"
	if ! update-grub &> /dev/null; then
		log "FATAL: could not update GRUB"
	exit 1
	fi
	log "Reboot REQUIRED. REBOOTing NOW to boot the Xen Hypervisor."
	reboot
	exit 0	
fi

	
