#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/io/binary -p
cd tmp/io/binary || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require io/binary/binary

declare -a tests

tests=("io.binary.fixtures")
tests+=("io.binary.read_file" "io.binary.write_and_append_file")
tests+=("io.binary.is_text" "io.binary.is_printable")
tests+=("io.binary.is_binary" "io.binary.is_executable")
tests+=("io.binary.is_html" "io.binary.is_pdf")
tests+=("io.binary.is_png" "io.binary.is_jpeg" "io.binary.is_gif")
tests+=("io.binary.is_image")
tests+=("io.binary.get_file_type" "io.binary.file_types" "io.binary.elf" "io.binary.text_variants")
tests+=("io.binary.large_file" "io.binary.not_a_file" "io.binary.without_file_command")
tests+=("io.binary.extract_strings" "io.binary.hexdump")
tests+=("io.binary.random_bytes")
tests+=("io.binary.print")
# The safe variants replace the functions above, so they have to come last
tests+=("io.binary.safe.read_file" "io.binary.safe.write_file")
tests+=("io.binary.safe.random_bytes")

function io.binary.fixtures {
    intro "Creating fixtures"
    echo "just some text" >plain.txt
    printf '#!/usr/bin/env bash\necho hi\n' >script.sh
    printf '<!DOCTYPE html>\n<html><head><title>t</title></head><body>hi</body></html>\n' >page.html
    printf '%%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%%%EOF\n' >doc.pdf
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89' >pic.png
    printf 'GIF89a\x01\x00\x01\x00\x00\x00\x00;' >pic.gif
    printf '\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xff\xd9' >pic.jpg
    cp "$(command -v ls)" program
    success
}

function io.binary.read_file {
    intro "io.binary.read_file"
    assert_equals "just some text" "$(binary.read_file plain.txt)" "read_file"
    success
}

function io.binary.write_and_append_file {
    intro "io.binary.write_file, append_file and the void variants"
    binary.write_file "first" out.txt
    assert_equals "first" "$(cat out.txt)" "write_file"
    binary.write_file "second" out.txt
    assert_equals "second" "$(cat out.txt)" "write_file overwrites"
    binary.append_file "third" out.txt
    assert_equals "second
third" "$(cat out.txt)" "append_file"
    binary.write_file_void "nothing"
    binary.append_file_void "nothing"
    rm out.txt
    success
}

function io.binary.is_text {
    intro "io.binary.is_text"
    assert_true "plain text is text" binary.is_text plain.txt
    assert_true "html is text" binary.is_text page.html
    assert_false "an elf binary is not text" binary.is_text program
    assert_false "a png is not text" binary.is_text pic.png
    success
}

function io.binary.is_printable {
    intro "io.binary.is_printable"
    assert_true "plain text is printable" binary.is_printable plain.txt
    assert_false "an elf binary is not printable" binary.is_printable program
    success
}

function io.binary.is_binary {
    intro "io.binary.is_binary"
    assert_true "an elf binary is binary" binary.is_binary program
    assert_false "plain text is not binary" binary.is_binary plain.txt
    success
}

function io.binary.is_executable {
    intro "io.binary.is_executable"
    assert_true "an elf binary is executable" binary.is_executable program
    assert_true "a script is executable" binary.is_executable script.sh
    assert_false "plain text is not executable" binary.is_executable plain.txt
    assert_false "a png is not executable" binary.is_executable pic.png
    success
}

function io.binary.is_html {
    intro "io.binary.is_html"
    assert_true "html is html" binary.is_html page.html
    assert_false "plain text is not html" binary.is_html plain.txt
    success
}

function io.binary.is_pdf {
    intro "io.binary.is_pdf"
    assert_true "a pdf is a pdf" binary.is_pdf doc.pdf
    assert_false "plain text is not a pdf" binary.is_pdf plain.txt
    success
}

function io.binary.is_png {
    intro "io.binary.is_png"
    assert_true "a png is a png" binary.is_png pic.png
    assert_false "a gif is not a png" binary.is_png pic.gif
    success
}

function io.binary.is_jpeg {
    intro "io.binary.is_jpeg"
    assert_true "a jpeg is a jpeg" binary.is_jpeg pic.jpg
    assert_false "a png is not a jpeg" binary.is_jpeg pic.png
    success
}

function io.binary.is_gif {
    intro "io.binary.is_gif"
    assert_true "a gif is a gif" binary.is_gif pic.gif
    assert_false "a png is not a gif" binary.is_gif pic.png
    success
}

function io.binary.is_image {
    intro "io.binary.is_image"
    assert_true "a png is an image" binary.is_image pic.png
    assert_true "a gif is an image" binary.is_image pic.gif
    assert_true "a jpeg is an image" binary.is_image pic.jpg
    assert_false "plain text is not an image" binary.is_image plain.txt
    success
}

function io.binary.get_file_type {
    intro "io.binary.get_file_type"
    assert_equals "ASCII text" "$(binary.get_file_type plain.txt)" "type of plain text"
    binary.get_file_type pic.png | grep -q '^PNG image data' || fail "type of a png"
    success
}

function io.binary.file_types {
    intro "io.binary.get_file_type describes what a file is"
    printf '\xef\xbb\xbfwith bom\n' >bom.txt
    printf 'dos line\r\nendings\r\n' >crlf.txt
    printf 'caf\xc3\xa9 \xe2\x9c\x93\n' >utf8.txt
    printf 'caf\xe9 latin one\n' >latin1.txt
    printf 'text\x00with a nul' >nul.bin
    printf 'bell\x01control' >control.bin
    : >empty.txt
    printf 'BMW is a car brand\n' >bmw.txt
    printf 'BM\x36\x00\x00\x00\x00\x00\x00\x00\x36\x00\x00\x00\x28\x00\x00\x00' >pic.bmp
    printf '\x1f\x8b\x08\x00\x00\x00\x00\x00' >data.gz
    printf 'PK\x03\x04\x14\x00\x00\x00' >data.zip
    printf 'BZh91AY&SY' >data.bz2
    printf '\xfd7zXZ\x00\x00\x04' >data.xz
    printf 'RIFF\x24\x00\x00\x00WEBPVP8 ' >pic.webp
    printf 'II*\x00\x08\x00\x00\x00' >pic.tif
    printf '<HTML><BODY>shouting</BODY></HTML>\n' >upper.html
    printf '  \n<!doctype html>\n<p>indented</p>\n' >indented.html
    printf 'this is not <html> at the start\n' >notweb.txt
    head -c 257 /dev/zero >ustar.tar
    printf 'ustar\x0000' >>ustar.tar
    head -c 300 /dev/zero >>ustar.tar
    assert_equals "ASCII text" "$(binary.get_file_type plain.txt)" "plain text"
    assert_equals "UTF-8 Unicode text" "$(binary.get_file_type utf8.txt)" "utf-8"
    assert_equals "UTF-8 Unicode (with BOM) text" "$(binary.get_file_type bom.txt)" "utf-8 with a bom"
    assert_equals "ISO-8859 text" "$(binary.get_file_type latin1.txt)" "latin 1 is not utf-8"
    assert_equals "ASCII text, with CRLF line terminators" "$(binary.get_file_type crlf.txt)" "dos line endings"
    assert_equals "data" "$(binary.get_file_type nul.bin)" "a nul byte in the first bytes"
    assert_equals "data" "$(binary.get_file_type control.bin)" "a control character"
    assert_equals "empty" "$(binary.get_file_type empty.txt)" "empty file"
    assert_equals "ASCII text" "$(binary.get_file_type bmw.txt)" "text that starts with BM is not a bitmap"
    assert_equals "PC bitmap" "$(binary.get_file_type pic.bmp)" "a real bitmap"
    assert_equals "HTML document, ASCII text" "$(binary.get_file_type page.html)" "html"
    assert_equals "HTML document, ASCII text" "$(binary.get_file_type upper.html)" "html in capitals"
    assert_equals "HTML document, ASCII text" "$(binary.get_file_type indented.html)" "html after a blank line"
    assert_equals "ASCII text" "$(binary.get_file_type notweb.txt)" "html in the middle of text"
    assert_equals "a /usr/bin/env bash script, ASCII text executable" "$(binary.get_file_type script.sh)" "script"
    assert_equals "PDF document, version 1.4" "$(binary.get_file_type doc.pdf)" "pdf"
    assert_equals "PNG image data, 1 x 1" "$(binary.get_file_type pic.png)" "png with its size"
    assert_equals "GIF image data, version 89a, 1 x 1" "$(binary.get_file_type pic.gif)" "gif with its size"
    assert_equals "JPEG image data, JFIF standard 1.01" "$(binary.get_file_type pic.jpg)" "jpeg"
    assert_equals "gzip compressed data" "$(binary.get_file_type data.gz)" "gzip"
    assert_equals "Zip archive data" "$(binary.get_file_type data.zip)" "zip"
    assert_equals "bzip2 compressed data" "$(binary.get_file_type data.bz2)" "bzip2"
    assert_equals "XZ compressed data" "$(binary.get_file_type data.xz)" "xz"
    assert_equals "RIFF (little-endian) data, Web/P image" "$(binary.get_file_type pic.webp)" "webp"
    assert_equals "TIFF image data" "$(binary.get_file_type pic.tif)" "tiff"
    assert_equals "POSIX tar archive" "$(binary.get_file_type ustar.tar)" "tar"
    assert_true "bitmap is an image" binary.is_image pic.bmp
    assert_true "webp is an image" binary.is_image pic.webp
    assert_true "tiff is an image" binary.is_image pic.tif
    assert_false "gzip is no image" binary.is_image data.gz
    assert_true "utf-8 is text" binary.is_text utf8.txt
    assert_true "latin 1 is text" binary.is_text latin1.txt
    assert_false "a nul makes data" binary.is_text nul.bin
    assert_false "empty is not text" binary.is_text empty.txt
    assert_true "html is text too" binary.is_text page.html
    assert_false "text is not html" binary.is_html notweb.txt
    assert_true "capitals html" binary.is_html upper.html
    success
}

function io.binary.elf {
    intro "io.binary: ELF programs, libraries and the machine they are for"
    local mine other
    case "$HOSTTYPE" in
    x86_64)
        mine=62
        other=183
        ;;
    aarch64)
        mine=183
        other=62
        ;;
    *)
        mine=0
        other=62
        ;;
    esac
    # A program for this machine, a program for another, a shared library, an object file
    { printf '\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00'; printf "\\x02\\x00\\x$(printf '%02x' "$mine")\\x00"; head -c 44 /dev/zero; } >mine.elf
    { printf '\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00'; printf "\\x02\\x00\\x$(printf '%02x' "$other")\\x00"; head -c 44 /dev/zero; } >other.elf
    { printf '\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00'; printf "\\x03\\x00\\x$(printf '%02x' "$mine")\\x00"; head -c 44 /dev/zero; } >lib.elf
    { printf '\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00'; printf "\\x01\\x00\\x$(printf '%02x' "$mine")\\x00"; head -c 44 /dev/zero; } >object.elf
    # A program that is loaded anywhere (PIE) is a shared object whose dynamic section has the flag
    # DF_1_PIE in DT_FLAGS_1, a library that can be run has an interpreter but not that flag.
    # The header of 64 bytes field by field, one program header of type 2 (dynamic) that
    # points at the 32 bytes after it, and the entries of the dynamic section.
    local flag
    for flag in pie lib-with-interpreter; do
        {
            printf '\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00'
            printf "\\x03\\x00\\x$(printf '%02x' "$mine")\\x00"
            printf '\x01\x00\x00\x00'
            head -c 8 /dev/zero
            printf '\x40\x00\x00\x00\x00\x00\x00\x00'
            head -c 8 /dev/zero
            head -c 4 /dev/zero
            printf '\x40\x00\x38\x00\x01\x00'
            head -c 6 /dev/zero
            printf '\x02\x00\x00\x00\x00\x00\x00\x00'
            printf '\x78\x00\x00\x00\x00\x00\x00\x00'
            head -c 16 /dev/zero
            printf '\x20\x00\x00\x00\x00\x00\x00\x00'
            head -c 16 /dev/zero
            printf '\xfb\xff\xff\x6f\x00\x00\x00\x00'
            if [ "$flag" = "pie" ]; then
                printf '\x00\x00\x00\x08\x00\x00\x00\x00'
            else
                printf '\x00\x00\x00\x00\x00\x00\x00\x00'
            fi
            head -c 16 /dev/zero
        } >"$flag.elf"
    done
    # Big endian and 32 bits
    { printf '\x7fELF\x01\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00'; printf '\x00\x02\x00\x14'; head -c 44 /dev/zero; } >ppc.elf
    binary.get_file_type mine.elf | grep -q '^ELF 64-bit LSB executable, ' || fail "description of a program: $(binary.get_file_type mine.elf)"
    binary.get_file_type lib.elf | grep -q '^ELF 64-bit LSB shared object, ' || fail "description of a library: $(binary.get_file_type lib.elf)"
    binary.get_file_type pie.elf | grep -q '^ELF 64-bit LSB pie executable, ' || fail "description of a pie: $(binary.get_file_type pie.elf)"
    binary.get_file_type lib-with-interpreter.elf | grep -q '^ELF 64-bit LSB shared object, ' || fail "description of a library that can be run: $(binary.get_file_type lib-with-interpreter.elf)"
    binary.get_file_type object.elf | grep -q '^ELF 64-bit LSB relocatable, ' || fail "description of an object file: $(binary.get_file_type object.elf)"
    assert_equals "ELF 32-bit MSB executable, PowerPC" "$(binary.get_file_type ppc.elf)" "big endian, 32 bits"
    assert_true "a program is binary" binary.is_binary mine.elf
    assert_true "a program for another machine is binary" binary.is_binary other.elf
    assert_true "a pie is binary" binary.is_binary pie.elf
    assert_false "a library is not" binary.is_binary lib.elf
    assert_false "a library that has an interpreter is not either" binary.is_binary lib-with-interpreter.elf
    assert_false "an object file is not" binary.is_binary object.elf
    if [ "$mine" != "0" ]; then
        assert_true "a program for this machine is executable" binary.is_executable mine.elf
        assert_true "a pie for this machine is executable" binary.is_executable pie.elf
    fi
    assert_false "a program for another machine is not" binary.is_executable other.elf
    assert_false "a library is not executable" binary.is_executable lib.elf
    assert_false "text is not executable" binary.is_executable plain.txt
    assert_true "a script is" binary.is_executable script.sh
    assert_false "an elf is not text" binary.is_text mine.elf
    rm -f mine.elf other.elf lib.elf lib-with-interpreter.elf object.elf pie.elf ppc.elf
    success
}

function io.binary.text_variants {
    intro "io.binary: text that is cut at the end of what is read"
    local i
    # 3 byte characters: 2048 is not a multiple of 3, the last one is cut in two
    for ((i = 0; i < 1500; i++)); do printf '\xe2\x9c\x93'; done >cut.txt
    assert_equals "UTF-8 Unicode text" "$(binary.get_file_type cut.txt)" "a character that is cut by the end of the read"
    # Text where bytes are bad in the middle is not utf-8
    { head -c 100 plain.txt; printf '\xff\xfe'; head -c 100 plain.txt; } >bad-utf8.txt
    assert_equals "ISO-8859 text" "$(binary.get_file_type bad-utf8.txt)" "invalid utf-8"
    # A nul further than the bytes that are looked at does not make it data
    { head -c 3000 /dev/zero | tr '\0' 'a'; printf '\x00'; } >late-nul.txt
    assert_true "a nul after the first 2048 bytes" binary.is_text late-nul.txt
    rm cut.txt bad-utf8.txt late-nul.txt
    success
}

function io.binary.large_file {
    intro "io.binary: a large file is not read as a whole"
    local start
    head -c 5242880 /dev/zero | tr '\0' 'x' >large.txt
    start=$SECONDS
    assert_equals "ASCII text" "$(binary.get_file_type large.txt)" "large text file"
    test $((SECONDS - start)) -le 2 || fail "Looking at a file of 5 MB took $((SECONDS - start)) seconds"
    head -c 5242880 /dev/urandom >large.bin
    start=$SECONDS
    assert_equals "data" "$(binary.get_file_type large.bin)" "large file with random bytes"
    test $((SECONDS - start)) -le 2 || fail "Looking at a file of 5 MB took $((SECONDS - start)) seconds"
    rm large.txt large.bin
    success
}

function io.binary.not_a_file {
    intro "io.binary: what is not a file"
    mkdir adirectory
    local function_name
    for function_name in is_text is_printable is_html is_binary is_pdf is_jpeg is_png is_gif is_image is_executable; do
        assert_false "$function_name of a directory" quietly "binary.$function_name" adirectory
        assert_false "$function_name of a file that is not there" quietly "binary.$function_name" missing.file
    done
    binary.get_file_type missing.file >type.txt
    test $? -ne 0 || fail "get_file_type of a missing file should fail"
    assert_equals "cannot open" "$(cat type.txt)" "description of a missing file"
    rm -r adirectory type.txt
    success
}

function io.binary.without_file_command {
    intro "io.binary does not need file(1)"
    local saved
    saved="$PATH"
    # A path without any of the usual directories: only builtins are left
    # shellcheck disable=SC2123
    PATH=/nonexistent
    binary.get_file_type pic.png >type.txt
    PATH="$saved"
    assert_equals "PNG image data, 1 x 1" "$(cat type.txt)" "type found without any command"
    rm type.txt
    success
}

function io.binary.extract_strings {
    intro "io.binary.extract_strings"
    test -n "$(binary.extract_strings program)" || fail "No strings extracted from a binary"
    assert_equals "" "$(binary.extract_strings plain.txt 2>/dev/null)" "strings of a text file"
    success
}

function io.binary.hexdump {
    intro "io.binary.hexdump"
    binary.hexdump program | head -n 1 | grep -qiE '7f45 4c46|457f 464c' || fail "No elf magic in the hexdump"
    assert_equals "" "$(binary.hexdump plain.txt 2>/dev/null)" "hexdump of a text file"
    success
}

function io.binary.random_bytes {
    intro "io.binary.random_bytes"
    test -n "$(binary.random_bytes 64)" || fail "No random bytes returned"
    test "$(binary.random_bytes 64)" != "$(binary.random_bytes 64)" || fail "Random bytes are not random"
    success
}

function io.binary.print {
    intro "io.binary.print and print_error"
    assert_equals "out" "$(binary.print out 2>/dev/null)" "print goes to stdout"
    assert_equals "" "$(binary.print_error err 2>/dev/null)" "print_error stays off stdout"
    assert_equals "err" "$(binary.print_error err 2>&1 >/dev/null)" "print_error goes to stderr"
    success
}

function io.binary.safe.read_file {
    intro "io.binary.safe.read_file"
    require io/binary/safe
    assert_equals "just some text" "$(binary.read_file plain.txt)" "read a text file"
    assert_equals "" "$(binary.read_file program)" "a binary must not be dumped"
    assert_equals "" "$(binary.read_file missing.txt)" "a missing file reads as empty"
    success
}

function io.binary.safe.write_file {
    intro "io.binary.safe.write_file"
    binary.write_file "first" safe.txt
    binary.write_file "second" safe.txt
    assert_equals "first" "$(cat safe.txt)" "an existing file must not be overwritten"
    rm safe.txt
    success
}

function io.binary.safe.random_bytes {
    intro "io.binary.safe.random_bytes"
    test -n "$(binary.random_bytes 1K)" || fail "1K should be allowed"
    test -n "$(binary.random_bytes 64)" || fail "64 bytes should be allowed"
    assert_equals "" "$(binary.random_bytes 20480K 2>/dev/null)" "20480K is too large"
    assert_equals "" "$(binary.random_bytes lots 2>/dev/null)" "lots is not a size"
    success
}

echo "Testing io/binary/binary"

for test in "${tests[@]}"; do
    "$test"
done

teardown
