# Scoop Bucket

This is a Scoop bucket for the `gonewton` CLI tools: `constraint` and `newton`.

## Installation

First, add this bucket:

```powershell
scoop bucket add gonewton https://github.com/gonewton/scoop-bucket
```

Then install the tools:

```powershell
scoop install constraint
scoop install newton
```

## Usage

### Constraint

```powershell
constraint --help
```

### Newton

```powershell
newton --help
```

## Upgrading

To upgrade to the latest version:

```powershell
scoop update
scoop update constraint
scoop update newton
```

## Development

This bucket is automatically updated when new releases are published to the respective repositories.

To manually update manifests, use the `generate_manifest.sh` script:

```bash
./generate_manifest.sh constraint --version v1.0.0
./generate_manifest.sh newton --version v1.0.0
```