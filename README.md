# makeindex.sh

Creates a structured index of a directory tree in JSON format

`makeindex.sh` is a Bash script that scans the contents of a given directory and generates a JSON file describing the full structure (files and subdirectories) of that directory tree. Each file entry includes metadata such as file name, type, extension, size (in human-readable units), relative path, and last modification date. Directory entries are represented as nested JSON objects.

The script is useful for creating an index of files for web-based file explorers, backup tools, or directory reporting utilities.

## Features

* Recursively scans all files and subdirectories in a given folder.
* Ignores files and folders starting with `.` or `~`.
* Excludes the output JSON file from the index.
* Outputs file sizes as B, KB, MB, GB, or TB (with two decimal precision).
* Outputs file modification times in ISO8601 format (UTC).
* Provides two modes:

  * `keep` (default): If the JSON file already exists, do nothing.
  * `renew`: Always regenerate the JSON file (overwrites any existing file).

## Usage

```bash
./makeindex.sh <directory> <json_file> [keep|renew]
```

* `<directory>`: Path to the root directory to scan.
* `<json_file>`: Path to the output JSON file.
* `[keep|renew]` (optional):

  * `keep` (default): Only creates the JSON file if it does not exist.
  * `renew`: Deletes any existing JSON file and creates a new one with the current directory structure.

**Examples:**

* Generate a new index only if it doesn't exist:

  ```bash
  ./makeindex.sh data/ data-index.json
  ```

* Always regenerate the index, overwriting previous file:

  ```bash
  ./makeindex.sh data/ data-index.json renew
  ```

## Output Example

The generated JSON file is an array of objects, one for each item in the root directory:

```json
[
  {
    "name": "documents",
    "type": "folder",
    "path": "documents",
    "children": [ ... ]
  },
  {
    "name": "report.pdf",
    "type": "file",
    "size": "125.32 KB",
    "extension": "pdf",
    "path": "report.pdf",
    "lastModified": "2024-05-28T14:00:00Z"
  }
]
```

## Notes

* Excluded: any file or directory starting with `.` or `~`, and the JSON output file itself.
* Make sure the script has execution permission: `chmod +x makeindex.sh`.
* Requires `bash`, `awk`, `stat`, and `date`.
* Works on most Linux distributions; minor tweaks may be needed for BSD/macOS.

