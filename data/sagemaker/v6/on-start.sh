#!/bin/bash

set -e

readonly CLI_SERVER_NAME_TAG_KEY="CliServerName"
readonly WORKSPACE_ID_TAG_KEY="WorkspaceId"

readonly JUPYTER_USER_NAME="ec2-user"
readonly JUPYTER_USER_HOME="/home/${JUPYTER_USER_NAME}"
readonly WORKBENCH_DIR="${JUPYTER_USER_HOME}/SageMaker/.workbench"
readonly WORKBENCH_EXE="${WORKBENCH_DIR}/bin/wb"

# Install pip packages in background while installing java/go/workbench CLI
install_pip_package() {
  sudo -u ec2-user -i <<'EOM'

  # Install common packages in all conda environments
  COMMON_PIP_PACKAGES="\
    dsub \
    nbdime \
    nbstripout \
    pre-commit \
    pylint \
    pytest"

  # Download once
  echo "Downloading common pip packages for installation in all conda environments: $COMMON_PIP_PACKAGES"
  pip download -qqq $COMMON_PIP_PACKAGES

  # Note that "base" is special environment name, include it there as well.
  for env in base ${HOME}/anaconda3/envs/*; do
      if [ $env = 'JupyterSystemEnv' ]; then
          continue
      fi
      echo "Installing pip packages in environment '$env'"
      source /home/ec2-user/anaconda3/bin/activate $(basename "$env")
      pip install -qqq $COMMON_PIP_PACKAGES
      conda deactivate
  done
EOM
}

echo "Installing pip packages in the background."
install_pip_package &

echo "Install Amazon Correto Java 17 Headless"
yum install --quiet --assumeyes java-17-amazon-corretto-headless

# Install aws-vault
#
# TODO: Install from an official package instead of building from fork/branch when PR
#       https://github.com/99designs/aws-vault/pull/1202 merges and is built into an official
#       release (BENCH-514).

echo "Installing golang."
yum install --quiet --assumeyes golang

echo "Installing patched aws-vault."
sudo -u ec2-user -i <<'EOM'
echo "Checking out patched aws-vault source."
git clone https://github.com/jmczerk/aws-vault.git
cd aws-vault
git checkout jmczerk/issue_890

echo "Building patched aws-vault."
go build .
EOM
mv "${JUPYTER_USER_HOME}/aws-vault/aws-vault" /usr/local/bin

echo "Installing goofys."
yum -y install fuse
curl -L "https://github.com/kahing/goofys/releases/download/v0.24.0/goofys" -o goofys
chmod +x goofys
mv goofys /usr/local/bin/

# Resolve Workbench Server and Workspace ID from instance tags (requires that role TerraNotebook has
# permission sagemaker:ListTags on the notebook instance).

INSTANCE_ARN=$(jq -r .ResourceArn /opt/ml/metadata/resource-metadata.json)
INSTANCE_REGION=$(echo "${INSTANCE_ARN}" | awk -F ":" '{ print $4 }')

# Write an /etc/instance-tags file that we can use to resolve workspace ID
echo "Querying Sagemaker for instance tags."
aws sagemaker list-tags --region "${INSTANCE_REGION}" --resource-arn "${INSTANCE_ARN}" --output json \
    | jq ".Tags | map( { (.Key|tostring): .Value } ) | add" \
    > /etc/instance-tags

echo "Wrote /etc/instance-tags file:"
cat /etc/instance-tags

# Check whether required tags are set and exit if they are not.
TAGS_EXIST=$(jq "has(\"${CLI_SERVER_NAME_TAG_KEY}\") and has(\"${WORKSPACE_ID_TAG_KEY}\")" /etc/instance-tags )
if [ "${TAGS_EXIST}" == false ]; then
    wait
    echo "Script cannot continue, required tags ${CLI_SERVER_NAME_TAG_KEY} and/or ${WORKSPACE_ID_TAG_KEY} missing."
    exit 0
fi

# Resolve CLI Server, Workspace ID, and Expected AWS Config File location from tags
WORKBENCH_CLI_SERVER="$(jq -r .${CLI_SERVER_NAME_TAG_KEY} /etc/instance-tags)"
WORKBENCH_WORKSPACE="$(jq -r .${WORKSPACE_ID_TAG_KEY} /etc/instance-tags)"
AWS_CONFIG_FILE="${JUPYTER_USER_HOME}/.workbench/aws/${WORKBENCH_WORKSPACE}.conf"

# Write common environment vars to .profile so they are present in all notebooks
cat > ${JUPYTER_USER_HOME}/.profile << EOM
export WORKBENCH_DIR="${WORKBENCH_DIR}"
export WORKBENCH_EXE="${WORKBENCH_EXE}"
export WORKBENCH_CLI_SERVER="${WORKBENCH_CLI_SERVER}"
export WORKBENCH_WORKSPACE="${WORKBENCH_WORKSPACE}"
export AWS_CONFIG_FILE="${AWS_CONFIG_FILE}"
export AWS_VAULT_BACKEND=keyctl
export AWS_VAULT_KEYCTL_SCOPE=user
export JAVA_HOME="/usr/lib/jvm/java-17-amazon-corretto.x86_64"
EOM

chown ${JUPYTER_USER_NAME}:${JUPYTER_USER_NAME} ${JUPYTER_USER_HOME}/.profile

echo "Wrote Jupyter user .profile:"
cat ${JUPYTER_USER_HOME}/.profile

# Source .profile from .bash_profile so env vars are consistent across notebooks and shells
echo "Source .profile from .bashrc for Jupyter user."
sed -i '/^# .bashrc$/ a \\n#Source .profile if exists\n[ -f ${HOME}/.profile ] && . ${HOME}/.profile' /home/ec2-user/.bashrc

# Set up terminado so that terminals will launch in bash with interactive logins
echo "Make bash terminal default shell."
TERMINADO_SEARCH="^# c.NotebookApp.terminado_settings = {}$"
TERMINADO_SETTING="c.NotebookApp.terminado_settings = {'shell_command': ['bash', '-il']}"
sed -i "s/${TERMINADO_SEARCH}/${TERMINADO_SETTING}/g" ${JUPYTER_USER_HOME}/.jupyter/jupyter_notebook_config.py

# Restart Jupyter server so that shell related changes take effect
echo "Restarting Jupyter Server so that shell setting changes take effect."
systemctl restart jupyter-server

# Write convenience functions to .bashrc
echo "Writing Bash functions for Workbench"
cat << 'EOM' | sed -i '/^# User specific aliases and functions$/ r /dev/stdin' /home/ec2-user/.bashrc

configure_workspace() {
  ${WORKBENCH_EXE} workspace set --uuid ${WORKBENCH_WORKSPACE}
  ${WORKBENCH_EXE} workspace configure-aws --cache-with-aws-vault=true
  ${WORKBENCH_EXE} resource mount
}

configure_ssh() {
  USER_SSH_DIR="${HOME}/.ssh"
  mkdir -p ${USER_SSH_DIR}
  USER_SSH_KEY=$(${WORKBENCH_EXE} security ssh-key get --include-private-key --format=JSON)
  echo $USER_SSH_KEY | jq -r '.privateSshKey' > ${USER_SSH_DIR}/id_rsa
  echo $USER_SSH_KEY | jq -r '.publicSshKey' > ${USER_SSH_DIR}/id_rsa.pub
  chmod 0600 ${USER_SSH_DIR}/id_rsa*
  ssh-keyscan -H github.com >> ${USER_SSH_DIR}/known_hosts
}

configure_git() {
  pushd ${HOME}/SageMaker
  ${WORKBENCH_EXE} resource list --type=GIT_REPO --format json | jq -c .[] | while read ITEM; do
    GIT_REPO_NAME="$(echo $ITEM | jq -r .name)"
    GIT_REPO_URL="$(echo $ITEM | jq -r .gitRepoUrl)"
    if [ ! -d "${GIT_REPO_NAME}" ]; then
      git clone "${GIT_REPO_URL}" "${GIT_REPO_NAME}"
    fi
  done
  popd
}

configure_workbench() {
  configure_workspace
  configure_ssh
  configure_git
}

EOM

# Now act as ec2-user to set up user config
echo "Assuming user ec2-user to configure Workbench CLI."
sudo -u ec2-user -i <<'EOM'

# Lazy create workbench persistence directory on EBS volume to survive restarts and
# symlink it in user's home directory.

echo "Creating ${WORKBENCH_DIR} directory and ~/.workbench symlink"
mkdir -p "${WORKBENCH_DIR}"
ln -sfn "${WORKBENCH_DIR}" "${HOME}/.workbench"

# If latest supported Workbench not already installed, download and install it
# This must be done as ec2-user for Workbench state to persist for user!

case "$WORKBENCH_CLI_SERVER" in
  "verily") VERSION_URL="https://terra-axon.api.verily.com/version" ;;
  "verily-devel") VERSION_URL="https://terra-devel-axon.api.verily.com/version" ;;
  "verily-autopush") VERSION_URL="https://terra-autopush-axon.api.verily.com/version" ;;
  "verily-staging") VERSION_URL="https://terra-staging-axon.api.verily.com/version" ;;
  "verily-preprod") VERSION_URL="https://terra-preprod-axon.api.verily.com/version" ;;
  "dev-stable") VERSION_URL="https://workbench-dev.verily.com/api/axon/version" ;;
  "dev-unstable") VERSION_URL="https://workbench-dev-unstable.verily.com/api/axon/version" ;;
  "test") VERSION_URL="https://workbench-test.verily.com/api/axon/version" ;;
  *) >&2 echo "Unknown CLI server name '${WORKBENCH_CLI_SERVER}'."; exit 1 ;;
esac

# Build AFS service path and fetch the CLI distribution path
VERSION_JSON="$(curl -s "${VERSION_URL}")"
readonly VERSION_JSON

LATEST_VERSION="$(echo "$VERSION_JSON" | jq -r '.latestSupportedCli')"
readonly LATEST_VERSION

DO_INSTALL_CLI=true
if [ -f "${WORKBENCH_EXE}" ] && [ "$(${WORKBENCH_EXE} version)" == "${LATEST_VERSION}" ]; then
  DO_INSTALL_CLI=false
fi
readonly DO_INSTALL_CLI

if [ "${DO_INSTALL_CLI}" = true ]; then
    readonly CLI_DISTRIBUTION_PATH="$(echo "$VERSION_JSON" | jq -r '.cliDistributionPath')"
    readonly ARCHIVE_FILE_NAME="workbench-cli.tar"

    echo "Downloading and installing Workbench CLI version ${LATEST_VERSION}"
    wget "https://storage.googleapis.com/${CLI_DISTRIBUTION_PATH#gs://}/${LATEST_VERSION}/${ARCHIVE_FILE_NAME}"

    echo "Extracting Workbench CLI tarball to '${_DIR}'."
    tar --extract --file=${ARCHIVE_FILE_NAME} --directory=${WORKBENCH_DIR} --strip-components=1
    rm ${ARCHIVE_FILE_NAME}

    echo "Configure Workbench CLI for manual login and setting server to ${WORKBENCH_CLI_SERVER}"
    ${WORKBENCH_EXE} config set browser manual
    ${WORKBENCH_EXE} server set --name ${WORKBENCH_CLI_SERVER}
fi

# If user is logged in, refresh the Workbench configuration
if [ $(${WORKBENCH_EXE} auth status --format json | jq .loggedIn) == true ]; then
  configure_workbench
fi

# NOTE: We are intentionally skipping install of cromwell, cromshell, and nextflow until there is
#       an identified ask for this.

# Write .gitignore
GIT_IGNORE_FILE="${HOME}/.gitignore"
cat > ${GIT_IGNORE_FILE} << 'EOF'
# By default, all files should be ignored by git.
# We want to be sure to exclude files containing data such as CSVs and images such as PNGs.
*.*
# Now, allow the file types that we do want to track via source control.
!*.ipynb
!*.py
!*.r
!*.R
!*.wdl
!*.sh
# Allow documentation files.
!*.md
!*.rst
!LICENSE*
EOF

# And configure git to use it
echo "Setting global git core.excludesfile to '${GIT_IGNORE_FILE}'"
git config --global core.excludesfile ${GIT_IGNORE_FILE}

EOM

# Generate Workbench bash completion (enabled by default in Amazon Linux)
echo "Writing Workbench bash completion."
sudo -u ec2-user -i sh -c '${WORKBENCH_EXE} generate-completion' > /etc/bash_completion.d/workbench

# Create the symlink to workbench binary in /usr/local/bin
echo "Symlinking Workbench CLI executable to /usr/local/bin."
ln -sf "${JUPYTER_USER_HOME}/SageMaker/.workbench/bin/wb" /usr/local/bin/wb

# Wait for pip installations to complete before moving onto final user setup
echo "Waiting for pip installations to complete..."
wait
echo "Done!"

# Install nbstripout (depends on pip install complete in base env)
echo "Installing nbstripout globally"
sudo -u ec2-user -i /home/ec2-user/anaconda3/bin/nbstripout --install --global

# Finally, add Workbench initialization to .bash_profile... we must not sudo ec2-user interactively after this!
echo "Writing first time setup prompt to .bash_profile."
cat << EOM | sed -i '/^# User specific environment and startup programs$/ r /dev/stdin' /home/ec2-user/.bash_profile
if [ \$(\${WORKBENCH_EXE} auth status --format json | jq .loggedIn) == false ]; then
    echo "User must log into Workbench to continue."
    ${WORKBENCH_EXE} auth login
    configure_workbench
fi
EOM
