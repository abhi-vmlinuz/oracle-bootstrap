# Oracle Database Development Bootstrapper

A one-command installer that sets up a complete Oracle Database development environment on Linux (including WSL).

## Quick Start

```bash
git clone https://github.com/abhi-vmlinuz/oracle-bootstrap.git
cd oracle-bootstrap

# Download Oracle Instant Client ZIPs
wget https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-basic-linux.x64-23.7.0.24.10.zip
wget https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-sqlplus-linux.x64-23.7.0.24.10.zip

# Run installer
./install.sh
```

After installation, open a new terminal and run:

```bash
connect-db
```

That's it. Oracle container starts, waits until ready, and drops you into SQL*Plus.

## Commands

| Command | Purpose |
|---------|---------|
| `connect-db` | Start container if stopped, wait for Oracle, launch SQL*Plus with `rlwrap` |
| `sqlplus-now` | Launch SQL*Plus instantly (container must already be running) |

## Supported Distributions

- Fedora
- Ubuntu
- Linux Mint
- Debian
- Kali Linux
- Arch Linux / Manjaro
- openSUSE

## Project Structure

```
oracle-bootstrap/
├── install.sh
├── uninstall.sh
├── lib/
│   ├── distro.sh
│   ├── packages.sh
│   ├── podman.sh
│   ├── oracle.sh
│   ├── sqlplus.sh
│   ├── shell.sh
│   └── utils.sh
├── scripts/
│   ├── connect-db
│   ├── sqlplus-now
│   └── wait-for-db
├── sql/
│   └── init.sql
├── README.md
└── LICENSE
```

## Custom Credentials

By default, connects as `mca/mca@localhost:1521/FREEPDB1`.

To change credentials, edit:
- `scripts/connect-db`
- `scripts/sqlplus-now`
- `sql/init.sql`

Then re-run `./install.sh`.

## Uninstalling

```bash
./uninstall.sh
```

This removes the container, data volume, commands, and shell integration. Optionally removes Instant Client and cached downloads.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `command not found: connect-db` | Reload shell: `source ~/.bashrc` or open new terminal |
| Podman not found | Run `./install.sh` to install it |
| Container won't start | Check `podman logs oracledb` |
| SQL*Plus not found | Ensure Oracle Instant Client is in `~/.cache/oracle/` and re-run installer |

## License

MIT — see LICENSE file.
