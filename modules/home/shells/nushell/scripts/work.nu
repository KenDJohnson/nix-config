
def "git-branch-exists" [branch: string]: nothing -> bool {
    (^git rev-parse --verify --quiet $branch | complete).exit_code == 0
}

# sanitize branch name (provided as input) stripping `<name>/` prefix
def "cg branch-sanitize" [
]: string -> string {
    $in | split row '/' | skip 1 | str join '/'
}

def "cg worktree dir" [
    name: string            # branch name
    --strip                 # whether or not to strip the user prefix
]: nothing -> path {
    let name = if $strip {
        $name | cg branch-sanitize
    } else {
        $name
    }
    $env.CGXS_DEV_DIR | path join worktrees | path join $name
}
alias "cg wt d" = cg worktree dir

# add a git worktree for an existing branch
def --env "cg worktree add" [
    branch: string             # full branch name, including `<name>/` prefix
]: nothing -> nothing {
   let wt_dir = cg worktree dir ($branch | cg branch-sanitize)
   ^git -C $env.CGXS_REPO worktree add $branch $wt_dir
   cd $wt_dir
   make
}
alias "cg wt a" = cg worktree add

def --env "cg worktree create" [
    branch: string             # branch name without `<name>/` prefix
    --base: string = "main"    # base branch
    --track                    # track upstream
]: nothing -> nothing {
    let branch_name = $"(whoami)/($branch)"
    let wt_dir = cg worktree dir $branch
    if (git-branch-exists $branch) {
        ^git -C $env.CGXS_REPO worktree add $branch_name $wt_dir 
    } else {
        ^git -C $env.CGXS_REPO worktree add -b $branch_name $wt_dir $base
    }
    cd $wt_dir
    if $track {
        ^git push -u origin $branch
    }
    make
}
alias "cg wt c" = cg worktree create
