# :rocket: An Implementation of MeTTa designed to run on the Warren Abstract Machine (WAM)

## Quick Links

 - [https://github.com/trueagi-io/metta-wam/](https://github.com/trueagi-io/metta-wam/)   MeTTaLog Official
 - [https://github.com/logicmoo/metta-wam/](https://github.com/logicmoo/metta-wam/)   Compiler/Interpreter/LSP/Examples Development   
 - [https://github.com/logicmoo/metta-testsuite/tree/master/](https://github.com/logicmoo/metta-testsuite/tree/master/) Runs tests for previous
 - [https://github.com/logicmoo/metta-testsuite/tree/development/](https://github.com/logicmoo/metta-testsuite/tree/development/)  Testing Suite 
 - [https://github.com/trueagi-io/metta-wam/issues](https://github.com/trueagi-io/metta-wam/issues)   ISSUES
- [Getting Started](#getting-started)
  - [Installation](#installation)
- [Running MeTTaLog](#neckbeard-running-mettalog)
  - [With Docker](#whale-running-mettalog-with-docker)
- Continuous Reports [https://logicmoo.github.io/metta-testsuite/ci/](https://logicmoo.github.io/metta-testsuite/ci/)
- Nightly Reports [https://logicmoo.github.io/metta-wam/nightly/](https://logicmoo.github.io/metta-wam/nightly/)
- More Reports [https://logicmoo.github.io/metta-wam](https://logicmoo.github.io/metta-wam)
- [Testing Readme](https://github.com/logicmoo/metta-testsuite/blob/development/tests/README.md) and [Result Links](https://github.com/logicmoo/metta-testsuite/blob/development/reports/TEST_LINKS.md)
- [Overview Documentation](https://github.com/trueagi-io/metta-wam/blob/master/docs/OVERVIEW.md).


## Getting Started

### :gear: Installation

_Before you get started make sure `pip` and `venv` are working good._


Linux/WSL/OS X
Clone and set up MeTTaLog with the following commands:
```
git clone https://github.com/trueagi-io/metta-wam
cd metta-wam
source ./INSTALL.sh --allow-system-modifications # Follow the default prompts 
```
#### The INSTALL.sh script handles the installation of essential components and updates:
- Ensures Python's `pip` is installed or installs it.
- **Installs or Updates SWI-Prolog** to ensure version 9.3.9 or higher is present.
- **Installs janus**: A Python package that interfaces with SWI-Prolog.
- **Installs pyswip**: Another Python package that provides further integration.
- **Installs hyperon**: Hyperon pip package needed for running compatibility tests.
- **Installs ansi2html**: Unit Test Visibility.
- **Installs junit2html**: Unit Test Reporting.
- **Installs mettalog-vspace**: Allows Rust MeTTa use extra functionality found in mettalog.
- **Installs mettalog-jupyter-kernel**: Work with metta files in Jupyter Notebooks.
- **Installs metakernel**: (No relation!) but allows our Jupyter Kernel to work.

**Note**: Running this script modifies software configurations and installs packages. Ensure you're prepared for these changes.


### Windows Installation

If you’re on **Windows**, follow these steps to install MeTTaLog and create `.metta` file associations:

1. **Install SWI-Prolog (with Janus support)**  
   - You need a version of [SWI-Prolog](https://www.swi-prolog.org/) that includes **Janus** functionality. If you’re compiling from source, see the [SWI-Prolog docs](https://www.swi-prolog.org/build/) for details on building with additional packages.
   
2. **Clone the `metta-wam` repository**  
   ```bash
   git clone https://github.com/trueagi-io/metta-wam
   cd metta-wam
   ```
3. **Run `INSTALL.bat` as Administrator**  
   - Right-click on `INSTALL.bat` and choose **Run as administrator**, **or** open an **elevated** Command Prompt/PowerShell in this folder:
     ```cmd
     INSTALL.bat
     ```
   - This script **modifies the Windows registry** to add the `.metta` file association, so admin privileges are required.
   - When prompted, choose **I** (Install) to associate `.metta` files with **mettalog**.

4. **.metta File Association**  
   - Once installed, you can double-click `.metta` files or launch them from the command line to run inside **mettalog** (backed by SWI-Prolog Janus).

**Uninstalling**  
- Re-run the same `INSTALL.bat` as administrator and pick **U** (Uninstall) to remove the `.metta` association.

**Network Drive Note**  
- If you cloned the repository on a network drive, you may need to **map** that drive in the elevated session. Otherwise, Windows may not recognize the drive letter under administrative privileges.

---

## :whale: Running MeTTaLog with Docker

<details>
  <summary>This section guides you through using Docker to set up</summary>

Ensures that MeTTaLog is isolated from your local filesystem and operates in a controlled environment.

### Building the Docker Image

To create a Docker image with MeTTaLog installed, use the following command:

```bash
docker build -t mettalog .
```

This command constructs a Docker image named `mettalog` based on the Dockerfile in the current directory.

### Interacting with MeTTaLog in Docker

After building the image, you can run MeTTaLog inside a Docker container. This isolates it from your local filesystem, which means it won't have direct access to your local files unless explicitly configured to do so.

To start an interactive container with a bash shell, use:

```bash
docker run -it mettalog bash -l
```

Once inside the container, you have several options to interact with MeTTaLog. See [Running MeTTaLog](#neckbeard-running-mettalog).

### Transferring Files to and from the Container

Docker allows you to copy files between the host and the container, which can be useful for moving scripts or data into the container before running them, or extracting results afterward. Refer to the Docker documentation on [copying files](https://docs.docker.com/engine/reference/commandline/container_cp/) for more details.

For comprehensive information about Docker's capabilities, consult the [Docker manuals](https://docs.docker.com/manuals/) and [reference documentation](https://docs.docker.com/reference/).

</details>

## :neckbeard: Running MeTTaLog

Interact directly with MeTTaLog through the REPL:
```bash
mettalog --repl

metta+> !(+ 1 1)
Deterministic: 2

; Execution took 0.000105 secs. (105.29 microseconds)
metta+>^D   # Exit the REPL with `ctrl-D`.
```

To run a script:
```bash
mettalog examples/puzzles/nalifier.metta
```

To run a script and then enter the repl:
```bash
mettalog examples/puzzles/fish_riddle_1_no_states.metta --repl
metta+>!(query &self (because blue house keeps parrots the $who is the fish owner))
[(Succeed ((quote (because blue house keeps parrots the brit is the fish owner))))]
metta+>!(halt! 7)

```

## Unit tests

One examples is provided in this repository
```bash
mettalog --test examples/tests/unit_test_example.metta
# The output is saved as an HTML file in the same directory.
```

The rest of the tests are in a large REPO @
```bash
git clone https://github.com/logicmoo/metta-testsuite/
ls ./tests/  # this is a symlink that was already made with # ln -s metta-testsuite/tests/ ./tests  
```

Run a single test
```bash
mettalog --test tests/baseline_compat/metta-morph_tests/tests0.metta 
```
Execute baseline sanity tests:
```bash
mettalog --test --clean ./tests/baseline_compat/
```

## :toolbox: Troubleshooting

<details>
  <summary>Some prolog commands not found</summary>

If you already have a recent enough version of SWI-Prolog installed, that will be used instead of mettalog installing its own. Some of the packages might not be installed, and mettalog might give an error such as:

```
ERROR: save_history/0: Unknown procedure el_write_history/2
```

In that case, you need to rebuild your SWI-Prolog installation to include the missing packages. The most reliable way to do this is to make sure the following Debian/Ubuntu packages are installed using:

```
sudo apt install build-essential autoconf git cmake libpython3-dev libgmp-dev libssl-dev unixodbc-dev \
        libreadline-dev zlib1g-dev libarchive-dev libossp-uuid-dev libxext-dev \
        libice-dev libjpeg-dev libxinerama-dev libxft-dev libxpm-dev libxt-dev \
        pkg-config libdb-dev libpcre3-dev libyaml-dev libedit-dev
```

then rebuild SWI-Prolog using the instructions from the [SWI-Prolog -- Installation on Linux, *BSD (Unix)](https://www.swi-prolog.org/build/unix.html). The main part of this (assuming that you are in the `swipl` or `swipl-devel` directory) is:

```
cd build
cmake -DCMAKE_INSTALL_PREFIX=$HOME -DCMAKE_BUILD_TYPE=PGO -G Ninja ..
ninja
ctest -j $(nproc) --output-on-failure
ninja install
```
If you installed SWI-Prolog as a package from your Linux distribution and run into issues, it is likely that you will need to `apt remove` it and then either
* build SWI-Prolog from source making sure that all the operating system packages are installed first, or
* rerun the metta-wam `INSTALL.sh` script.

</details>

## :raised_hands: Acknowledgments
Thanks to the Hyperon Experimental MeTTa, PySWIP teams, and Flybase for their contributions to this project.

## :phone: Support
For queries or suggestions, please open an issue on our [GitHub Issues Page](https://github.com/trueagi-io/metta-wam/issues).

## :scroll: License
MeTTaLog is distributed under the LGPL License, facilitating open collaboration and use.

<details>
  <summary>Prerequisites for using MeTTaLog in Rust</summary>

- A build of [Hyperon Experimental](https://github.com/trueagi-io/hyperon-experimental) is required.
```bash
  /home/user$ metta
  metta> !(import-py! mettalog)
  metta> !(mettalog:repl)
  metta@&self +> !(ensure-loaded! whole_flybase)

  metta@&self +> !(let $query 
                     (, (fbgn_fbtr_fbpp_expanded $GeneID $TranscriptType $TranscriptID $GeneSymbol $GeneFullName $AnnotationID $_ $_ $_ $_ $_) 
					    (dmel_unique_protein_isoforms $ProteinID $ProteinSymbol $TranscriptSymbol $_) 
						(dmel_paralogs $ParalogGeneID $ProteinSymbol $_ $_ $_ $_ $_ $_ $_ $_ $_) 
						(gene_map_table $MapTableID $OrganismAbbreviation $ParalogGeneID $RecombinationLoc $CytogeneticLoc $SequenceLoc) 
						(synonym $SynonymID $MapTableID $CurrentSymbol $CurrentFullName $_ $_))
					(match &self $query $query))
                    
```

```shell
metta> !(test_custom_v_space)

; (add-atom &vspace_8 a)
; (add-atom &vspace_8 b)
; (atom-count &vspace_8)
Pass Test:(Values same: 2 == 2)
Pass Test:(Values same: Test Space Payload Attrib == Test Space Payload Attrib)
; (get-atoms &vspace_8)
Pass Test:( [a, b] == [a, b] )
; (add-atom &vspace_9 a)
; (add-atom &vspace_9 b)
; (add-atom &vspace_9 c)
; (remove-atom &vspace_9 b)
Pass Test:(remove_atom on a present atom should return true)
; (remove-atom &vspace_9 bogus)
Pass Test:(remove_atom on a missing atom should return false)
; (get-atoms &vspace_9)
Pass Test:( [a, c] == [a, c] )
; (add-atom &vspace_10 a)
; (add-atom &v

space_10 b)
; (add-atom &vspace_10 c)
; (atom-replace &vspace_10 b d)
; (add-atom &vspace_10 d)
Pass Test:(Expression is true: True)
; (get-atoms &vspace_10)
Pass Test:( [a, c, d] == [a, d, c] )
; (add-atom &vspace_11 (A B))
; (add-atom &vspace_11 (C D))
; (add-atom &vspace_11 (A E))
; (match &vspace_11 ($_105354) (A $_105354))
; RES: (metta-iter-bind  &vspace_11 (A B) (B))
; RES: (metta-iter-bind  &vspace_11 (A E) (E))
Pass Test:( [ { $xx <- B },
 { $xx <- E } ] == [{xx: B}, {xx: E}] )
; (add-atom &vspace_12 (A B))
Pass Test:(Values same: CSpace == CSpace)
; (match &vspace_12 ($_117600) (A $_117600))
; RES: (metta-iter-bind  &vspace_12 (A B) (B))
Pass Test:( [ { $v <- B } ] == [{v: B}] )
; (add-atom &vspace_12 (big-space None))
; (add-atom &vspace_13 (A B))
; (match &vspace_13 ($_129826) (A $_129826))
; RES: (metta-iter-bind  &vspace_13 (A B) (B))
; (match &vspace_13 ($_135548) (: B $_135548))
Pass Test:(Values same: [[B]] == [[B]])
```

</details>

<details>
  <summary>Python interaction</summary>

Module loading
; using the python default module resolver $PYTHONPATH
`!(import! &self motto.llm_gate)` 
; using the python path
`!(import! &self ../path/to/motto/llm_gate.py)`
; Rust way (was the only way to load llm_gate functions from Rust)
`!(import! &self motto)` 

; Script running
`!(pymain! &self ../path/to/motto/test_llm_gate.py ( arg1 arg2 ))`
; Single methods is python files
`!(pyr! &self ../path/to/motto/test_llm_gate.py "run_tests" ((= verbose True)))`

```
; Can define a shortcut
(: run-llm-tests (-> Bool Ratio))
(= 
  (run-llm-tests $verbose)
  (pyr! &self ../path/to/motto/test_llm_gate.py "run_tests" ((= verbose $verbose))))
```

</details>

<details>
  <summary>MeTTaLog Extras</summary>

```
; For the compiler to know that the member function will be a predicate 
(: member/2 Compiled)

; Declare member/2
(: member/2 Nondeterministic)


; Allow rewrites of member to invert using superpose
(: member/2 (Inverted 1 superpose))


```

```
; MeTTa file loading
!(include! &self ../path/to/motto/test_llm_gate.metta)

; Http Files
!(include! &self https://somewhere/test_llm_gate.metta)
```

```
; interfacing to Prolog
(:> OptionsList (List (^ Expresson (Arity 2))))
(:> ThreadOptions OptionsList)
(:> ThreadId Number)
(: make-thread (-> Expression ThreadOptions ThreadId))
(: thread_create/3 Deterministic)
;; (add-atom &self (Imported thread_create/3 2 make-thread))
(= 
  (make-thread $goal $options)
  (let True 
    (as-tf (thread_create! $goal $result $options))
	$result))

; returns a number and keeps going
!(make-thread (shell! "xeyes") ((detached False)))

```

To get comparable Interp vs Compiler statistics in one Main Output
```
clear ; mettalog --test --v=./src/main --log --html tests/*baseline*/ \
  --output=4-06-main-both --clean
clear ; mettalog --test --v=./src/canary-lng --log --html tests/*baseline*/ \
  --output=4-06-canary-lng-both --clean
clear ; mettalog --test --v=./src/canary --log --html tests/*baseline*/ \
  --output=4-06-canary-wd-both --clean
```

Vs for diffing
```

clear ; mettalog --test --v=./src/canary --log --html --compile=full tests/baseline_compat/ \
  --output=4-06-compile_full --clean

clear ; mettalog --test --v=./src/canary --log --html --compile=false tests/baseline_compat/ \
  --output=4-06-compile_false --clean

```

</details>

<details>
  <summary>Metta Functions Task List</summary>

| Function Name  | Doc. (@doc) | Test Created | Impl. in Interpreter | Impl. in Transpiler | Arg Types Declared |
|----------------|-------------|--------------|----------------------|---------------------|--------------------|
| `functionA`    | - [ ]       | - [ ]        | - [ ]                | - [ ]               | - [ ]              |
| `functionB`    | - [ ]       | - [ ]        | - [ ]                | - [ ]               | - [ ]              |
| `functionC`    | - [ ]       | - [ ]        | - [ ]                | - [ ]               | - [ ]              |

</details>

<details>
  <summary>Launch Jupyter notebook</summary>
 - Contains a Jupyter Kernel for MeTTa (in-progress)
```
./scripts/start_jupyter.sh
```
</details>
