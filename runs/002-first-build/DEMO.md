# DEMO — clone, import, and draw the graph

Everything below is copy-pasteable into PowerShell 7.2+. It clones the module
built by this run, builds it, points it at a real Azure DevOps project, and
produces a graph you can open in a browser.

Total time: about a minute, most of it the build.

## What you need

- **PowerShell 7.2 or later.** `$PSVersionTable.PSVersion` to check.
- **An Azure DevOps personal access token** with **Code (Read)** and
  **Build (Read)**. Nothing else — the module never writes.
- **git**.

## 1. Set the token

The module reads `$env:AZDO_PAT` and nothing else. Never pass it as a parameter:
anything on a command line lands in `PSReadLine` history and in transcripts, and
a PAT is a bearer credential for your whole organisation.

```powershell
$env:AZDO_PAT = '<your token>'
```

## 2. Clone and build

```powershell
git clone --branch run-002-first-build https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
cd PSAzureDevOpsGraph
Install-Module powershell-yaml -Scope CurrentUser -Force   # the one runtime dependency
./build.ps1
```

`build.ps1` runs `Clean, Lint, Build, Test`. Expect it to end with:

```
Coverage 82.88% against a target of 40%.
Build succeeded. 5 tasks, 0 errors, 0 warnings
```

If PSScriptAnalyzer, Pester, or InvokeBuild are missing it stops and names what
to install; it never installs anything behind your back.

## 3. Import

```powershell
Import-Module ./output/PSAzureDevOpsGraph/PSAzureDevOpsGraph.psd1 -Force
Get-Command -Module PSAzureDevOpsGraph
```

Seven commands.

## 4. Build the graph

Substitute your own organisation and project.

```powershell
$graph = Get-AzDoPipelineDependencyGraph -Organisation jlbalmerjr1 -Project ClaudeTesting
$graph.nodes | Group-Object kind | Select-Object Count, Name
```

Against the fixture project this prints:

```
Count Name
----- ----
   15 pipeline
    4 repo
   30 yaml
```

Roughly half a second per YAML file, all of it network — 13 seconds for these 30.

## 5. Draw it

```powershell
$graph | Export-AzDoPipelineDependencyGraph -Path ./graph.html -Format Html
Invoke-Item ./graph.html
```

**What appears.** A plain page headed `jlbalmerjr1 / ClaudeTesting`, a count
line reading *15 pipeline, 4 repo, 30 yaml, 51 edges*, and one table row per
edge: the source file, the edge kind in monospace, the target, and the raw
reference text as it appeared in the YAML.

Two rows are **tinted red** — the unresolved references out of `p09.yml`. Their
target is marked *(pseudo-node)* because nothing in the graph has that id: one
names a file that does not exist, the other an alias that was never declared.
Those two rows are the reason the tool exists. A pipeline whose template
reference is broken looks, in every other view, exactly like a healthy one.

The page loads no scripts, stylesheets, or fonts from anywhere — it opens from a
`file://` URL on a machine with no network.

## 6. Answer the real question

```powershell
# Which files reference this template?
$target = 'yaml:pipelines-main/pipelines/templates/steps-build.yml'
$graph.edges | Where-Object to -eq $target | Select-Object from, kind, ref

# Everything broken, with the reason
$graph.edges | Where-Object kind -eq 'unresolved' | Format-List from, ref, reason

# Which pipelines have no incoming references at all?
$referenced = $graph.edges.to
$graph.nodes | Where-Object { $_.kind -eq 'pipeline' -and $_.id -notin $referenced }
```

## Reproducing this run's exact score

From a clone of the **harness** repository, with `$env:AZDO_PAT` set:

```powershell
git clone https://github.com/JerryBalmer1/AI.Agent.Claude.PowerShellModuleBuilder.git
cd AI.Agent.Claude.PowerShellModuleBuilder
pwsh -NoProfile -File ./plans/0016-first-build/verify.ps1
```

That re-derives all three scores from a fresh clone of the module rather than
reading them out of `runs/002-first-build/README.md`. Without `AZDO_PAT` it
skips the live half loudly and still checks the rest.

To score a graph you produced yourself:

```powershell
./evals/functional/Compare-Graph.ps1 -CandidatePath ./graph.json
```

Exit 0 and `The graphs agree. 0 differences.` is the passing result.

## If something goes wrong

| Symptom | Cause |
|---|---|
| `AZDO_PAT is not set…` | Step 1. The module will not prompt or search for a token. |
| `Azure DevOps returned its sign-in page` | The token is wrong, expired, or lacks Code/Build read. Azure DevOps sends the login page with a success status. |
| `The 'powershell-yaml' module is required` | Step 2's `Install-Module` line. |
| Empty graph, no error | The project has no YAML pipeline definitions. Classic (designer) build definitions carry no `process.yamlFilename` and are skipped. |
