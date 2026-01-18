let
  # User SSH public keys (from ~/.ssh/id_ed25519.pub)
  kjohnson-mini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINFsq+fd1/4M384lgW1QWZ7HkvgzNMo1ARMm5WvL4hGp";
  kjohnson-mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMeRa2lQA9cb8X6jUL/vipKVIzt+Ax+rtJ+XZbR6wIRF";
  kjohnson-tenb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN0RYAHLgSZJ2Yj/v88f6f+Vwc0uIPTW8asw8ZCuo6Dm";
  users = [kjohnson-mini kjohnson-mbp kjohnson-tenb];

  Kens-MBP = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYoyPc1ZWmBTP0SVu4ozURWvVcd6ARFwuAAmc23W4K2";
  Kens-Mac-mini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOC4z3GE9cIzBQNEz1jw6EQbDkf83ivDVLka7sxo56A1";
  tenb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMoPZnpqzh9siHfUmk/mfZ6WWY9WHnIAsvyWnW5NRblz";
  systems = [Kens-MBP Kens-Mac-mini tenb];
  personal = [kjohnson-mini kjohnson-mbp Kens-MBP Kens-Mac-mini];
  work = [kjohnson-tenb tenb];
  allKeys = users ++ systems;
in {
  "user-info.age".publicKeys = allKeys;
  "ssh-hosts.age".publicKeys = allKeys;
}
