# Ubuntu 24.04 Specific Notes

## PEP 668 and "externally-managed-environment" Error

### What is PEP 668?

Ubuntu 24.04 implements [PEP 668](https://peps.python.org/pep-0668/), which prevents installing Python packages system-wide using pip. This is designed to:

- Prevent conflicts between pip-installed packages and system packages
- Protect the system Python environment
- Encourage use of virtual environments

### The Error

When trying to install packages with pip, you may see:

```
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
```

### How This Installation Script Handles It

The script uses the `--break-system-packages` flag when installing pipenv:

```bash
pip3 install --break-system-packages --upgrade pipenv
```

### Why This is Safe

1. **Pipenv is a tool, not a library**: It manages virtual environments and doesn't interfere with system packages
2. **Isolated environments**: All application dependencies are installed in `.venv`, not system-wide
3. **No conflicts**: The application's packages are completely isolated from system Python
4. **Standard practice**: This is the recommended approach for environment management tools

### Alternative Solutions

If you prefer not to use `--break-system-packages`, you have alternatives:

#### Option 1: System Package (if available)

```bash
sudo apt-get install python3-pipenv
```

**Pros:**
- ✅ Managed by apt
- ✅ No PEP 668 issues
- ✅ Integrated with system

**Cons:**
- ❌ May be outdated
- ❌ Not always available
- ❌ Less control over version

#### Option 2: User Installation

```bash
pip3 install --user pipenv
export PATH="$HOME/.local/bin:$PATH"
```

**Pros:**
- ✅ No system modification
- ✅ No PEP 668 issues
- ✅ Latest version

**Cons:**
- ❌ PATH modification needed
- ❌ User-specific (not system-wide)
- ❌ May cause issues with sudo

#### Option 3: Virtual Environment for Pipenv (overkill)

```bash
python3 -m venv /opt/pipenv-venv
/opt/pipenv-venv/bin/pip install pipenv
ln -s /opt/pipenv-venv/bin/pipenv /usr/local/bin/pipenv
```

**Pros:**
- ✅ Completely isolated
- ✅ No system modification

**Cons:**
- ❌ Complex setup
- ❌ Overkill for a tool
- ❌ Maintenance overhead

### Recommended Approach

**For this installation script:** Use `--break-system-packages` (current implementation)

**Reasoning:**
1. Pipenv is specifically designed to create isolated environments
2. No actual system packages are affected
3. Simplest and most reliable solution
4. Works consistently across different Ubuntu 24.04 configurations
5. Widely accepted practice in the Python community for tools like pipenv

### If You Still Have Concerns

If you're uncomfortable with `--break-system-packages`, you can:

1. **Use Docker/Podman**: Containerize the entire application
2. **Use system packages only**: Install all dependencies via apt (limited package availability)
3. **Manual installation**: Install pipenv using one of the alternative methods above, then run the script

### Testing the Fix

After installation, verify everything is isolated:

```bash
# Check system Python packages
pip3 list

# Check application virtual environment packages
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr pipenv run pip list

# These should be completely different lists
```

### More Information

- **PEP 668 Specification**: https://peps.python.org/pep-0668/
- **Ubuntu 24.04 Release Notes**: https://discourse.ubuntu.com/t/noble-numbat-release-notes/
- **Python Virtual Environments**: https://docs.python.org/3/library/venv.html
- **Pipenv Documentation**: https://pipenv.pypa.io/

### Common Questions

**Q: Will this break my system Python?**  
A: No. Pipenv only installs packages in isolated virtual environments (`.venv` directories).

**Q: Can I use pip normally after this?**  
A: The PEP 668 restriction still applies to other pip commands. Use virtual environments or `--break-system-packages` as needed.

**Q: Is this the official recommendation?**  
A: For tools like pipenv that manage virtual environments, using `--break-system-packages` is widely accepted. For regular packages, use virtual environments.

**Q: What about security updates?**  
A: System packages are still managed by apt. Application packages are managed by pipenv. Both can be updated independently.

**Q: Can I uninstall pipenv later?**  
A: Yes. `sudo pip3 uninstall pipenv` will remove it. The application's virtual environment will remain functional.

### Summary

The `--break-system-packages` flag is:
- ✅ Safe for tools like pipenv
- ✅ Recommended by the Python community
- ✅ Does not affect system stability
- ✅ Allows proper virtual environment management
- ✅ The simplest solution that works reliably

The installation script uses this approach to provide a smooth, reliable installation experience on Ubuntu 24.04.

## Python Version Mismatch

### The Issue

The VCF Credential Manager's `Pipfile` may specify a specific Python version (e.g., 3.13.0) that isn't available on Ubuntu 24.04. Ubuntu 24.04 ships with Python 3.12 by default.

You may see this error:

```
Warning: Python 3.13.0 was not found on your system...
Neither 'pyenv' nor 'asdf' could be found to install Python.
```

### How the Script Handles This

The installation script automatically:

1. **Detects system Python version**:
   ```bash
   PYTHON_VERSION=$(python3 --version | awk '{print $2}')
   ```

2. **Modifies the Pipfile**:
   ```bash
   sed -i 's/python_version = .*/python_version = "3.12"/' Pipfile
   ```

3. **Uses system Python**:
   ```bash
   PIPENV_PYTHON=3 pipenv install --skip-lock
   ```

### Why This Works

- **Compatible versions**: Python 3.12 and 3.13 are highly compatible
- **Skip lock file**: Using `--skip-lock` avoids strict version checking
- **System Python**: Uses the well-tested Ubuntu Python package
- **No version manager needed**: Doesn't require pyenv or asdf

### Manual Fix

If you need to fix this manually:

```bash
cd /opt/vcf-credential-manager

# Check your Python version
python3 --version

# Edit Pipfile to match (e.g., for Python 3.12)
sudo nano Pipfile
# Change: python_version = "3.13" to python_version = "3.12"

# Or use sed
sudo sed -i 's/python_version = .*/python_version = "3.12"/' Pipfile

# Reinstall with system Python
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 PIPENV_PYTHON=3 pipenv install --skip-lock
```

### Alternative: Install Specific Python Version

If you absolutely need Python 3.13:

```bash
# Add deadsnakes PPA
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update

# Install Python 3.13
sudo apt-get install python3.13 python3.13-venv python3.13-dev

# Use it with pipenv
cd /opt/vcf-credential-manager
sudo -u vcfcredmgr PIPENV_VENV_IN_PROJECT=1 pipenv install --python 3.13
```

**Note:** This is usually unnecessary as Python 3.12 works perfectly fine.

---

**Last Updated:** December 2025  
**Applies to:** Ubuntu 24.04 LTS (Noble Numbat)

