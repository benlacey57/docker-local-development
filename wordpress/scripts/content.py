import json
from pathlib import Path
from typing import Dict, List
from rich.console import Console

console = Console()

class ContentManager:
    def __init__(self, services_folder: Path, seo_counties_folder: Path, seo_towns_folder: Path):
        self.services_folder = services_folder
        self.seo_counties_folder = seo_counties_folder
        self.seo_towns_folder = seo_towns_folder

    def load_json_file(self, filepath: Path) -> Dict:
        """Load a JSON file."""
        try:
            with open(filepath, "r") as f:
                return json.load(f)
        except FileNotFoundError:
            console.print(f"[red]File not found: {filepath}")
            return {}
        except json.JSONDecodeError as e:
            console.print(f"[red]Error decoding JSON: {e}")
            return {}

    def generate_content(self, template: str, replacements: Dict[str, str]) -> str:
        """Replace placeholders in the template with actual values."""
        for placeholder, value in replacements.items():
            template = template.replace(f"{{{placeholder}}}", value)
        return template

    def load_locations(self) -> (List[Dict], List[Dict]):
        """Load county and town data."""
        counties = [self.load_json_file(file) for file in self.seo_counties_folder.glob("*.json")]
        towns = [self.load_json_file(file) for file in self.seo_towns_folder.glob("*.json")]
        return counties, towns

    def generate_seo_content(self, industry: str, wordpress: "WordPressManager"):
        """Generate SEO content and insert/update it in WordPress."""
        services_file = self.services_folder / f"{industry}.json"
        services_data = self.load_json_file(services_file)

        if not services_data:
            return

        counties, towns = self.load_locations()

        for county in counties:
            county_slug = county["slug"]
            county_name = county["name"]

            county_content = self.generate_content(
                services_data["description"],
                {"county": county_name}
            )
            wordpress.create_or_update_post(county_name, county_content, "page")

            for town in [t for t in towns if t["parent"] == county_slug]:
                town_name = town["name"]

                town_content = self.generate_content(
                    services_data["description"],
                    {"county": county_name, "town": town_name}
                )
                wordpress.create_or_update_post(town_name, town_content, "page")

                for service in services_data["services"]:
                    service_name = service["name"]

                    service_content = self.generate_content(
                        service["description"],
                        {"county": county_name, "town": town_name, "service": service_name}
                    )
                    wordpress.create_or_update_post(service_name, service_content, "page")
