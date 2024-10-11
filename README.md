# POPL'25 Artifact Evaluation

## VitualBox VM
Open VirtualBox and import the provided image.
The image was created using VirtualBox 7.1 on an x86-64bit machine. It contains an Ubuntu Server installation.
Provided within the installation are all tools necessary to evaluate the artifact.

Start the VM, you can either start the VM 
To log in to the VM, use the following:
Username: `popl`
Password: `popl25`

To inspect the outputs, either use the command line or mount the directory /home/popl/outputs on your local machine.
You can do so via sshfs (`sshfs popl25ae-mimir:outputs popl25ae_mimir -o follow_symlinks -o idmap=user -o uid=$(id -u) -o gid=$(id -g)`) or using the VirtualBox mounting facilities: // todo

## Claims

### Soundness


### MimIR Performance Evaluation

For the performance evaluation, the `evaluate.sh` script will build and run the necessary tools.
The steps performed by the script are:
- Install MimIR and Impala (a higher level functional DSL hosting language that uses Mim as code generation target).
- Build and evaluate the Benchmarks Game C and Impala benchmarks
- Build and evaluate the MimIR RegEx plugin benchmark

#### Benchmarks Game
In the paper (6.1), we claim that using Mim with it's low-level plugins allows writing code that is competitive performance-wise to standard C code.

To support this claim, we ported a number of benchmarks from the Benchmarks Game to Impala (a custom language frontend that uses Mim for code generation & optimization).
Compiling these benchmarks through Mim produces binaries that show competitive performance to similar C implementations of the same benchmarks.

After running the `evaluate.sh` script, the results will be found in `output/benchmarksgame`.
You may compare these numbers with `Table 3`.
Note, depending on your setup, the absolute time is expected to change, obviously.
Instead, the ratio between C and Impala is the interesting to observe part.
Background processes in the VM and your local machine may lead to inconsistencies. The benchmarks are repeated a number of times, however, to reduce this effect and present a final averaged number.

#### RegEx


#### AutoDiff
Note: the AutoDiff case-study is just that - a case study, not intended for re-use at the moment.
The AutoDiff evaluation is based on a modified downstream version of MimIR (back then called Thorin2) that contains changes that were not deemed stable enough for incorporation in the upstream MimIR project.
We believe that this case study shows part of the potential of using MimIR for DSL development, but this part is not yet in a state for public use.

The evaluation is based on the docker image `neuralcoder/thornado-ad:hardcode2` that contains the MimIR, Impala, PyTorch and Enzyme versions used for the paper.

## Availability of the artifact
The POPL artifact is available at Zenodo (todo).
However, all parts of the artifact are publicly available online:

The repository https://github.com/AnyDSL/popl25 contains the evaluation scripts & all repositories as submodules that contribute to the artifact.

The main repositories required for reusability are:
- MimIR: The implementation for MimIR - https://github.com/AnyDSL/MimIR
- MimIR Soundness: The Coq infrastructure modelling MimIR's semantics - https://github.com/NeuralCoder3/mimir-soundness


