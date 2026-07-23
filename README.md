# Oracle Database Development Bootstrapper

A simple, one-command installer to set up a complete Oracle Database development environment on Linux and Windows Subsystem for Linux (WSL).

Designed to get computer science/MCA students up and running with Oracle SQL instantly, with zero manual setup headaches.

---

##  Quick Start (START FROM HERE) 

Open your terminal and run the following commands:

```bash
# 1. Clone this repository
git clone https://github.com/abhi-vmlinuz/oracle-bootstrap.git
cd oracle-bootstrap

# 2. Download the required Oracle Instant Client files (23c Free)
wget https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-basic-linux.x64-23.4.0.24.05.zip
wget https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-sqlplus-linux.x64-23.4.0.24.05.zip

# 3. Run the installer (enter your sudo password if prompted for dependencies)
./install.sh
```
### NOTE
if the wget commands returns a 404 head to this [link](https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html) and download:
- instantclient-basic-linux.x64-23.26.3.0.0.zip
- instantclient-sqlplus-linux.x64-23.26.3.0.0.zip

move these zip files on the repository folder and run the install script again

### NOTE 
if the script exists with message:
`Waiting for Oracle to be ready...`
then re-run the ./install script again.

### Next Step
Close your current terminal, open a **new terminal window**, and run:
```bash
connect-db
```
Press **Enter** at both prompts to log in with the default credentials (`mca` / `mca`).

---

##  CLI Commands

After installation, two global commands will be available in your shell:

| Command | When to use it | What it does |
|:---|:---|:---|
| **`connect-db`** | **First connection of the day** | Starts the Oracle container if stopped, waits for the database to boot, and drops you into SQL*Plus. |
| **`sqlplus-now`** | **Quick subsequent connections** | Instantly drops you into SQL*Plus (container must already be running). |

---

##  Running and Importing SQL Files

There are two easy ways to run your SQL files (like tables creation or queries):

### Method A: Directly from your terminal (Recommended)
You can run any `.sql` file directly from your terminal shell using the `--from` flag:

```bash
# If container is stopped:
connect-db --from path/to/your/file.sql

# If container is already running (instant execution):
sqlplus-now --from path/to/your/file.sql
```
*Note: This will execute all statements in the file and exit back to your terminal immediately.*

### Method B: From inside the SQL*Plus prompt
If you are already inside SQL*Plus, you can execute a local SQL file using the `@` symbol:

```sql
SQL> @path/to/your/file.sql
```

---

## Credentials & Default Database

By default, the database is pre-configured with:
- **Username:** `mca` (all caps `MCA` internally)
- **Password:** `mca`
- **Host / Port:** `localhost:1521`
- **Pluggable Database (PDB):** `FREEPDB1`

Simply hit **Enter** when prompted for the username and password to use these defaults.

---

##  Supported Linux Distributions

- Ubuntu / Linux Mint / Pop!_OS
- Debian / Kali Linux
- Fedora
- Arch Linux / Manjaro
- openSUSE

---

##  Troubleshooting

| Problem | Root Cause | Solution |
|:---|:---|:---|
| **`connect-db: command not found`** | Your current terminal doesn't know about the new commands. | Close your terminal and open a new one, or run `source ~/.bashrc` (or `source ~/.zshrc`). |
| **Long wait on first startup** | The container is creating initial database files. | The first-time initialization takes 2–4 minutes depending on your disk speed. Please wait for the count to complete. |
| **`rlwrap` not working** | Package was not installed. | Run your distro package manager to install it (e.g. `sudo apt install rlwrap`). |
| **Missing shared library (`libaio`)** | Missing distro dependency for SQL*Plus. | Run `./install.sh` again to let the script resolve it, or manually run `sudo apt install libaio1` (or `libaio1t64` on Ubuntu 24.04+). |

---

##  Uninstalling

If you ever need to clean up and remove the Oracle setup:
```bash
cd oracle-bootstrap
./uninstall.sh
```
This removes the container, data volume, installed commands, and shell integration.

---

## 📄 License
MIT feel free to share and modify for your classes!
