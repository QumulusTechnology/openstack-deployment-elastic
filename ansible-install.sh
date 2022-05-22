#!/usr/bin/env bash

###############################################################################
# Debug Options
###############################################################################
# Short form: set -u
# set -o nounset
# Short form: set -e
# set -o errexit

# Print a helpful message if a pipeline with non-zero exit code causes the
# script to exit as described above.
# trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR

# Allow the above trap be inherited by all functions in the script.
#
# Short form: set -E
# set -o errtrace

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
# set -o pipefail

###############################################################################
# Program Variables
###############################################################################

# Set $IFS to only newline and tab.
# http://www.dwheeler.com/essays/filenames-in-shell.html
IFS=$'\n\t'

###############################################################################
# Program Functions
###############################################################################

_install_ansible() {
if [ ! -x "$(command -v ansible-galaxy)" ]; then
  # install role
  apt update
  DEBIAN_FRONTEND=noninteractiv apt upgrade -yq
  DEBIAN_FRONTEND=noninteractiv apt install -yq ansible-core
fi
}

_verify_ansible() {
if [ -x "$(command -v ansible-galaxy)" ]; then
  # install role
  ansible-galaxy install git+https://github.com/elastic/ansible-elastic-cloud-enterprise.git
else
  echo "ERROR: Ansible isn't installed on this machine, aborting ece installation"
  exit 1
fi
}

_write_ansible_playbook() {
cat << PLAYBOOK > ./ece.yml
---

- hosts: all
  gather_facts: true
  roles:
    - node_prep

- hosts: primary
  gather_facts: true
  roles:
    - ansible-elastic-cloud-enterprise
  vars:
    ece_primary: true
    ece_version: ${ece-version}


- hosts: secondary
  gather_facts: true
  roles:
    - ansible-elastic-cloud-enterprise
  vars:
    ece_roles: [director, coordinator, proxy, allocator]
    ece_version: ${ece-version}


- hosts: tertiary
  gather_facts: true
  roles:
    - ansible-elastic-cloud-enterprise
  vars:
    ece_roles: [director, coordinator, proxy, allocator]
    ece_version: ${ece-version}

PLAYBOOK
}

_write_ansible_hosts() {
cat << HOSTS_FILE > ./hosts
[primary]
ece-server0 ansible_host=${ece-server0}

[secondary]
ece-server1 ansible_host=${ece-server1}

[tertiary]
ece-server2 ansible_host=${ece-server2}

[ece:children]
primary
secondary
tertiary

[ece:vars]
ansible_ssh_private_key_file=${key}
ansible_user=${user}
ansible_become=yes
availability_zone=zone1
primary_hostname=ece-server0
device_name=${device}
data_dir=/data

HOSTS_FILE
}

_run_ansible() {
  export ANSIBLE_HOST_KEY_CHECKING=False
  ansible-playbook -i hosts ece.yml
  }


###############################################################################
# Main
###############################################################################

# _main()
#
# Usage:
#   _main [<options>] [<arguments>]
#
# Description:
#   Entry point for the program, handling basic option parsing and dispatching.
_main() {
    _install_ansible
    _verify_ansible
    _write_ansible_playbook
    _write_ansible_hosts
    sleep ${sleep-timeout}
    _run_ansible
}

# Call `_main` after everything has been defined.
_main "$@"
