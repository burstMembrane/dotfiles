#!/usr/bin/env python3

import yaml
import os
import subprocess
import shlex
from pathlib import Path


def load_config():
    with open("bootstrap.yaml", "r") as f:
        return yaml.safe_load(f)


def run_command(cmd, shell=False):
    if shell:
        subprocess.run(cmd, shell=True, check=True)
    else:
        subprocess.run(shlex.split(cmd), check=True)


def install_system_packages(packages):
    subprocess.run(["sudo", "apt-get", "update"])
    subprocess.run(["sudo", "apt-get", "install", "-y"] + packages)


def check_command_exists(cmd):
    return subprocess.run(["which", cmd], capture_output=True).returncode == 0


def check_path_exists(path):
    return Path(os.path.expandvars(path)).exists()


def install_tool(name, config):
    if "check_command" in config:
        if check_command_exists(config["check_command"]):
            print(f"{name} is already installed")
            return

    if "check_path" in config:
        if check_path_exists(config["check_path"]):
            print(f"{name} is already installed")
            return

    if config.get("skip_in_docker") and is_running_in_docker():
        print(f"Skipping {name} installation in Docker")
        return

    print(f"Installing {name}...")
    for cmd in config.get("install", []):
        run_command(os.path.expandvars(cmd), shell=True)

    for cmd in config.get("post_install", []):
        run_command(os.path.expandvars(cmd), shell=True)


def is_running_in_docker():
    return os.path.exists("/.dockerenv")


def main():
    config = load_config()

    # Install system packages
    install_system_packages(config["system"]["packages"])

    # Set locale
    if "locale" in config:
        subprocess.run(["sudo", "locale-gen", config["locale"]])

    # Create directories and symlinks
    for path in config.get("paths", []):
        Path(os.path.expandvars(path)).mkdir(parents=True, exist_ok=True)

    for link in config.get("symlinks", []):
        source = os.path.expandvars(link["source"])
        target = os.path.expandvars(link["target"])
        if not os.path.exists(target):
            os.symlink(source, target)

    # Install tools
    for tool_name, tool_config in config["tools"].items():
        install_tool(tool_name, tool_config)


if __name__ == "__main__":
    main()
