
def "host-target regex" []: nothing -> record<arch: string, os:string> {
    let arch = match (uname | get machine) {
        "arm64" => "arm64|aarch64",
        other => other,
    }
    let os = match (uname | get operating-system) {
        "Darwin" => "(?i:darwin|macos)",
        other => other,
    }
    { arch: $arch, os: $os }
}

def host-target []: nothing -> string {
    let arch = match (uname | get machine) {
        "arm64" => "aarch64",
        other => other,
    }
    let os = match (uname | get operating-system) {
        "Darwin" => "apple-darwin",
        other => other,
    }
    $"($arch)-($os)"
}

def gh-latest-release [repo: string]: nothing -> string {
  ^gh release -R $repo list --json isLatest,name,tagName -q 'map(select(.isLatest))|first|.tagName'
}

def gh-release-assets [
    repo: string
    tag: string
]: nothing -> table<apiUrl: string, contentType: string, name: string, url: string> {
    ^gh release -R $repo view $tag --json assets -q '.assets|map({ apiUrl, contentType, name, url })'
        | from json
}

def gh-release-platform-assets [
    repo: string
    tag: string
]: nothing -> table<apiUrl: string, contentType: string, name: string, url: string> {
    let os_regex = host-target regex
    gh-release-assets $repo $tag
        | where name =~ $os_regex.arch
        | where name =~ $os_regex.os
}

def gh-find-release-asset [
    repo: string
    release: string
    filter?: string
]: nothing -> record<apiUrl: string, contentType: string, name: string, url: string> {
    let assets = match $filter {
        null => (gh-release-platform-assets $repo $release),
        _ => (gh-release-platform-assets $repo $release | where name == $filter),
    }
    if (($assets | length) > 1) {
        let selected = $assets | get name | input list "Select a release asset"
        $assets | where name == $selected | first
    } else {
        $assets | first
    }
}

def gh-release-asset-download-extract [
    repo: string
    tag: string
    name: string
    out: path
]: nothing -> nothing {
    let dl_dir = mktemp --directory
    let extract_path = $dl_dir | path join ($name | split row '.' | first)
    ^gh release -R $repo download $tag --pattern $name --output -
        | ^tar -C $dl_dir -xzf -
    mv $extract_path $out
    rm -r $dl_dir
}

def gh-download-release [
    repo: string
    out: path
    --tag: string
    --filter: string
] {
   let tag = ($tag | default { gh-latest-release $repo })
   let asset = gh-find-release-asset $repo $tag $filter
   gh-release-asset-download-extract $repo $tag $asset.name $out
}


def update-codex [] {
    let codex_path = which codex | get 0.path
    let asset_name = $"codex-(host-target).tar.gz"
    gh-download-release openai/codex $codex_path --filter $asset_name
    chmod +x $codex_path
    codex --version
}

def pairs-to-record []: list<list<string>> -> record {
    $in | reduce --fold {} {|pair, acc| $acc | upsert $pair.0 $pair.1 }
}

def rows-to-record []: table -> record {
    let vals = $in | values
    $vals.0 | zip $vals.1 | pairs-to-record
}

def _parse-wt-group [] {
    $in
        | take 3
        | each { if $in == detached { [branch, detached] } else { $in | split row ' ' } }
        | pairs-to-record
        | update branch? {|b| $b.branch | str replace -r '^refs/heads/' ''}
}

def git-status-parse1 [] {
    # 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
    # let xy = '(?<staged1>[\.MTADRCU?!])(?<staged2>[\.MTADRCU?!])'
    # let sub_state = '(?<submodule>N\.\.\.|S[C\.][M\.][U\.])'
    # let mh = '(?<head_mode>[0-7]{6})'
    # let mi = '(?<index_mode>[0-7]{6})'
    # let mw = '(?<worktree_mode>[0-7]{6})'
    # let hh = '(?<head_object>[0-9a-f]+)'
    # let hi = '(?<index_object>[0-9a-f]+)'
    # let path = '(?<path>.*)'
    let pattern = [
        '1'
        '(?<staged1>[\.MTADRCU?!])(?<staged2>[\.MTADRCU?!])'
        '(?<submodule>N\.\.\.|S[C\.][M\.][U\.])'
        '(?<head_mode>[0-7]{6})'
        '(?<index_mode>[0-7]{6})'
        '(?<worktree_mode>[0-7]{6})'
        '(?<head_object>[0-9a-f]+)'
        '(?<index_object>[0-9a-f]+)'
        '(?<path>.*)'
    ] | str join ' '
    

    $in | parse --regex $pattern
}

def git-wt-branch-status [wt: path] {
    let wt_status = ^git -C $wt status --branch --porcelain=2 | lines
    let branch = $wt_status
        | iter filter-map { parse --regex '# branch\.(?<field>\w+) (?<val>.+)' }
        | flatten
        | rows-to-record
    let upstream = if ($branch.ab? | is-not-empty) {
        let ab = $branch.ab | parse --regex '\+(?<ahead>\d+) -(?<behind>\d+)' | first
        $ab | merge { name: $branch.upstream?, exists: true }
    } else {
        {
            ahead: 0,
            behind: 0,
            name: $branch.upstream?,
            exists: false
        }
    }
    $branch | reject ab? | upsert upstream $upstream
}

def git-wt-remote [wt: path]: nothing -> string {
    ^git -C $wt rev-parse --abbrev-ref @{u}
}

def git-wt-detail [] {
    let wt = $in
    let branch_status = git-wt-branch-status $wt.worktree
    $wt | merge $branch_status
}

def git-wts [] {
    ^git worktree list --porcelain
        | lines
        | chunks 4
        | each { _parse-wt-group }
}

alias gwt = git-wts

def "gwt detail" [] {
    git-wts
        | each {|wt| $wt | git-wt-detail }
}

def "gwt unpushed" [] {
    gwt detail
        | where (($it.upstream.name | is-not-empty) and (not $it.upstream.exists))
}

def "gwt stale" [] {
    gwt detail
        | where (($it.upstream.name | is-not-empty) and (not $it.upstream.exists))
}

def multiline-run []: string -> any {
    let cmd = $in | lines | each { str replace '\' '' | str trim } | str join ' ' | split row ' '
    print -e $"($cmd | str join ' ')"
    ^$cmd
}
