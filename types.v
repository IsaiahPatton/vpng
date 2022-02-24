module vpng

// ****
pub enum PixelType {
	indexed
	grayscale
	grayscalealpha
	truecolor
	truecoloralpha
}

pub type Pixel = Grayscale | GrayscaleAlpha | Indexed | TrueColor | TrueColorAlpha

pub struct PngFile {
	ihdr       IHDR
pub:
	width      int
	height     int
	pixel_type PixelType
pub mut:
    inter InternalPngFile
	palette    []TrueColor
	pixels     []Pixel
}

pub fn (mut this PngFile) set_pixel(x int, y int, pix TrueColorAlpha) {
    ind := y * this.width + x
    if ind > this.pixels.len {
        return
    }
    this.pixels[ind] = pix
}

pub fn (mut this PngFile) get_unfiltered() []byte {
    mut arr := []byte{}
    for mut pix in this.pixels {
        if mut pix is TrueColorAlpha {
            arr << pix.red
            arr << pix.green
            arr << pix.blue
            arr << pix.alpha
        }
    }
    return arr
}

pub struct InternalPngFile {
pub mut:
	ihdr             IHDR
	stride           int
	channels         byte
	idat_chunks      []byte
	raw_bytes        []byte
	unfiltered_bytes []byte
	plte             []byte
	pixels           []Pixel
	pixel_type       PixelType
}

pub struct IHDR {
mut:
	width              int
	height             int
	bit_depth          byte
	color_type         byte
	compression_method byte
	filter_method      byte
	interlace_method   byte
}

pub struct Indexed {
pub mut:
	index byte
}

pub struct Grayscale {
pub mut:
	gray byte
}

pub struct GrayscaleAlpha {
pub mut:
	gray  byte
	alpha byte
}

pub struct TrueColor {
pub mut:
	red   byte
	green byte
	blue  byte
}

pub struct TrueColorAlpha {
pub mut:
	red   byte
	green byte
	blue  byte
	alpha byte
}
