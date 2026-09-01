# Web Fuzzing Evaluations (WFE)

**WARNING**: Documentation is still under construction

The current repository contains scripts to run experiments with different REST API fuzzers on the [Web Fuzzing Dataset (WFD)](https://github.com/WebFuzzing/Dataset), using different fuzzers. 

To use this repository, you only need _Python_ and _Docker_. 
Nothing else needs to be manually installed, as everything (including WFD and the fuzzers) have already been published and can be run via Docker.

## Included APIs and Fuzzers

Current version 4.3.0 of [WFD](https://github.com/WebFuzzing/Dataset) includes 36 APIs. 

The fuzzers currently configured here in WFE are (in alphabetic order):

* [ARAT-RL](https://github.com/codingsoo/ARAT-RL)
* [CATS](https://github.com/Endava/cats)
* [EvoMaster](https://github.com/WebFuzzing/EvoMaster)
* [RESTler](https://github.com/microsoft/restler-fuzzer)
* [Schemathesis](https://github.com/schemathesis/schemathesis)
* [WuppieFuzz](https://github.com/TNO-S3/WuppieFuzz)

## Running Experiments

You can run following Python script:

> python3 scripts/run-tools.py  \<dir> \<minSeed> \<maxSeed> <timeMinutes>

Where: 
* __\<dir>__ is the name of a folder where all the experiment scripts are created and data will be collected
* __\<minSeed>__ and __\<maxSeed>__ represent how often experiments are repeated, starting from seed \<minSeed> to seed \<maxSeed>. A range like (2,4) means that experiments will be repeated 3 times, with seeds 2, 3 and 4. 
* __\<timeMinutes>__ specify for how long each fuzzer should run to test each API.  

Once this script is executed, a list of Bash scripts will be present under `<dir>/scripts`.
Each script represents a single job, of a fuzzer run on a single API. 
These scripts automatically start and stop the APIs, and collect all data like HTTP coverage (via a reversed proxy) and code coverage (via JaCoCo). 
All is automated. 

These bash scripts can be run individually (e.g., useful for debugging), or all in a batch.
For this latter case, it is recommended to use the `schedule.py` script, e.g.:

> python3 scripts/schedule.py \<N> \<FOLDER> \<TIMEOUT_MINUTES> 

Where:
* __\<N>__ is the parallelism, i.e., N jobs will be run in parallel, at most. 
* __\<FOLDER>__ is the folder where the scripts to run are stored, e.g., `<dir>/scripts`.
* __\<TIMEOUT_MINUTES>__ a global timeout for each job, which includes not only the fuzzers, but also the starting/stopping of the APIs. This is needed to avoid issues like Docker hanging forever in some cases.   

## Experiment Results

TODO

## Adding New Fuzzers

Adding a new fuzzer requires 

TODO

## Creating Summary Tables and Plots

TODO