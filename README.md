Terminal assistant on steroids. Uses Gemini Flash to turn your thoughts into commands, fix your mess, and explain the unexplainable. Fully autonomous with its own terminal recorder and AI analyst mode. Works on Linux & macOS.

## Quick Start

```bash
git clone https://github.com/CloudWells/clicom-tool.git
cd clicom-tool
sudo bash install.sh
source ~/.bashrc
```
*The installer will ask for your Google API Key and save it to `/opt/clicom/config/.env` automatically.*

## Configuration

- **API Key & Settings**: Stored in `/opt/clicom/config/.env`
- **AI Persona**: Stored in `/opt/clicom/config/custom_prompt.txt` (edit via `clicom -prompt`)

- **Just ask**: `clicom find all docker containers using more than 1GB RAM`
- **AI Analyst**: `clicom -ai "why is my disk full?"` (Runs analysis commands + provides expert opinion)
- **Fix shit**: `clicom -fix` (Analyzes logs of your failed command and suggests a fix)
- **What happened?**: `clicom -wtf` (Explains the last terminal output with beautiful formatting)
- **YOLO Mode**: `clicom -yolo on` (Executes commands immediately without asking)
- **Custom Persona**: `clicom -prompt` (Set global instructions, e.g., "be concise and rude")
- **Record session**: `clicom -log on` (Internal Python-based recorder for deep context)

## Features

- **Rich Formatting**: Beautiful Markdown rendering for explanations and analysis.
- **Model Switching**: Easily switch between `flash`, `pro`, or `preview` models.
- **Auto-Update**: Keep your tool fresh with `clicom -update`.
- **Zsh & Bash**: Full support for both major shells.

## Flags

- `-ai`: **Analyst Mode**. Runs commands and explains the result.
- `-fix`: Analyze logs + history -> suggest a fix.
- `-wtf`: Explain the current terminal state/error.
- `-prompt`: Edit global AI instructions/persona.
- `-h`: Include last 20 commands for context.
- `-model [name]`: Switch the underlying Gemini model.
- `-yolo on/off`: Enable "no-confirmation" mode.
- `-update`: Pull the latest version from GitHub and reinstall.

## Uninstall

```bash
sudo /opt/clicom/uninstall.sh
```

## License
MIT