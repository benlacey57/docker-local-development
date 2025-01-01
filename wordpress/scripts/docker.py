import subprocess
from pathlib import Path
from rich.console import Console

console = Console()

class DockerManager:
    def __init__(self, wp_content_path: Path, db_path: Path, compose_file: Path):
        self.wp_content_path = wp_content_path
        self.db_path = db_path
        self.compose_file = compose_file

    def create_folders(self):
        """Create necessary folders for Docker."""
        for folder in [self.wp_content_path, self.db_path]:
            folder.mkdir(parents=True, exist_ok=True)
        console.print("[green]Docker folders created successfully.")

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
                    "volumes": [f"{self.wp_content_path.resolve()}:/var/www/html/wp-content"],
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
                    "volumes": [f"{self.db_path.resolve()}:/var/lib/mysql"],
                    "environment": {
                        "MYSQL_DATABASE": "wordpress",
                        "MYSQL_USER": "wordpress",
                        "MYSQL_PASSWORD": "password",
                        "MYSQL_ROOT_PASSWORD": "rootpassword",
                    },
                },
            },
        }
        with open(self.compose_file, "w") as f:
            f.write(json.dumps(docker_compose, indent=2))
        console.print("[green]Docker Compose file generated successfully.")

    def start_containers(self):
        """Start Docker containers."""
        try:
            subprocess.run(["docker-compose", "up", "-d"], check=True)
            console.print("[green]Docker containers started successfully.")
        except subprocess.CalledProcessError as e:
            console.print(f"[red]Failed to start Docker containers: {e}")
