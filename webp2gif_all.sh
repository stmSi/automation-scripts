for f in *.webp; do
    echo "$f"
    python3 -c "
from PIL import Image, ImageSequence

def extract_and_save_frames(source, dest):
    with Image.open(source) as im:
        if not im.is_animated:
            frames = [im.convert('RGBA')]
        else:
            frames = [frame.copy().convert('RGBA') for frame in ImageSequence.Iterator(im)]

        # Create a new image with white background for each frame
        new_frames = []
        for frame in frames:
            bg = Image.new('RGBA', frame.size, (255, 255, 255, 255))
            bg.paste(frame, (0, 0), frame)
            new_frames.append(bg.convert('RGB'))

        new_frames[0].save(dest, save_all=True, append_images=new_frames[1:], optimize=False, loop=0, duration=im.info['duration'])

extract_and_save_frames('$f', '${f%.webp}.gif')
"
done
