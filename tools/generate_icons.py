import os
from PIL import Image
import logging
from typing import List, Dict

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

SRC = "assets/icons/logo.png"

SIZES = [16, 32, 64, 128, 256, 512, 1024]
ASSETS_DIR = "assets/icons"
ANDROID_DIR = "android/app/src/main/res"
IOS_DIR = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
WEB_DIR = "web/icons"
MACOS_DIR = "macos/Runner/Assets.xcassets/AppIcon.appiconset"

# Minimum resolution requirements
MIN_RESOLUTION = 64
MAX_RESOLUTION = 4096

class IconGenerator:
    def __init__(self, src_path: str):
        self.src_path = src_path
        self.base_img = None

    def load_base_image(self) -> bool:
        """Load and validate the base image."""
        try:
            if not os.path.exists(self.src_path):
                logger.error(f"Source image not found: {self.src_path}")
                return False

            self.base_img = Image.open(self.src_path).convert("RGBA")

            # Validate base image
            width, height = self.base_img.size
            if width != height:
                logger.warning(
                    f"Base image is not square: {width}x{height}. "
                    "Aspect ratio will be maintained."
                )

            if min(width, height) < MIN_RESOLUTION:
                logger.error(
                    f"Base image resolution too low: {min(width, height)}px "
                    f"(minimum: {MIN_RESOLUTION}px)"
                )
                return False

            if max(width, height) > MAX_RESOLUTION:
                logger.warning(
                    f"Base image resolution very high: {max(width, height)}px "
                    f"(maximum recommended: {MAX_RESOLUTION}px)"
                )

            logger.info(f"Base image loaded successfully: {width}x{height}")
            return True

        except Exception as e:
            logger.error(f"Failed to load base image: {e}")
            return False

    def validate_icon_quality(self, icon_path: str) -> bool:
        """Validate icon quality after generation."""
        try:
            if not os.path.exists(icon_path):
                logger.error(f"Generated icon not found: {icon_path}")
                return False

            img = Image.open(icon_path)
            width, height = img.size

            # Check if square
            if width != height:
                logger.warning(f"Icon is not square: {width}x{height}")

            # Check minimum resolution
            if min(width, height) < 16:
                logger.error(
                    f"Icon resolution too low: {min(width, height)}px"
                )
                return False

            # Check for transparency
            if img.mode != 'RGBA':
                logger.warning(f"Icon does not have transparency: {img.mode}")

            # Check for pixelation (simple heuristic)
            # This is a basic check - more sophisticated analysis could be added
            pixels = list(img.getdata())
            unique_colors = len(set(pixels))
            if unique_colors < 10:  # Very few unique colors might indicate issues
                logger.warning(f"Icon has very few unique colors: {unique_colors}")

            logger.info(
                f"Icon quality validated: {icon_path} ({width}x{height})"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to validate icon {icon_path}: {e}")
            return False

    def generate_responsive_icons(self, sizes: List[int]) -> Dict[int, str]:
        """Generate multiple sizes and return mapping."""
        generated_icons = {}

        if not self.base_img:
            logger.error("Base image not loaded")
            return generated_icons

        ensure_dir(ASSETS_DIR)

        for size in sizes:
            try:
                path = f"{ASSETS_DIR}/logo_{size}.png"
                img_resized = self.base_img.resize((size, size), Image.LANCZOS)

                # Ensure consistent aspect ratio by cropping if necessary
                if self.base_img.size[0] != self.base_img.size[1]:
                    # Center crop to square
                    min_side = min(self.base_img.size)
                    left = (self.base_img.size[0] - min_side) // 2
                    top = (self.base_img.size[1] - min_side) // 2
                    right = left + min_side
                    bottom = top + min_side
                    cropped = self.base_img.crop((left, top, right, bottom))
                    img_resized = cropped.resize((size, size), Image.LANCZOS)

                img_resized.save(path, format="PNG")

                if self.validate_icon_quality(path):
                    generated_icons[size] = path
                    logger.info(f"Generated icon: {path}")
                else:
                    logger.warning(f"Generated icon failed validation: {path}")

            except Exception as e:
                logger.error(f"Failed to generate icon size {size}: {e}")

        return generated_icons

# Ensure directory exists (utility function)


def ensure_dir(path: str) -> None:
    """Ensure directory exists with path validation."""
    try:
        # Validate path to prevent traversal
        abs_path = os.path.abspath(path)
        project_root = os.path.abspath(os.path.dirname(__file__) + '/..')
        
        if not abs_path.startswith(project_root):
            raise ValueError(f"Path traversal detected: {path}")
        
        os.makedirs(abs_path, exist_ok=True)
        logger.debug(f"Directory ensured: {abs_path}")
    except Exception as e:
        logger.error(f"Failed to create directory {path}: {e}")


# Save resized icon to path


def save_icon(img: Image.Image, path: str, size: int) -> bool:
    """Save resized icon to path with validation."""
    try:
        # Validate path to prevent traversal
        abs_path = os.path.abspath(path)
        project_root = os.path.abspath(os.path.dirname(__file__) + '/..')
        
        if not abs_path.startswith(project_root):
            raise ValueError(f"Path traversal detected: {path}")
        
        img_resized = img.resize((size, size), Image.LANCZOS)
        img_resized.save(abs_path, format="PNG")

        # Validate the generated icon
        generator = IconGenerator("")
        generator.base_img = img  # Temporary assignment for validation
        return generator.validate_icon_quality(abs_path)

    except Exception as e:
        logger.error(f"Failed to save icon {path}: {e}")
        return False


# Main icon generation logic


def main():
    """Main icon generation function with enhanced validation."""
    logger.info("Starting icon generation process...")

    generator = IconGenerator(SRC)

    if not generator.load_base_image():
        logger.error("Failed to load base image. Aborting.")
        return False

    # 1. Standard sizes in assets/icons/
    logger.info("Generating standard icon sizes...")
    generated_standard = generator.generate_responsive_icons(SIZES)

    if not generated_standard:
        logger.error("Failed to generate any standard icons")
        return False

    # 2. Android mipmap icons
    logger.info("Generating Android icons...")
    android_map = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    android_success = True
    for folder, sz in android_map.items():
        ensure_dir(f"{ANDROID_DIR}/{folder}")
        path = f"{ANDROID_DIR}/{folder}/ic_launcher.png"
        if not save_icon(generator.base_img, path, sz):
            android_success = False
            logger.error(f"Failed to generate Android icon: {path}")

    # 3. iOS icons
    logger.info("Generating iOS icons...")
    ios_map = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    ensure_dir(IOS_DIR)
    ios_success = True
    for fname, sz in ios_map.items():
        path = f"{IOS_DIR}/{fname}"
        if not save_icon(generator.base_img, path, sz):
            ios_success = False
            logger.error(f"Failed to generate iOS icon: {path}")

    # 4. Web icons
    logger.info("Generating web icons...")
    web_map = {
        "Icon-192.png": 192,
        "Icon-512.png": 512,
        "Icon-maskable-192.png": 192,
        "Icon-maskable-512.png": 512,
        "favicon.png": 64,
    }
    ensure_dir(WEB_DIR)
    web_success = True
    for fname, sz in web_map.items():
        path = f"{WEB_DIR}/{fname}"
        if not save_icon(generator.base_img, path, sz):
            web_success = False
            logger.error(f"Failed to generate web icon: {path}")

    # 5. macOS desktop icons
    logger.info("Generating macOS icons...")
    macos_map = {
        "app_icon_16.png": 16,
        "app_icon_32.png": 32,
        "app_icon_64.png": 64,
        "app_icon_128.png": 128,
        "app_icon_256.png": 256,
        "app_icon_512.png": 512,
        "app_icon_1024.png": 1024,
    }
    ensure_dir(MACOS_DIR)
    macos_success = True
    for fname, sz in macos_map.items():
        path = f"{MACOS_DIR}/{fname}"
        if not save_icon(generator.base_img, path, sz):
            macos_success = False
            logger.error(f"Failed to generate macOS icon: {path}")

    # Summary
    platform_results = [
        bool(generated_standard), android_success, ios_success,
        web_success, macos_success
    ]
    success = all(platform_results)

    if success:
        logger.info("All icons generated successfully!")
        print("All icons generated successfully!")
    else:
        logger.error("Some icons failed to generate. Check logs for details.")
        print("Some icons failed to generate. Check logs for details.")
        return False

    return True

# Entry point


if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)

