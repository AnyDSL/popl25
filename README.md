# POPL'25 Artifact Evaluation

## VitualBox VM
Open VirtualBox and [import](https://docs.oracle.com/en/virtualization/virtualbox/7.1/user/Introduction.html#ovf-import-appliance) the provided image.
The image was created using VirtualBox 7.1 on an x86-64bit machine. It contains an Ubuntu Desktop installation.
Provided within the installation are all tools necessary to evaluate the artifact.

After starting the VM, log in to the VM, using the following account information:
Username: `popl`
Password: `popl25`

As the outputs are plain text, you can inspect the outputs using your favorite editor of choice (hopefully preinstalled).
For the Coq proofs, we pre-installed VS Code with the necessary extensions.

## Kick The Tires
For the initial kick-the-tires phase, please just run the `./evaluate.sh` script in the `~/popl25` folder and see that everything completes correctly.
This means that you have the following files in `~/popl25/output`:
- `benchmarksgame.csv`
- `benchmark_mail_runtime.csv`
- `benchmark_mail_compiletime`
- `regex_cloc.txt`

## Claims

### Soundness

Running `make` inside `soundness/mimir/` builds the Coq proofs (automatically done by `./evaluate.sh`).
We pre-installed VS Code with the necessary extensions to allow manual inspection of the Coq Proofs.
For this, open VS Code in the folder `soundness/mimir`.

The main file is `soundness/mimir/semantics/types_sol.v` with the progress lemma on [line 140](https://github.com/NeuralCoder3/mimir-soundness/blob/7594a3fc2715c58e907f978b0f4f8762c6192d3d/mimir/semantics/types_sol.v#L140) and preservation on [line 1246](https://github.com/NeuralCoder3/mimir-soundness/blob/7594a3fc2715c58e907f978b0f4f8762c6192d3d/mimir/semantics/types_sol.v#L1246).

**Claim**: We model a relevant portion of MimIR close to the C++-Implementation.
On this model, we prove lemmas regarding the progress and preservation properties of MimIR.

### MimIR Performance Evaluation

For the performance evaluation, the `evaluate.sh` script will build and run the necessary tools.
The steps performed by the script are:
- Install MimIR and Impala (a higher level functional DSL hosting language that uses Mim as code generation target).
- Build and evaluate the Benchmarks Game C and Impala benchmarks
- Build and evaluate the MimIR RegEx plugin benchmark

#### Benchmarks Game
**Claim**: In the paper (6.1), we claim that using MimIR with it's low-level plugins allows writing code that is competitive performance-wise to standard C code.

To support this claim, we ported a number of benchmarks from the Benchmarks Game to Impala (a custom language frontend that uses MimIR for code generation & optimization).
Compiling these benchmarks through MimIR produces binaries that show competitive performance to similar C implementations of the same benchmarks.

After running the `evaluate.sh` script, the results will be found in `output/benchmarksgame.csv`.
You may compare these numbers with `Table 3`.
Note, depending on your setup, the absolute time is expected to change, obviously.
Instead, the ratio between C and Impala is the interesting to observe part.
Background processes in the VM and your local machine may lead to inconsistencies.
The benchmarks are repeated a number of times, however, to reduce this effect and present a final averaged number.

#### RegEx
**Claim**: In the paper (6.2, Table 4), we claim that MimIR allows embedding domain-specific languages and optimizations in a succinct manner while achieving state-of-the-art performance.

We showcase this with a RegEx matcher implementation that makes use of MimIR's normalization framework and its easy integration of domain-specific optimizations.

After running the `evaluate.sh` script, the results will be found at:
- aggregate runtime performance results: `output/benchmark_mail_runtime.csv`
- aggregate compile time performance results: `output/benchmark_mail_compiletime` (lists the input/output file and the `user` compile time)
- aggregate line of code counts: `output/regex_cloc.txt`.

Regarding interpretation of the timing results:
Depending on the hardware the benchmarks are run on, individual times will vary.
However, the expectation is that the relative performance of the implementations will be roughly similar compared to the paper results.
Refer to `Table 4` for our results.

Note, for some reason, the compile time performance test unnecessarily compiles the MimIR file twice.
That's a build-system issue, not a MimIR limitation.
Just use either value.

The line of code (LoC) metrics depend on:
- the submodule of CTRE, that we use for the benchmark as well, the numbers should match the paper.
- for pcre2 we checkout the repo at the commit we did the initial evaluation with, the numbers should thus match the paper.
- for std::regex we use the installed C++ standard library, the numbers therefore might differ slightly from those in the paper.
- for the manual implementation we merely inspect the relevant file in the benchmark folder (`manual_match_mail.cpp`), the numbers therefore should match the paper.
- for MimIR, we refer to the relevant files in the top level MimIR repository (`mim/plug/regex`, `automaton` in both `include` and `src`), these numbers should match the paper.


#### AutoDiff
Note: the AutoDiff case-study is just that - a case study, not intended for re-use at the moment.
The majority of the AutoDiff infrastructure is indeed available in the primary MimIR repository.
However, the AutoDiff evaluation is based on a modified downstream version of MimIR (back then called Thorin2) that contains changes (primarily optimizations) that were not deemed stable enough for incorporation in the upstream MimIR project, yet.
We believe that this case study shows part of the potential of using MimIR for DSL development, but this part is not 100% in a state for public use, yet.

Therefore, the evaluation is based on the docker image `fodinabor/mimir-ad-bench:gmm` that contains the MimIR, Impala, PyTorch and Enzyme versions used for the paper.

The AutoDiff work shows that MimIR lends itself quite nicely to developing efficient DSLs on top.
By making use of the IR's functional principles, the task of auto differentiation can be solved in a compact implementation and even performs great.

**Claim**: In the paper (6.3) we claim that our AutoDiff implementation is much more compact due to MimIR's design than comparable implementations on LLVM IR (Enzyme).
Todo: calculate metrics again.

**Claim**: In the paper, we also claim that the performance is still comparable to state-of-the-art auto differentiation tools (PyTorch, Enzyme).
After running `./evaluate.sh` the results will be found in output/autodiff`.
You can find a plot of the results in `output/autodiff/gmm.pdf`. Compare this to `Fig. 8.` in the paper.

To keep the runtime of the artifact reasonable, we only run the GMM benchmark on a subset of tools and sizes.
Therefore, the plot will only show an approximation of the graph for sizes below $5*10^3$.
To run a more extensive evaluation, you may execute `sudo docker run -ti -v "`pwd`/output:/output" -e FOLDERS="<SELECT YOUR SIZES>" fodinabor/mimir-ad-bench:gmm`, where supported sizes are `10k_small 10k 10k_D128 10k_K100 10k_D256 10k_K200`.

## Availability of the artifact
The POPL artifact is available at Zenodo (todo).
However, all parts of the artifact are publicly available online:
[This GitHub repository](https://github.com/AnyDSL/popl25) contains the evaluation scripts & all repositories as submodules that contribute to the artifact.

The main repositories required for reusability are:
- [MimIR](https://github.com/AnyDSL/MimIR): The implementation for MimIR
- [MimIR Soundness](https://github.com/NeuralCoder3/mimir-soundness): The Coq infrastructure modelling MimIR's semantics
