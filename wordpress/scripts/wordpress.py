import subprocess
from typing import List, Dict
from rich.console import Console

console = Console()

class WordPressManager:
    def __init__(self):
        pass

    def run_command(self, command: List[str], success_message: str, error_message: str):
        """Run a WP-CLI command and handle errors."""
        try:
            subprocess.run(command, check=True)
            console.print(f"[green]{success_message}")
        except subprocess.CalledProcessError as e:
            console.print(f"[red]{error_message}: {e}")

    def apply_settings(self, settings: Dict[str, Dict]):
        """Apply WordPress settings using WP-CLI."""
        for category, options in settings.items():
            for key, value in options.items():
                command = ["docker", "exec", "-it", "wordpress", "wp", "option", "update", key, str(value)]
                self.run_command(
                    command,
                    f"Updated {category} setting: {key}",
                    f"Failed to update {category} setting: {key}"
                )

    def create_or_update_post(self, post_title: str, post_content: str, post_type: str, parent_id: int = None):
        """Create or update a WordPress post."""
        command = [
            "docker", "exec", "-it", "wordpress", "wp", "post", "create",
            f"--post_title={post_title}",
            f"--post_content={post_content}",
            f"--post_type={post_type}",
            f"--post_status=publish"
        ]
        if parent_id:
            command.append(f"--post_parent={parent_id}")

        self.run_command(
            command,
            f"Successfully created/updated post: {post_title}",
            f"Failed to create/update post: {post_title}"
        )
