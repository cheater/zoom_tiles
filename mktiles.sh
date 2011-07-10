#!/bin/bash

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# 1. resize

function get_dim {
    if ! [ -f "$1" ]; then
        echo "get_dim: file does not exist: \`$1'" >& 2
        return 1
        fi
    dim=$(convert "$1" -format "%$2" info:)
    if ! [ 0 -eq "$?" ]; then
        echo "get_dim: error when processing \`$1'" >& 2
        return 1
        fi
    echo "$dim"
    return 0
    }

function get_width {
    get_dim $1 "w"
    }

function get_height {
    get_dim $1 "h"
    }

function generate_sizes {
    # $1 - the starting size
    # $2 - the amount of steps
    # generate_sizes 200 4 -> 100 50 25 12
    if ! [ 0 -lt "$1" ]; then
        echo "generate_sizes: the first argument (image size) must be "\
            "a positive integer. Passed: \`$1'" >& 2
        return 1
        fi
    if ! [ 0 -lt "$2" ]; then
        echo "generate_sizes: the second argument (size steps) must be "\
            "a postiive integer. Passed: \`$2'" >& 2
        return 1
        fi
    for i in $(eval echo {0.."$2"}); do
        power_of_two=$((2**$i))
        echo $(($1 / $power_of_two))
        done
    }

function img_generate_size {
    # $1 - the image
    # $2 - the new width
    # $3 - the new file
    if ! [ -f "$1" ]; then
        echo "img_generate_size: file does not exist: \`$1'" >& 2
        return 1
        fi
    if ! [ 0 -lt "$2" ]; then
        echo "img_generate_size: the size needs to be positive. " \
            "Passed: \`$2'" >& 2
        return 1
        fi
    if [ -f "$3" ]; then
        echo "img_generate_size: overwriting \`$3'" >& 2
        fi
    convert "$1" -resize "$2" "$3"
    }

function img_generate_sizes {
    # $1 - the image
    # $2 - the amount of size reductions
    # $3 - the temp dir
    if ! [ 0 -lt "$2" ]; then
        echo "You have to pass a positive number of size-reductions to "\
            "function img_generate_sizes." >& 2
        return 1
        fi
    if ! [ -d "$3" ]; then
        echo "img_generate_sizes: not a directory: temporary directory path "\
            "\`$3'. " >& 2
        return 1
        fi
    i=0
    for w in $(generate_sizes $(get_width "$1") "$2"); do
        out="${3}/${i}.jpg"
        if ! img_generate_size $1 $w "$out"; then
            echo "Error when processing \`$1'"; >& 2
            return 1
            fi
        echo "$out"
        i=$(($i+1))
        done
    }

# 2. make tiles

function generate_tiles {
    convert "$1" -crop "${2}x${2}" "$3/$4.jpg"
    }

function img_generate_tiles {
    # $1 - the image
    # $2 - the amount of size reductions
    # $3 - the temp dir
    # $4 - the size of tiles horizontally and vertically
    # $5 - the output dir
    
    if ! [ 0 -lt "$4" ]; then
        echo "img_generate_tiles: the fourth argument, the tile size "\
            "horizontally and vertically, should be a positive integer. "\
            "Passed: \`$4'." >& 2
        return 1
        fi
    if ! [ -d "$5" ]; then
        echo "img_generate_tiles: not a directory: output directory \`$5'" >& 2
        return 1
        fi

    size=0;
    convert "$1" "$5/$size.jpg"
    for temp_img in $(img_generate_sizes "$1" "$2" "$3"); do
        if ! generate_tiles "$temp_img" "$4" "$5" "$size"; then
            echo "img_generate_tiles: error when processing \`$1'." >& 2
            return 1
            fi
        size=$(($size+1));
        done
    }

function help {
echo \
"Usage: ./mktiles.sh \"wild*card.ext\" amount_of_zoom_levels temp_dir
tile_size output_directory

The script will generate files of the form n-k.jpg where n = 1, 2, ...
is the zoom level and k = 0, 1, ... is the tile number.

Tile numbers work in the following way: the first tile is a square in
the top left corner, the next tile is tile_size pixels to the right,
and so on until the last tile that fits completely. The final tile in
the row is smaller, unless tile_size is an exact divisor of the image
width. Then the next tile starts in the next row, that is tile_size
pixels under the first tile.
"
    }

function license {
echo \
"
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
    }

function imgs_generate_tiles {
    # $1 - the images
    # $2 - the amount of size reductions
    # $3 - the temp dir
    # $4 - the size of tiles horizontally and vertically
    # $5 - the output dir
    for img in $1; do
        echo "imgs_generate_titles: $img" >& 2
        imgdir=$5/$img
        mkdir "$imgdir"
        img_generate_tiles "$img" "$2" "$3" "$4" "$imgdir"
        done
    rm -rf "$3/*"
}

license
help
imgs_generate_tiles "$1" "$2" "$3" "$4" "$5"
