FROM mcr.microsoft.com/devcontainers/base:ubuntu-20.04

ENV DEBIAN_FRONTEND=noninteractive


# ------------------------ Prepare docker environment ------------------------ #

RUN apt-get update && \
    # Install general utilities
    apt-get -y install tree && \
    # Install Flutter dependencies
    apt-get -y install curl file git unzip xz-utils zip clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev && \
    # Install app-specific dependencies
    apt-get -y install keybinder-3.0 appindicator3-0.1 libappindicator3-1 libappindicator3-dev libnotify-dev


# ------------------------------ Install Flutter ----------------------------- #

RUN git clone https://github.com/flutter/flutter.git -b stable /home/vscode/flutter
RUN git config --global --add safe.directory /home/vscode/flutter
ENV PATH="$PATH:/home/vscode/flutter/bin"
RUN flutter upgrade
RUN chown -R vscode:vscode /home/vscode/flutter


# ------------------------------ Install Flatpak ----------------------------- #

RUN apt-get install -y flatpak flatpak-builder
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
RUN flatpak install -y org.freedesktop.Sdk/x86_64/21.08
RUN flatpak install -y org.freedesktop.Platform/x86_64/21.08
RUN flatpak install -y flathub org.freedesktop.appstream-glib
