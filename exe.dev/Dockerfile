# Optional: bake the dotfiles into an exe.dev image so new VMs boot ready
# instead of spending minutes in the setup script. Contains no secrets.
#
#   docker build --platform linux/amd64 -t ghcr.io/levinbaenninger/exe-dev:latest exe.dev
#   docker push ghcr.io/levinbaenninger/exe-dev:latest
#   ssh exe.dev new --image=ghcr.io/levinbaenninger/exe-dev:latest
FROM ghcr.io/boldsoftware/exeuntu:latest

LABEL exe.dev/install-shelley=true
LABEL exe.dev/login-user=exedev

USER exedev
WORKDIR /home/exedev
ENV DOTFILES_PROFILE=exe DOTFILES_WORK=0
ARG DOTFILES_BRANCH=main
RUN curl -fsSL "https://raw.githubusercontent.com/levinbaenninger/dotfiles/${DOTFILES_BRANCH}/install.sh" \
      | DOTFILES_BRANCH="${DOTFILES_BRANCH}" bash
USER root
