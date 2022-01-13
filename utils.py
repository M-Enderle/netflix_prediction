from tmdbv3api import Movie, TMDb
from PIL import Image

tmdb = TMDb()
tmdb.api_key = '4ab4f4dbeee4940aaa23a14b14fb879d'
tmdb.language = 'en'
standard = "https://europix.cc/no-poster.png"


def get_poster(movie_name):
    if not movie_name:
        return standard
    movie = Movie()
    try:
        search = movie.search(movie_name)[0]
    except IndexError:
        return standard
    poster = search.poster_path
    if not poster:
        return standard
    return "https://www.themoviedb.org/t/p/w600_and_h900_bestv2" + poster


def crop_image():
    im = Image.open("./plot.png")
    pixels = im.convert('RGBA')
    height = 1000
    width = 1200

    crop = []

    for x in range(width):
        if any([pixels.getpixel((x,y))[3] for y in range(height)]):
            crop.append(x-1)
            break

    for y in range(height):
        if any([pixels.getpixel((x,y))[3] for x in range(width)]):
            crop.append(y-1)
            break

    for x in range(width-1, 0, -1):
        if any([pixels.getpixel((x,y))[3] for y in range(height)]):
            crop.append(x+1)
            break

    for y in range(height-1, 0, -1):
        if any([pixels.getpixel((x,y))[3] for x in range(width)]):
            crop.append(y+1)
            break

    im1 = im.crop(crop)
    im1.save("./plot.png")