from pathlib import Path
from scripts.docker import DockerManager
from scripts.wordpress import WordPressManager
from scripts.content import ContentManager

# Paths
WP_CONTENT_PATH = Path("wp-content")
DB_PATH = Path("db")
COMPOSE_FILE = Path("docker-compose.yml")
SERVICES_FOLDER = Path("services")
SEO_COUNTIES_FOLDER = Path("seo/counties")
SEO_TOWNS_FOLDER = Path("seo/towns")

# Initialize managers
docker_manager = DockerManager(WP_CONTENT_PATH, DB_PATH, COMPOSE_FILE)
wordpress_manager = WordPressManager()
content_manager = ContentManager(SERVICES_FOLDER, SEO_COUNTIES_FOLDER, SEO_TOWNS_FOLDER)

# Main process
def main():
    docker_manager.create_folders()
    docker_manager.generate_docker_compose()
    docker_manager.start_containers()

    industry = input("Enter the industry (e.g., plumber, marketing): ").strip().lower()
    content_manager.generate_seo_content(industry, wordpress_manager)

if __name__ == "__main__":
    main()
