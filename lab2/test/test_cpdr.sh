#!/bin/bash
TEST_BIN="cpdr"
TEST_SRC="test_src"
TEST_DST="test_dst"

# Disable umask so permissions are set exactly as specified
umask 0000

# Cleanup any previous test artifacts
rm -rf "$TEST_SRC" "$TEST_DST"

# Create a complex test directory structure
mkdir -p "$TEST_SRC/dir1/dir2/dir3"
echo "Test file A" > "$TEST_SRC/fileA.txt"
echo "Test file B" > "$TEST_SRC/dir1/fileB.txt"
echo "Test file C" > "$TEST_SRC/dir1/dir2/fileC.txt"
echo "Test file D" > "$TEST_SRC/dir1/dir2/dir3/fileD.txt"
mkdir -p "$TEST_SRC/dir1/dir2_empty"
mkdir -p "$TEST_SRC/dir1_empty"

# Create files with different permissions
echo "Executable file" > "$TEST_SRC/executable.sh"
chmod 755 "$TEST_SRC/executable.sh"
echo "Read-only file" > "$TEST_SRC/readonly.txt"
chmod 444 "$TEST_SRC/readonly.txt"

echo "Hidden file" > "$TEST_SRC/.hidden_file"
chmod 600 "$TEST_SRC/.hidden_file"

echo "Restricted file" > "$TEST_SRC/dir1/restricted.txt"
chmod 640 "$TEST_SRC/dir1/restricted.txt"

# Set directory permissions
chmod 700 "$TEST_SRC/dir1/dir2"
chmod 755 "$TEST_SRC/dir1"
chmod 777 "$TEST_SRC/dir1/dir2/dir3"
chmod 500 "$TEST_SRC/dir1_empty"
chmod 555 "$TEST_SRC/dir1/dir2_empty"

# Compile the program if necessary
gcc -o $TEST_BIN $TEST_BIN.c
if [ $? -ne 0 ]; then
	echo "ERROR: Compilation failed."
	exit 1
fi

# Run the program
./$TEST_BIN "$TEST_SRC" "$TEST_DST"
if [ $? -ne 0 ]; then
	echo "ERROR: Program execution failed!"
	exit 1
fi

# Verify the results
for file in "$TEST_SRC/fileA.txt" "$TEST_SRC/dir1/fileB.txt" "$TEST_SRC/dir1/dir2/fileC.txt" "$TEST_SRC/dir1/dir2/dir3/fileD.txt" "$TEST_SRC/executable.sh" "$TEST_SRC/readonly.txt" "$TEST_SRC/.hidden_file" "$TEST_SRC/dir1/restricted.txt"; do
	dst_file="${file/$TEST_SRC/$TEST_DST}"
	if [ ! -f "$dst_file" ]; then
		echo "FAILED: $dst_file was not copied"
		exit 1
	fi

	src_perm=$(stat -c "%a" "$file")
	dst_perm=$(stat -c "%a" "$dst_file")
	if [ "$src_perm" != "$dst_perm" ]; then
		echo "FAILED: Permissions for $dst_file do not match"
		exit 1
	fi
done

for dir in "$TEST_SRC/dir1" "$TEST_SRC/dir1/dir2" "$TEST_SRC/dir1/dir2/dir3" "$TEST_SRC/dir1_empty" "$TEST_SRC/dir1/dir2_empty"; do
	dst_dir="${dir/$TEST_SRC/$TEST_DST}"
	if [ ! -d "$dst_dir" ]; then
		echo "FAILED: Directory $dst_dir was not copied"
		exit 1
	fi

	src_perm=$(stat -c "%a" "$dir")
	dst_perm=$(stat -c "%a" "$dst_dir")
	if [ "$src_perm" != "$dst_perm" ]; then
		echo "FAILED: Permissions for directory $dst_dir do not match"
		exit 1
	fi

	if [ -z "$(ls -A "$dst_dir")" ] && [ -n "$(ls -A "$dir")" ]; then
		echo "FAILED: Directory $dst_dir should not be empty"
		exit 1
	fi
done

echo "SUCCESS: All tests passed!"
exit 0
