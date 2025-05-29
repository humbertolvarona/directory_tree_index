#!/bin/bash

export LC_NUMERIC="C"

DIR="$1"
JSON_FILE="$2"
ACTION="${3:-keep}"

OUTFILE_ABS=$(readlink -f "$JSON_FILE")

# Format size in KB, MB, GB, TB (2 decimals)
human_size() {
    local size="$1"
    local units=(B KB MB GB TB)
    local i=0
    # Solo enteros en el bucle
    while [[ $size -ge 1024 && $i -lt 4 ]]; do
        size=$((size / 1024))
        ((i++))
    done
    # Solo convertir a float si no es bytes
    if [[ $i -eq 0 ]]; then
        echo "${size} ${units[$i]}"
    else
        real_size=$(awk "BEGIN {printf \"%.2f\", $1/(1024^$i)}")
        echo "${real_size} ${units[$i]}"
    fi
}

get_size() {
    if stat --version >/dev/null 2>&1; then
        stat -c %s "$1"
    else
        stat -f %z "$1"
    fi
}

get_mtime() {
    if stat --version >/dev/null 2>&1; then
        date -u -d @"$(stat -c %Y "$1")" +'%Y-%m-%dT%H:%M:%SZ'
    else
        date -u -r "$(stat -f %m "$1")" +'%Y-%m-%dT%H:%M:%SZ'
    fi
}

# Esta función devuelve solo los children del directorio raíz
children_json() {
    local dir="$1"
    local relpath="$2"
    local indent="$3"
    local entries=()
    local i=0

    shopt -s nullglob dotglob
    for entry in "$dir"/*; do
        [ -e "$entry" ] || continue
        local name=$(basename "$entry")
        [[ "$name" =~ ^[.~] ]] && continue

        if [ "$(readlink -f "$entry")" = "$OUTFILE_ABS" ]; then
            continue
        fi

        local subpath="${relpath:+$relpath/}$name"
        if [ -d "$entry" ]; then
            entries[i]="$(dir_to_json "$entry" "$subpath" "$indent")"
        else
            local size_bytes=$(get_size "$entry")
            local size_human=$(human_size "$size_bytes")
            local ext="${name##*.}"
            [[ "$name" == "$ext" ]] && ext=""
            local mtime=$(get_mtime "$entry")
            entries[i]="
${indent}{
${indent}  \"name\": \"$name\",
${indent}  \"type\": \"file\",
${indent}  \"size\": \"$size_human\",
${indent}  \"extension\": \"$ext\",
${indent}  \"path\": \"$subpath\",
${indent}  \"lastModified\": \"$mtime\"
${indent}}"
        fi
        ((i++))
    done

    local children=""
    local count=${#entries[@]}
    if [ $count -gt 0 ]; then
        children=$(printf ",%s" "${entries[@]}")
        children=${children:1}
    fi

    echo "$children"
}

# Esta función sí devuelve el objeto completo para subdirectorios
dir_to_json() {
    local dir="$1"
    local relpath="$2"
    local indent="$3"
    local entries=()
    local i=0

    shopt -s nullglob dotglob
    for entry in "$dir"/*; do
        [ -e "$entry" ] || continue
        local name=$(basename "$entry")
        [[ "$name" =~ ^[.~] ]] && continue

        if [ "$(readlink -f "$entry")" = "$OUTFILE_ABS" ]; then
            continue
        fi

        local subpath="${relpath:+$relpath/}$name"
        if [ -d "$entry" ]; then
            entries[i]="$(dir_to_json "$entry" "$subpath" "  $indent")"
        else
            local size_bytes=$(get_size "$entry")
            local size_human=$(human_size "$size_bytes")
            local ext="${name##*.}"
            [[ "$name" == "$ext" ]] && ext=""
            local mtime=$(get_mtime "$entry")
            entries[i]="
${indent}  {
${indent}    \"name\": \"$name\",
${indent}    \"type\": \"file\",
${indent}    \"size\": \"$size_human\",
${indent}    \"extension\": \"$ext\",
${indent}    \"path\": \"$subpath\",
${indent}    \"lastModified\": \"$mtime\"
${indent}  }"
        fi
        ((i++))
    done

    local children=""
    local count=${#entries[@]}
    if [ $count -gt 0 ]; then
        children=$(printf ",%s" "${entries[@]}")
        children=${children:1}
    fi

    local this_path="${relpath:-""}"

    cat <<EOF
${indent}{
${indent}  "name": "$(basename "$dir")",
${indent}  "type": "folder",
${indent}  "path": "$this_path",
${indent}  "children": [
$children
${indent}  ]
${indent}}
EOF
}

if [[ -z "$DIR" || -z "$JSON_FILE" ]]; then
    echo "Usage: $0 <directory> <json_file> [keep|renew]"
    exit 1
fi

if [[ "$ACTION" == "keep" ]]; then
    if [[ -f "$JSON_FILE" ]]; then
        echo "File $JSON_FILE already exists and 'keep' is set. No action performed."
        exit 0
    fi
elif [[ "$ACTION" == "renew" ]]; then
    if [[ -f "$JSON_FILE" ]]; then
        rm -f "$JSON_FILE"
    fi
fi

# Genera el JSON solo con los hijos del directorio raíz
echo "[ $(children_json "$DIR" "" "") ]" > "$JSON_FILE"
echo "JSON file generated at $JSON_FILE"
 exit 0