
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
        | ^tar -C $dl_dir -xf -
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
