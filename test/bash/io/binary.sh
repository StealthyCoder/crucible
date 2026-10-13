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
tests+=("io.binary.get_file_type")
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
