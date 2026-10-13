#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging
require strings/strings

function binary.read_file {
	__verify_nr_args "$#" 1 binary.read_file
	local target
	target="$1"
	cat "$target"
}

# What a file is, found out by bash itself from its first bytes, the way
# file(1) does it: magic numbers for the formats, and for the rest a look at
# whether the bytes can be text. It sets
#   _binary_kind         missing, empty, elf, macho, pe, script, html, text, data,
#                        png, gif, jpeg, bmp, webp, tiff, pdf, gzip, bzip2, xz,
#                        zip, 7z or tar
#   _binary_description  a line in the style of file(1)
#   _binary_executable   1 when it is an executable of this machine
# Usage: binary._sniff <file>
function binary._sniff {
	local LC_ALL=C
	local fd hex size i byte pair char head_text first_line has_nul has_control has_high has_crlf previous
	_binary_kind="missing"
	_binary_description="cannot open"
	_binary_executable=0
	if [ ! -f "$1" ] || [ ! -r "$1" ]; then
		return 1
	fi
	if [ ! -s "$1" ]; then
		_binary_kind="empty"
		_binary_description="empty"
		return 0
	fi
	exec {fd}<"$1"
	__read_bytes_hex "$fd" 2048
	exec {fd}<&-
	hex="$__READ_HEX"
	size=$((${#hex} / 2))

	case "$hex" in
	7F454C46*)
		binary._sniff_elf "$hex" "$1"
		return 0
		;;
	CAFEBABE*)
		# A Mach-O universal binary lists a few architectures, a Java class its version, which is 45 or more
		if [ "$size" -ge 8 ] && [ $((16#${hex:8:8})) -lt 45 ]; then
			_binary_kind="macho"
			_binary_description="Mach-O universal binary"
		else
			_binary_kind="data"
			_binary_description="compiled Java class data"
		fi
		return 0
		;;
	FEEDFACE* | FEEDFACF* | CEFAEDFE* | CFFAEDFE*)
		_binary_kind="macho"
		_binary_description="Mach-O executable"
		return 0
		;;
	4D5A*)
		_binary_kind="pe"
		_binary_description="MS-DOS/Windows executable"
		return 0
		;;
	89504E470D0A1A0A*)
		_binary_kind="png"
		_binary_description="PNG image data"
		if [ "$size" -ge 24 ]; then
			_binary_description+=", $((16#${hex:32:8})) x $((16#${hex:40:8}))"
		fi
		return 0
		;;
	474946383761* | 474946383961*)
		_binary_kind="gif"
		_binary_description="GIF image data, version 8${hex:11:1}a"
		[ "${hex:11:1}" = "7" ] || _binary_description="GIF image data, version 89a"
		if [ "$size" -ge 10 ]; then
			_binary_description+=", $((16#${hex:14:2}${hex:12:2})) x $((16#${hex:18:2}${hex:16:2}))"
		fi
		return 0
		;;
	FFD8FF*)
		_binary_kind="jpeg"
		_binary_description="JPEG image data"
		if [ "${hex:12:8}" = "4A464946" ]; then
			printf -v char ', JFIF standard %d.%02d' $((16#${hex:22:2})) $((16#${hex:24:2}))
			_binary_description+="$char"
		fi
		return 0
		;;
	255044462D*)
		_binary_kind="pdf"
		_binary_description="PDF document"
		printf -v char '%b' "\\x${hex:10:2}\\x${hex:12:2}\\x${hex:14:2}"
		if [[ "$char" =~ ^[0-9]\.[0-9]$ ]]; then
			_binary_description+=", version $char"
		fi
		return 0
		;;
	1F8B*)
		_binary_kind="gzip"
		_binary_description="gzip compressed data"
		return 0
		;;
	425A68*)
		_binary_kind="bzip2"
		_binary_description="bzip2 compressed data"
		return 0
		;;
	FD377A585A00*)
		_binary_kind="xz"
		_binary_description="XZ compressed data"
		return 0
		;;
	504B0304* | 504B0506* | 504B0708*)
		_binary_kind="zip"
		_binary_description="Zip archive data"
		return 0
		;;
	377ABCAF271C*)
		_binary_kind="7z"
		_binary_description="7-zip archive data"
		return 0
		;;
	52494646????????57454250*)
		_binary_kind="webp"
		_binary_description="RIFF (little-endian) data, Web/P image"
		return 0
		;;
	49492A00* | 4D4D002A*)
		_binary_kind="tiff"
		_binary_description="TIFF image data"
		return 0
		;;
	esac
	# A bitmap starts with the two letters BM, which text can too: look at the header that follows
	if [[ "$hex" == 424D* ]] && [ "$size" -ge 18 ] && [ "${hex:12:8}" = "00000000" ]; then
		case "${hex:28:8}" in
		0C000000 | 28000000 | 38000000 | 40000000 | 6C000000 | 7C000000)
			_binary_kind="bmp"
			_binary_description="PC bitmap"
			return 0
			;;
		esac
	fi
	if [ "$size" -ge 262 ] && [ "${hex:514:10}" = "7573746172" ]; then
		_binary_kind="tar"
		_binary_description="POSIX tar archive"
		return 0
	fi

	# Text has no NUL and no control characters other than the usual ones
	has_nul=0
	has_control=0
	has_high=0
	has_crlf=0
	previous=0
	head_text=""
	for ((i = 0; i < size; i++)); do
		pair="${hex:i*2:2}"
		byte=$((16#$pair))
		if [ "$byte" -eq 0 ]; then
			has_nul=1
			break
		elif [ "$byte" -lt 32 ]; then
			case "$byte" in
			7 | 8 | 9 | 10 | 12 | 13 | 27) ;;
			*) has_control=1 ;;
			esac
			[ "$byte" -eq 10 ] && [ "$previous" -eq 13 ] && has_crlf=1
		elif [ "$byte" -eq 127 ]; then
			has_control=1
		elif [ "$byte" -ge 128 ]; then
			has_high=1
		fi
		if [ "$i" -lt 256 ]; then
			if [ "$byte" -ge 32 ] && [ "$byte" -lt 127 ]; then
				printf -v char '%b' "\\x$pair"
				head_text+="$char"
			elif [ "$byte" -eq 10 ]; then
				head_text+=$'\n'
			fi
		fi
		previous=$byte
	done
	if [ "$has_nul" -eq 1 ] || [ "$has_control" -eq 1 ]; then
		_binary_kind="data"
		_binary_description="data"
		return 0
	fi

	_binary_kind="text"
	if [ "$has_high" -eq 0 ]; then
		_binary_description="ASCII text"
	elif binary._valid_utf8 "$hex" "$size"; then
		_binary_description="UTF-8 Unicode text"
		[[ "$hex" == EFBBBF* ]] && _binary_description="UTF-8 Unicode (with BOM) text"
	else
		_binary_description="ISO-8859 text"
	fi
	[ "$has_crlf" -eq 1 ] && _binary_description+=", with CRLF line terminators"

	if [[ "$head_text" == '#!'* ]]; then
		_binary_kind="script"
		_binary_executable=1
		first_line="${head_text%%$'\n'*}"
		first_line="${first_line#'#!'}"
		first_line="${first_line#"${first_line%%[![:space:]]*}"}"
		_binary_description="a $first_line script, $_binary_description executable"
	elif [[ "${head_text,,}" =~ ^[[:space:]]*(\<\!doctype[[:space:]]+html|\<html|\<head|\<body) ]]; then
		_binary_kind="html"
		_binary_description="HTML document, $_binary_description"
	fi
	return 0
}

# Succeeds when the bytes are well formed UTF-8. When only the start of a long
# file was read, the last character may have been cut off, so up to three
# bytes at the end are given a chance to be left out.
# Usage: binary._valid_utf8 <hex> <bytes in it>
function binary._valid_utf8 {
	local hex trim
	local pattern='^(([0-7].)|(C[2-9A-F]|D.)[89AB].|E.[89AB].[89AB].|F[0-4][89AB].[89AB].[89AB].)*$'
	hex="$1"
	[[ "$hex" =~ $pattern ]] && return 0
	if [ "$2" -ge 2048 ]; then
		for trim in 2 4 6; do
			[[ "${hex:0:${#hex}-trim}" =~ $pattern ]] && return 0
		done
	fi
	return 1
}

# Reads the header of an ELF file into the _binary_ variables
# Usage: binary._sniff_elf <hex of the first bytes> <file>
function binary._sniff_elf {
	local hex bits order type machine machine_name type_name pie phoff phentsize phnum i offset size
	hex="$1"
	size=$((${#hex} / 2))
	_binary_kind="elf"
	if [ "$size" -lt 20 ]; then
		_binary_description="ELF, truncated"
		return 0
	fi
	case "${hex:8:2}" in
	01) bits=32 ;;
	02) bits=64 ;;
	*) bits="?" ;;
	esac
	case "${hex:10:2}" in
	01) order="LSB" ;;
	02) order="MSB" ;;
	*) order="?" ;;
	esac
	type=$(binary._elf_int "$hex" "$order" 16 2)
	machine=$(binary._elf_int "$hex" "$order" 18 2)
	case "$machine" in
	3) machine_name="Intel 80386" ;;
	8) machine_name="MIPS" ;;
	20) machine_name="PowerPC" ;;
	21) machine_name="64-bit PowerPC" ;;
	22) machine_name="IBM S/390" ;;
	40) machine_name="ARM" ;;
	62) machine_name="x86-64" ;;
	183) machine_name="ARM aarch64" ;;
	243) machine_name="UCB RISC-V" ;;
	*) machine_name="machine $machine" ;;
	esac
	pie=0
	case "$type" in
	1) type_name="relocatable" ;;
	2) type_name="executable" ;;
	3)
		# Shared objects are libraries and programs that are loaded anywhere (PIE). The
		# difference is a flag in the dynamic section, which is how file(1) tells them apart.
		type_name="shared object"
		if [ "$bits" = "64" ] && [ "$size" -ge 64 ]; then
			phoff=$(binary._elf_int "$hex" "$order" 32 8)
			phentsize=$(binary._elf_int "$hex" "$order" 54 2)
			phnum=$(binary._elf_int "$hex" "$order" 56 2)
		elif [ "$bits" = "32" ] && [ "$size" -ge 52 ]; then
			phoff=$(binary._elf_int "$hex" "$order" 28 4)
			phentsize=$(binary._elf_int "$hex" "$order" 42 2)
			phnum=$(binary._elf_int "$hex" "$order" 44 2)
		else
			phnum=0
		fi
		for ((i = 0; i < ${phnum:-0} && i < 64; i++)); do
			offset=$((phoff + i * phentsize))
			if [ $((offset + 4)) -gt "$size" ]; then
				break
			fi
			# Program header type 2 is the dynamic section
			if [ "$(binary._elf_int "$hex" "$order" "$offset" 4)" = "2" ]; then
				binary._elf_is_pie "$hex" "$order" "$bits" "$offset" "$2" && pie=1
				break
			fi
		done
		[ "$pie" -eq 1 ] && type_name="pie executable"
		;;
	4) type_name="core file" ;;
	*) type_name="type $type" ;;
	esac
	_binary_description="ELF $bits-bit $order $type_name, $machine_name"
	if [ "$type_name" = "executable" ] || [ "$pie" -eq 1 ]; then
		_binary_kind="elf"
		if [ "$machine" = "$(binary._host_machine)" ]; then
			_binary_executable=1
		fi
	else
		_binary_kind="elf_other"
	fi
}

# Succeeds when the dynamic section of an ELF file says it is a position
# independent executable (DT_FLAGS_1 has DF_1_PIE).
# Usage: binary._elf_is_pie <hex> <LSB or MSB> <32 or 64> <offset of the program header> <file>
function binary._elf_is_pie {
	local hex order bits header dyn_offset dyn_size entry_size fd dynamic i tag value
	hex="$1"
	order="$2"
	bits="$3"
	header="$4"
	if [ "$bits" = "64" ]; then
		dyn_offset=$(binary._elf_int "$hex" "$order" $((header + 8)) 8)
		dyn_size=$(binary._elf_int "$hex" "$order" $((header + 32)) 8)
		entry_size=16
	else
		dyn_offset=$(binary._elf_int "$hex" "$order" $((header + 4)) 4)
		dyn_size=$(binary._elf_int "$hex" "$order" $((header + 16)) 4)
		entry_size=8
	fi
	# Only a dynamic section of a sensible size, in the first 16 MiB, is looked at
	if [ "$dyn_size" -le 0 ] || [ "$dyn_size" -gt 8192 ] || [ "$dyn_offset" -gt 16777216 ]; then
		return 1
	fi
	exec {fd}<"$5"
	binary._skip_bytes "$fd" "$dyn_offset"
	__read_bytes_hex "$fd" "$dyn_size"
	exec {fd}<&-
	dynamic="$__READ_HEX"
	for ((i = 0; i + entry_size <= dyn_size; i += entry_size)); do
		tag=$(binary._elf_int "$dynamic" "$order" "$i" $((entry_size / 2)))
		value=$(binary._elf_int "$dynamic" "$order" $((i + entry_size / 2)) $((entry_size / 2)))
		# DT_NULL ends the section, 1879048187 is DT_FLAGS_1 and 134217728 is DF_1_PIE
		[ "$tag" = "0" ] && break
		if [ "$tag" = "1879048187" ]; then
			[ $((value & 134217728)) -ne 0 ]
			return
		fi
	done
	return 1
}

# Throws away the first bytes of a file that is open. The pieces end at a NUL
# and a NUL is not counted by a read of characters, so they are counted here.
# Usage: binary._skip_bytes <fd> <bytes>
function binary._skip_bytes {
	local LC_ALL=C
	local fd left piece step status
	fd="$1"
	left="$2"
	while [ "$left" -gt 0 ]; do
		step=$left
		[ "$step" -gt 1048576 ] && step=1048576
		IFS= read -r -d '' -n "$step" -u "$fd" piece
		status=$?
		left=$((left - ${#piece}))
		# A piece that is shorter than asked for was ended by a NUL, that is one more byte
		if [ "$status" -eq 0 ] && [ ${#piece} -lt "$step" ]; then
			left=$((left - 1))
		elif [ "$status" -ne 0 ]; then
			return 1
		fi
	done
}

# Prints the number of bytes at an offset in the header of an ELF file
# Usage: binary._elf_int <hex> <LSB or MSB> <offset in bytes> <bytes>
function binary._elf_int {
	local hex digits i
	hex="$1"
	digits=""
	if [ "$2" = "LSB" ]; then
		for ((i = $4 - 1; i >= 0; i--)); do
			digits+="${hex:($3 + i)*2:2}"
		done
	else
		digits="${hex:$3*2:$4*2}"
	fi
	echo $((16#${digits:-0}))
}

# Prints the number of the ELF machine that this bash runs on, from the type of
# machine that bash itself knows it was made for
function binary._host_machine {
	case "$HOSTTYPE" in
	x86_64) echo 62 ;;
	aarch64 | arm64) echo 183 ;;
	arm*) echo 40 ;;
	i?86) echo 3 ;;
	riscv*) echo 243 ;;
	powerpc64*) echo 21 ;;
	powerpc*) echo 20 ;;
	s390x) echo 22 ;;
	mips*) echo 8 ;;
	*) echo 0 ;;
	esac
}

function binary.is_text {
	__verify_nr_args "$#" 1 binary.is_text
	binary._sniff "$1"
	[[ "$_binary_kind" == text || "$_binary_kind" == html || "$_binary_kind" == script ]]
}

function binary.is_printable {
	__verify_nr_args "$#" 1 binary.is_printable
	binary.is_text "$1"
}

function binary.is_html {
	__verify_nr_args "$#" 1 binary.is_html
	binary._sniff "$1"
	[ "$_binary_kind" = "html" ]
}

# An executable file format: ELF programs, Mach-O and PE. A library is not one,
# and neither is a script, that is text.
function binary.is_binary {
	__verify_nr_args "$#" 1 binary.is_binary
	binary._sniff "$1"
	[[ "$_binary_kind" == elf || "$_binary_kind" == macho || "$_binary_kind" == pe ]]
}

function binary.is_pdf {
	__verify_nr_args "$#" 1 binary.is_pdf
	binary._sniff "$1"
	[ "$_binary_kind" = "pdf" ]
}

function binary.is_jpeg {
	__verify_nr_args "$#" 1 binary.is_jpeg
	binary._sniff "$1"
	[ "$_binary_kind" = "jpeg" ]
}

function binary.is_png {
	__verify_nr_args "$#" 1 binary.is_png
	binary._sniff "$1"
	[ "$_binary_kind" = "png" ]
}

function binary.is_gif {
	__verify_nr_args "$#" 1 binary.is_gif
	binary._sniff "$1"
	[ "$_binary_kind" = "gif" ]
}

function binary.is_image {
	__verify_nr_args "$#" 1 binary.is_image
	binary._sniff "$1"
	[[ "$_binary_kind" == png || "$_binary_kind" == gif || "$_binary_kind" == jpeg || "$_binary_kind" == bmp || "$_binary_kind" == webp || "$_binary_kind" == tiff ]]
}

# A script, or a program for the machine that this bash runs on
function binary.is_executable {
	__verify_nr_args "$#" 1 binary.is_executable
	binary._sniff "$1"
	[ "$_binary_executable" -eq 1 ]
}

# Prints what kind of file it is, in the style of file(1)
function binary.get_file_type {
	__verify_nr_args "$#" 1 binary.get_file_type
	local status
	binary._sniff "$1"
	status=$?
	echo "$_binary_description"
	return "$status"
}

function binary.write_file {
	__verify_nr_args "$#" 2 binary.write_file
	local content target
	content="$1"
	target="$2"
	echo "$content" >"$target"
}

function binary.append_file {
	__verify_nr_args "$#" 2 binary.append_file
	local content target
	content="$1"
	target="$2"
	echo "$content" >>"$target"
}

function binary.extract_strings {
	__verify_nr_args "$#" 1 binary.extract_strings
	local target content
	target="$1"
	content=""
	if binary.is_binary "$target"; then
		if __command_exists "strings"; then
			content="$(strings $target)"
		else
			logging.warning "[strings] command does not exist, cannot extract strings from $target"
		fi
	else
		logging.warning "$target is not a binary file"
	fi
	echo "$content"
}

function binary.hexdump {
	__verify_nr_args "$#" 1 binary.hexdump
	local target content
	target="$1"
	content=""
	if binary.is_binary "$target"; then
		if __command_exists "xxd"; then
			content="$(xxd $target)"
		elif __command_exists "hexdump"; then
			content="$(hexdump $target)"
		else
			logging.warning "[xxd, hexdump] commands do not exist, cannot create hexdump from $target"
		fi
	else
		logging.warning "$target is not a binary file"
	fi
	echo "$content"
}

function binary.random_bytes {
	__verify_nr_args "$#" 1 binary.random_bytes
	local size content
	size="$1"
	content="$(head -c "$size" </dev/urandom | tr -d '\0')"
	echo "$content"
}

function binary.write_file_void {
	__verify_nr_args "$#" 1 binary.write_file_void
	local content
	content="$1"
	binary.write_file "$content" /dev/null
}

function binary.append_file_void {
	__verify_nr_args "$#" 1 binary.append_file_void
	local content
	content="$1"
	binary.append_file "$content" /dev/null
}

function binary.print {
	__verify_nr_args "$#" 1 binary.print
	local content
	content="$1"
	echo "$content" >&1
}

function binary.print_error {
	__verify_nr_args "$#" 1 binary.print_error
	local content
	content="$1"
	echo "$content" 1>&2
}
