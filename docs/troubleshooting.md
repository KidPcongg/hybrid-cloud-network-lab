# Troubleshooting Notes

## 001 — Git clone failed because of an extra space

### Goal
Clone the private lab repository from GitHub to my Mac using SSH.

### Symptom
Git reported that the repository name was invalid.

### Incorrect command
git clone git@github-personal: KidPcongg/hybrid-cloud-network-lab.git

### Root cause
An extra space after the colon split the repository address
into two separate command-line arguments.

Git interpreted the first argument as the source and the
second as the destination directory.

### Fix
Remove the space after the colon:

git clone git@github-personal:KidPcongg/hybrid-cloud-network-lab.git

### Verification
The clone completed successfully.
Inside the repository, git status showed:
- On branch main.
- Up to date with origin/main.
- Nothing to commit, working tree clean.

### What I learned
SSH authentication and repository cloning are separate steps.
Successful authentication does not guarantee a correct clone command.
Spaces can change how the shell separates command arguments.
