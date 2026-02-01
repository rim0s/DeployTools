#!/bin/bash
set -euo pipefail

merge_dir=""
show_help(){
  cat <<'EOF'
Usage: merge-helper.sh --merge-dir <merge_dir> <command> [args]

Commands:
  list                       List conflicted relative paths in merge dir
  show-report                Show merge-report.txt
  diff <relpath>             Show unified diff between theirs and ours for relpath
  accept-ours <relpath> <target_root>   Accept our version (copy .ours -> target)
  accept-theirs <relpath> <target_root> Accept their version (copy .theirs -> target)
  accept-all-ours <target_root>         Accept all .ours into target
  accept-all-theirs <target_root>       Accept all .theirs into target
  gen-patch <out.patch>      Generate patch (theirs -> ours) into out.patch

Notes:
  - <merge_dir> is the pending merge folder created by rollback system,
    typically: ${ROLLBACK_PREFIX:-.}/<tx>/pending/<opid>.merge
  - <relpath> is the path relative to the merge root (no leading slash).
EOF
}

if [[ $# -lt 2 ]]; then
  show_help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --merge-dir) merge_dir="$2"; shift 2;;
    list|show-report|diff|accept-ours|accept-theirs|accept-all-ours|accept-all-theirs|gen-patch)
      cmd="$1"; shift; break;;
    -h|--help) show_help; exit 0;;
    *) echo "Unknown arg: $1" >&2; show_help; exit 2;;
  esac
done

if [[ -z "$merge_dir" || ! -d "$merge_dir" ]]; then
  echo "merge_dir not provided or does not exist: $merge_dir" >&2
  exit 2
fi

case "$cmd" in
  list)
    find "$merge_dir" -type f \( -name '*.ours' -o -name '*.theirs' \) -print0 | \
      xargs -0 -n1 basename | sed -E 's/\.(ours|theirs)$//' | sort -u
    ;;
  interactive)
    target_root="$1"
    if [[ -z "$target_root" ]]; then
      echo "interactive requires <target_root>" >&2; exit 2
    fi
    # collect unique relpaths
    mapfile -t rels < <(find "$merge_dir" -type f \( -name '*.ours' -o -name '*.theirs' \) -print0 | xargs -0 -n1 basename | sed -E 's/\.(ours|theirs)$//' | sort -u)
    if [[ ${#rels[@]} -eq 0 ]]; then
      echo "no conflicts found in $merge_dir"
      exit 0
    fi
    echo "Entering interactive merge helper for $merge_dir -> $target_root"
    for rel in "${rels[@]}"; do
      while true; do
        echo
        echo "Conflict: $rel"
        echo "Actions: (d)iff (o)urs (t)heirs (s)kip (O)urs-all (T)heirs-all (q)uit"
        read -r -p "choice> " ch
        case "$ch" in
          d)
            "$0" --merge-dir "$merge_dir" diff "$rel" || true
            ;;
          o)
            src="$merge_dir/$rel.ours"
            if [[ ! -f "$src" ]]; then echo ".ours not found: $src"; else
              dest="$target_root/$rel"; mkdir -p "$(dirname "$dest")"; [[ -f "$dest" ]] && cp -p "$dest" "$dest.bak.$(date +%s)" || true; cp -p "$src" "$dest"; echo "Applied ours -> $dest"; fi
            break
            ;;
          t)
            src="$merge_dir/$rel.theirs"
            if [[ ! -f "$src" ]]; then echo ".theirs not found: $src"; else
              dest="$target_root/$rel"; mkdir -p "$(dirname "$dest")"; [[ -f "$dest" ]] && cp -p "$dest" "$dest.bak.$(date +%s)" || true; cp -p "$src" "$dest"; echo "Applied theirs -> $dest"; fi
            break
            ;;
          s)
            echo "Skipped $rel"
            break
            ;;
          O)
            echo "Applying all remaining .ours to target"
            for r in "${rels[@]}"; do
              src="$merge_dir/$r.ours"; dest="$target_root/$r"; if [[ -f "$src" ]]; then mkdir -p "$(dirname "$dest")"; [[ -f "$dest" ]] && cp -p "$dest" "$dest.bak.$(date +%s)" || true; cp -p "$src" "$dest"; echo "Applied ours -> $dest"; fi
            done
            exit 0
            ;;
          T)
            echo "Applying all remaining .theirs to target"
            for r in "${rels[@]}"; do
              src="$merge_dir/$r.theirs"; dest="$target_root/$r"; if [[ -f "$src" ]]; then mkdir -p "$(dirname "$dest")"; [[ -f "$dest" ]] && cp -p "$dest" "$dest.bak.$(date +%s)" || true; cp -p "$src" "$dest"; echo "Applied theirs -> $dest"; fi
            done
            exit 0
            ;;
          q)
            echo "Quit interactive mode"; exit 0
            ;;
          *) echo "Unknown choice"; ;;
        esac
      done
    done
    ;;
  show-report)
    if [[ -f "$merge_dir/merge-report.txt" ]]; then
      sed -n '1,200p' "$merge_dir/merge-report.txt"
    else
      echo "no merge-report.txt in $merge_dir"
    fi
    ;;
  diff)
    rel="$1"
    theirs="$merge_dir/$rel.theirs"
    ours="$merge_dir/$rel.ours"
    if [[ ! -f "$theirs" && ! -f "$ours" ]]; then
      echo "Neither theirs nor ours exists for $rel" >&2; exit 3
    fi
    # use /dev/null for missing side to show additions/deletions
    : > /tmp/merge_helper_left.tmp || true
    left=${theirs:-/dev/null}
    right=${ours:-/dev/null}
    if [[ -f "$theirs" ]]; then left="$theirs"; else left=/dev/null; fi
    if [[ -f "$ours" ]]; then right="$ours"; else right=/dev/null; fi
    diff -u --label "theirs/$rel" --label "ours/$rel" "$left" "$right" || true
    ;;
  accept-ours)
    rel="$1"; target_root="$2"
    src="$merge_dir/$rel.ours"
    if [[ ! -f "$src" ]]; then echo ".ours not found: $src" >&2; exit 3; fi
    dest="$target_root/$rel"
    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]]; then cp -p "$dest" "$dest.bak.$(date +%s)"; fi
    cp -p "$src" "$dest"
    echo "Applied ours -> $dest"
    ;;
  accept-theirs)
    rel="$1"; target_root="$2"
    src="$merge_dir/$rel.theirs"
    if [[ ! -f "$src" ]]; then echo ".theirs not found: $src" >&2; exit 3; fi
    dest="$target_root/$rel"
    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]]; then cp -p "$dest" "$dest.bak.$(date +%s)"; fi
    cp -p "$src" "$dest"
    echo "Applied theirs -> $dest"
    ;;
  accept-all-ours)
    target_root="$1"
    find "$merge_dir" -type f -name '*.ours' -print0 | while IFS= read -r -d '' f; do
      rel=$(basename "$f" .ours)
      dest="$target_root/$rel"
      mkdir -p "$(dirname "$dest")"
      if [[ -f "$dest" ]]; then cp -p "$dest" "$dest.bak.$(date +%s)"; fi
      cp -p "$f" "$dest"
      echo "Applied ours -> $dest"
    done
    ;;
  accept-all-theirs)
    target_root="$1"
    find "$merge_dir" -type f -name '*.theirs' -print0 | while IFS= read -r -d '' f; do
      rel=$(basename "$f" .theirs)
      dest="$target_root/$rel"
      mkdir -p "$(dirname "$dest")"
      if [[ -f "$dest" ]]; then cp -p "$dest" "$dest.bak.$(date +%s)"; fi
      cp -p "$f" "$dest"
      echo "Applied theirs -> $dest"
    done
    ;;
  gen-patch)
    out="$1"
    # create temp dirs
    tmpdir=$(mktemp -d)
    ours_root="$tmpdir/ours"
    theirs_root="$tmpdir/theirs"
    mkdir -p "$ours_root" "$theirs_root"
    find "$merge_dir" -type f -name '*.ours' -print0 | while IFS= read -r -d '' f; do
      rel=$(basename "$f" .ours)
      mkdir -p "$ours_root/$(dirname "$rel")"
      cp -p "$f" "$ours_root/$rel" || true
    done
    find "$merge_dir" -type f -name '*.theirs' -print0 | while IFS= read -r -d '' f; do
      rel=$(basename "$f" .theirs)
      mkdir -p "$theirs_root/$(dirname "$rel")"
      cp -p "$f" "$theirs_root/$rel" || true
    done
    diff -ruN "$theirs_root" "$ours_root" > "$out" || true
    echo "Patch written to $out"
    rm -rf "$tmpdir"
    ;;
  *) echo "unknown command" >&2; show_help; exit 2;;
esac
