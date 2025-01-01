import os
import json
import subprocess
from pathlib import Path
from rich.console import Console
from rich.progress import Progress
from typing import List, Dict

console = Console()

class WordPressDockerSetup:
    def __init__(self):
        self.docker_compose_file = "docker-compose.yml"
        self.settings_folder = Path("settings")
        self.content_folder = Path("content")
        self.wp_content_folder = Path("wp-content")
        self.database_folder = Path("db")
        self.site_url = "localhost"
        self.site_name = "Local WordPress Site"

    def run_command(self, command: List[str], success_message: str, error_message: str):
        """Run a shell command and handle errors."""
        try:
            subprocess.run(command, check=True)
            console.print(f"[green]{success_message}")
        except subprocess.CalledProcessError as e:
            console.print(f"[red]{error_message}: {e}")

    def prompt_user_input(self):
        """Prompt user for basic site configuration."""
        self.site_name = console.input("Enter site name [default: Local WordPress Site]: ") or self.site_name
        self.site_url = console.input("Enter site URL [default: localhost]: ") or self.site_url

    def create_folders(self):
        """Create necessary folders for Docker and WordPress."""
        for folder in [self.settings_folder, self.content_folder, self.wp_content_folder, self.database_folder]:
            folder.mkdir(exist_ok=True)
        console.print("[green]Folders created successfully.")

    def generate_docker_compose(self):
        """Generate a Docker Compose file for WordPress and MySQL."""
        docker_compose = {
            "version": "3.7",
            "services": {
                "wordpress": {
                    "image": "wordpress:latest",
                    "container_name": "wordpress",
                    "restart": "always",
                    "ports": ["80:80"],
                    "volumes": [
                        f"{self.wp_content_folder.resolve()}:/var/www/html/wp-content"
                    ],
                    "environment": {
                        "WORDPRESS_DB_HOST": "db",
                        "WORDPRESS_DB_USER": "wordpress",
                        "WORDPRESS_DB_PASSWORD": "password",
                        "WORDPRESS_DB_NAME": "wordpress",
                    },
                },
                "db": {
                    "image": "mysql:5.7",
                    "container_name": "mysql",
                    "restart": "always",
                    "volumes": [
                        f"{self.database_folder.resolve()}:/var/lib/mysql"
                    ],
                    "environment": {
                        "MYSQL_DATABASE": "wordpress",
                        "MYSQL_USER": "wordpress",
                        "MYSQL_PASSWORD": "password",
                        "MYSQL_ROOT_PASSWORD": "rootpassword",
                    },
                },
            },
        }
        with open(self.docker_compose_file, "w") as f:
            json.dump(docker_compose, f, indent=2)
        console.print("[green]Docker Compose file generated successfully.")

    def apply_wordpress_settings(self):
        """Apply WordPress settings from JSON files."""
        try:
            for file in self.settings_folder.glob("*.json"):
                with open(file, "r") as f:
                    settings = json.load(f)

                if file.stem == "general":
                    # Apply general settings
                    self.run_command(
                        ["docker", "exec", "-it", "wordpress", "wp", "option", "update", "blogname", settings["site_name"]],
                        "Updated site name.",
                        "Failed to update site name."
                    )
                    self.run_command(
                        ["docker", "exec", "-it", "wordpress", "wp", "option", "update", "siteurl", settings["site_url"]],
                        "Updated site URL.",
                        "Failed to update site URL."
                    )
                elif file.stem == "reading":
                    # Apply reading settings
                    self.run_command(
                        ["docker", "exec", "-it", "wordpress", "wp", "option", "update", "show_on_front", settings["show_on_front"]],
                        "Updated reading setting: show_on_front.",
                        "Failed to update reading setting: show_on_front."
                    )
                    if "page_on_front" in settings:
                        self.run_command(
                            ["docker", "exec", "-it", "wordpress", "wp", "option", "update", "page_on_front", settings["page_on_front"]],
                            "Updated front page ID.",
                            "Failed to update front page ID."
                        )
                    if "page_for_posts" in settings:
                        self.run_command(
                            ["docker", "exec", "-it", "wordpress", "wp", "option", "update", "page_for_posts", settings["page_for_posts"]],
                            "Updated posts page ID.",
                            "Failed to update posts page ID."
                        )
                elif file.stem == "discussion":
                    # Apply discussion settings
                    for key, value in settings.items():
                        self.run_command(
                            ["docker", "exec", "-it", "wordpress", "wp", "option", "update", key, str(value).lower()],
                            f"Updated discussion setting: {key}.",
                            f"Failed to update discussion setting: {key}."
                        )
                elif file.stem == "permalinks":
                    # Apply permalinks
                    self.run_command(
                        ["docker", "exec", "-it", "wordpress", "wp", "rewrite", "structure", settings["permalink_structure"]],
                        "Updated permalink structure.",
                        "Failed to update permalink structure."
                    )
                    if "category_base" in settings:
                        self.run_command(
                            ["docker", "exec", "-it", "wordpress", "wp", "rewrite", "category-base", settings["category_base"]],
                            "Updated category base.",
                            "Failed to update category base."
                        )
                    if "tag_base" in settings:
                        self.run_command(
                            ["docker", "exec", "-it", "wordpress", "wp", "rewrite", "tag-base", settings["tag_base"]],
                            "Updated tag base.",
                            "Failed to update tag base."
                        )
                elif file.stem == "media":
                    # Apply media settings
                    for key, value in settings.items():
                        if isinstance(value, dict):
                            for sub_key, sub_value in value.items():
                                option_key = f"{key}_{sub_key}"
                                self.run_command(
                                    ["docker", "exec", "-it", "wordpress", "wp", "option", "update", option_key, str(sub_value)],
                                    f"Updated media setting: {option_key}.",
                                    f"Failed to update media setting: {option_key}."
                                )
                        else:
                            self.run_command(
                                ["docker", "exec", "-it", "wordpress", "wp", "option", "update", key, str(value)],
                                f"Updated media setting: {key}.",
                                f"Failed to update media setting: {key}."
                            )

        except Exception as e:
            console.print(f"[red]Error applying WordPress settings: {e}")

    def run(self):
        """Main method to orchestrate the entire setup."""
        self.prompt_user_input()
        self.create_folders()
        self.generate_docker_compose()
        self.apply_wordpress_settings()


if __name__ == "__main__":
    setup = WordPressDockerSetup()
    setup.run()
