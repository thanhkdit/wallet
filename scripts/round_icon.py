import os
from PIL import Image, ImageOps, ImageDraw

def round_image(image_path, output_path):
    try:
        img = Image.open(image_path).convert("RGBA")
        size = (min(img.size), min(img.size))
        mask = Image.new('L', size, 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse((0, 0) + size, fill=255)
        
        output = ImageOps.fit(img, mask.size, centering=(0.5, 0.5))
        output.putalpha(mask)
        
        output.save(output_path, "PNG")
        print(f"Successfully created rounded image: {output_path}")
    except Exception as e:
        print(f"Error processing image: {e}")

if __name__ == "__main__":
    base_dir = os.getcwd()
    input_path = os.path.join(base_dir, "assets/images/wallet.jpg") 
    output_path = os.path.join(base_dir, "assets/images/wallet_round.png")
    
    if os.path.exists(input_path):
        round_image(input_path, output_path)
    else:
        print(f"Input file not found: {input_path}")
