> 🚧 **WORK IN PROGRESS** 🚧

# AutoCAD API Skills

A collection of AI agent skills and rules for scaffolding and building AutoCAD, Civil 3D, and Plant 3D plugins using .NET 10.

## How to Use

> 💡 **Recommendation:** We highly recommend installing these skills at the **Workspace (Project) level** rather than the User (Global) level. This avoids "context pollution," ensuring your AI assistant doesn't try to apply AutoCAD rules when you are working on unrelated projects (like web or mobile apps).

### The Easy Way (npx installer)

If you have Node.js installed, you can automatically scaffold all the AI rules and skills into your current project directory by running a single command. 

*(Note: Requires Node.js v16.7.0+ for `fs.cpSync`. You can install it on Windows via `winget install OpenJS.NodeJS.LTS`)*

Here is the typical workflow:
```bash
mkdir PlantPartBuilder
cd PlantPartBuilder
npx github:ADN-DevTech/acad-api-skill
cursor .
```

*(Note: If you are behind a corporate VPN or proxy, you may need to explicitly specify the npm registry:)*
```bash
npx --registry=https://registry.npmjs.org/ github:ADN-DevTech/acad-api-skill
```

This will automatically copy the `.cursor`, `skills`, `.github`, and `CLAUDE.md` files into your workspace.

---

### The Manual Way

If you prefer to install these manually, or want to install them at the **User (Global) level** so they apply to all your projects, follow the instructions below:

#### Cursor

**User Level (Global):**
- **Rules**: Copy the contents of `.cursor/rules/` to your global Cursor rules folder (`~/.cursor/rules/` on Mac/Linux, or `%USERPROFILE%\.cursor\rules\` on Windows).
- **Skills**: Copy the `skills/` directory to your global Cursor skills folder (`~/.cursor/skills/` or `%USERPROFILE%\.cursor\skills\`).

**Workspace Level (Project specific):**
- Copy the `.cursor/rules/` directory to your project's `.cursor/rules/` folder.
- Copy the `skills/` directory to your project's `.cursor/skills/` folder.

### VS Code (GitHub Copilot)

**User Level (Global):**
- Open your VS Code User Settings (`settings.json`).
- Copy the contents of `.github/copilot-instructions.md` and add them to the `github.copilot.chat.codeGeneration.instructions` array in your settings.

**Workspace Level:**
- Copy the `.github/copilot-instructions.md` file to your project's `.github/` folder.

### Claude (Claude Code CLI / Claude Desktop)

**Claude Code (CLI):**
- **Workspace Level:** Copy the `CLAUDE.md` file from this repository to the root of your project folder. The `claude` CLI tool will automatically read it and apply the guidelines.
- **User Level (Global):** While `CLAUDE.md` is project-specific, you can set global instructions for the CLI by running:
  `claude config set custom_instructions "Your global instructions here..."`

**Claude Web / Desktop App:**
- **User Level (Global):** You can paste the contents of `CLAUDE.md` into your "Custom Instructions" or "Project Knowledge" settings in the Claude web interface or Claude Desktop app.

## Repository
[https://github.com/ADN-DevTech/acad-api-skill](https://github.com/ADN-DevTech/acad-api-skill)
