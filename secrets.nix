let
  # User SSH public keys (from ~/.ssh/id_ed25519.pub)
  kjohnson-mini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINFsq+fd1/4M384lgW1QWZ7HkvgzNMo1ARMm5WvL4hGp";
  kjohnson-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMeRa2lQA9cb8X6jUL/vipKVIzt+Ax+rtJ+XZbR6wIRF";
  ken-ocx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkQvWncW5HKPK9vK63cblF3QMyomH/uFv2NdHuE9LmJ";
  users = [kjohnson-mini kjohnson-mbp ken-ocx];

  Kens-MBP = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYoyPc1ZWmBTP0SVu4ozURWvVcd6ARFwuAAmc23W4K2";
  Kens-Mac-mini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOC4z3GE9cIzBQNEz1jw6EQbDkf83ivDVLka7sxo56A1";
  ocx-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKIB30zIkNwpLoK7zwnuJu3mlkbKk89L7rbJnq9wy2r5";
  systems = [Kens-MBP Kens-Mac-mini ocx-mbp];
  work = [ken-ocx ocx-mbp];
  allKeys = users ++ systems;
in {
  "secrets/user-info.age".publicKeys = allKeys;
  "secrets/ssh-hosts.age".publicKeys = allKeys;
  "secrets/mcp-tokens.age".publicKeys = allKeys;
  "modules/home/work-identity.age".publicKeys = work;
}
