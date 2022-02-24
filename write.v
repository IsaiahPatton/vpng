module vpng

import os
import compress.zlib

pub fn (png PngFile) get_bytes() []byte {
    mut file_bytes := []byte{}
	signature(mut file_bytes)
	write_chunks(mut file_bytes, png)
    return file_bytes
}

pub fn (png PngFile) get_bytes_() []byte {
    mut file_bytes := []byte{}
	//signature(mut file_bytes)
	write_chunks_(mut file_bytes, png)
    return file_bytes
}

fn write_(png PngFile, filename string) {
	mut file_bytes := []byte{}
	signature(mut file_bytes)
	write_chunks(mut file_bytes, png)
	os.write_file(filename, file_bytes.bytestr()) or {
		println('Error writing file $err')
	}
}

fn signature(mut file_bytes []byte) {
	file_bytes << png_signature
}

fn ihdr_chunk(mut file_bytes []byte, mut cs CRC, png PngFile) {
	mut ihdr_bytes := [byte(`I`), `H`, `D`, `R`]
	ihdr_bytes << int_to_bytes(png.width) // WIDTH
	ihdr_bytes << int_to_bytes(png.height) // HEIGHT
	ihdr_bytes << png.ihdr.bit_depth // BIT DEPTH
	ihdr_bytes << png.ihdr.color_type // COLOR TYPE
	ihdr_bytes << png.ihdr.compression_method // Compression Method
	ihdr_bytes << png.ihdr.filter_method // Filter Method
	ihdr_bytes << png.ihdr.interlace_method // Interlace Method
	len_bytes := int_to_bytes(ihdr_bytes.len - 4)
	crc_bytes := int_to_bytes(int(cs.crc(ihdr_bytes, ihdr_bytes.len)))
	file_bytes << len_bytes
	file_bytes << ihdr_bytes
	file_bytes << crc_bytes
}

fn iend_chunk(mut file_bytes []byte, mut cs CRC) {
	iend_bytes := [byte(`I`), `E`, `N`, `D`]
	file_bytes << int_to_bytes(0)
	file_bytes << iend_bytes
	file_bytes << int_to_bytes(int(cs.crc(iend_bytes, iend_bytes.len)))
}

fn idat_chunk(mut file_bytes []byte, mut cs CRC, png PngFile) {
	mut idat_bytes := []byte{}
	for y in 0..png.height {
		idat_bytes << 0
		for x in 0..png.width {
			pix := png.pixels[y * png.width + x]
			match pix {
				TrueColor {
					idat_bytes << pix.red
					idat_bytes << pix.green
					idat_bytes << pix.blue
				}
				TrueColorAlpha {
					idat_bytes << pix.red
					idat_bytes << pix.green
					idat_bytes << pix.blue
					idat_bytes << pix.alpha
				}
				Indexed {
					idat_bytes << pix.index
				}
				else {}
			}
		}
	}

	out_len := idat_bytes.len + idat_bytes.len * 2
    
    mut out_ := zlib.compress(idat_bytes) or { panic(err) } 
    mut out := []byte{len: out_len+1}
    
    mut val := 0
    for b in out_ {
        out[val] = b
        val += 1
    }

	mut out_bytes := [byte(`I`), `D`, `A`, `T`]
	mut max := 0
	for i := out_len; i > 0; i-- {
		unsafe {
			if int(out[i]) != 0 {
				max = i + 1
				max += 4 - (max % 3)
				break
			}
		}
	}
	for i in 0 .. (max) {
		unsafe {
			out_bytes << byte(out[i])
		}
	}
	file_bytes << int_to_bytes(out_bytes.len - 4)
	file_bytes << out_bytes
	file_bytes << int_to_bytes(int(cs.crc(out_bytes, out_bytes.len)))
}

fn plte_chunk(mut file_bytes []byte, mut cs CRC, png PngFile) {
	if png.pixel_type != PixelType.indexed {
		return
	}
	mut out_bytes := [byte(`P`), `L`, `T`, `E`]
	for i in 0 .. png.palette.len {
		out_bytes << [png.palette[i].red]
		out_bytes << [png.palette[i].green]
		out_bytes << [png.palette[i].blue]
	}
	file_bytes << int_to_bytes(out_bytes.len - 4)
	file_bytes << out_bytes
	file_bytes << int_to_bytes(int(cs.crc(out_bytes, out_bytes.len)))
}

fn write_chunks(mut file_bytes []byte, png PngFile) {
	mut cs := CRC{}
	ihdr_chunk(mut file_bytes, mut cs, png)
	plte_chunk(mut file_bytes, mut cs, png)
	idat_chunk(mut file_bytes, mut cs, png)
	iend_chunk(mut file_bytes, mut cs)
}

fn write_chunks_(mut file_bytes []byte, png PngFile) {
	mut cs := CRC{}
	//ihdr_chunk(mut file_bytes, mut cs, png)
	//plte_chunk(mut file_bytes, mut cs, png)
	idat_chunk(mut file_bytes, mut cs, png)
	//iend_chunk(mut file_bytes, mut cs)
}