"""Régénère les deux QR de test dans `qr_test_assets/`.

Usage :
    python3 -m venv .venv && .venv/bin/pip install "qrcode[pil]"
    .venv/bin/python scripts/generate_qr_fixtures.py

Remplacer MERCHANT_QR_TOKEN / CLIENT_CARD_CODE ci-dessous par des valeurs
actuelles si les comptes de test d'origine ont été supprimés de la base
(`restaurants.qr_token`, `loyalty_cards.card_code`).
"""

import qrcode
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

MERCHANT_QR_TOKEN = "75a29191-7463-4634-9337-69485cfd946f"
CLIENT_CARD_CODE = "QDA9D363"

OUT_DIR = Path(__file__).resolve().parent.parent / "qr_test_assets"


def _font(bold: bool, size: int) -> ImageFont.FreeTypeFont:
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    try:
        return ImageFont.truetype(f"/usr/share/fonts/truetype/dejavu/{name}", size)
    except OSError:
        # Police bitmap par défaut si DejaVu est absent — toujours lisible,
        # juste moins soigné visuellement.
        return ImageFont.load_default()


def make_qr(data: str) -> Image.Image:
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=12,
        border=3,
    )
    qr.add_data(data)
    qr.make(fit=True)
    # Modules carrés noir sur blanc — contraste maximal pour un scan fiable
    # par une vraie caméra de téléphone, même rendu que l'app
    # (`QrDataModuleShape.square`, `AppColors.inkSolid`).
    return qr.make_image(fill_color="black", back_color="white").convert("RGB")


def add_label(img: Image.Image, title: str, subtitle: str, footer: str, color: str) -> Image.Image:
    pad_top, pad_bottom, side_margin = 84, 56, 24
    font_title, font_sub = _font(True, 26), _font(False, 16)

    measure = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    widths = [
        measure.textbbox((0, 0), text, font=font)[2]
        for text, font in [(title, font_title), (subtitle, font_sub), (footer, font_sub)]
    ]
    canvas_width = max(img.width, max(widths) + side_margin * 2)

    canvas = Image.new("RGB", (canvas_width, img.height + pad_top + pad_bottom), "white")
    canvas.paste(img, ((canvas_width - img.width) // 2, pad_top))
    draw = ImageDraw.Draw(canvas)

    def center_text(y: int, text: str, font: ImageFont.FreeTypeFont, fill: str) -> None:
        w = draw.textbbox((0, 0), text, font=font)[2]
        draw.text(((canvas_width - w) / 2, y), text, font=font, fill=fill)

    center_text(16, title, font_title, color)
    center_text(50, subtitle, font_sub, "#666666")
    center_text(canvas.height - 34, footer, font_sub, "#999999")
    return canvas


def main() -> None:
    OUT_DIR.mkdir(exist_ok=True)

    merchant = add_label(
        make_qr(MERCHANT_QR_TOKEN),
        "QR MARCHAND (TEST)",
        "Scanner avec l'app client (écran scan)",
        f"data: {MERCHANT_QR_TOKEN}",
        "#B45309",
    )
    merchant.save(OUT_DIR / "merchant_qr_test.png")

    client = add_label(
        make_qr(CLIENT_CARD_CODE),
        "QR CLIENT (TEST)",
        "Scanner avec l'app marchand (écran validation)",
        f"data: {CLIENT_CARD_CODE}",
        "#4F46E5",
    )
    client.save(OUT_DIR / "client_card_qr_test.png")

    print(f"Générés dans {OUT_DIR}: merchant_qr_test.png, client_card_qr_test.png")


if __name__ == "__main__":
    main()
