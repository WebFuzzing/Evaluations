# Web Fuzzing Evaluations (WFE)

The current repository contains scripts to run experiments with different REST API fuzzers on the [Web Fuzzing Dataset (WFD)](https://github.com/WebFuzzing/Dataset), using different fuzzers. 

To use this repository, you only need _Python_ and _Docker_ (and _R_ if you want to run the automated result analyses). 
Nothing else needs to be manually installed, as everything (including WFD and the fuzzers) have already been published and can be run via Docker.

## Included APIs and Fuzzers

Current version 4.4.0 of [WFD](https://github.com/WebFuzzing/Dataset) includes 56 APIs. 

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

This repository not only contains the scaffolding for running experiments on WFD, but also the results of these experiments, done at different points in time. 

When a new experiment is run, we check if any new version of any of the employed fuzzers is out, and update it accordingly.
This check is done for all fuzzers on the same day.

Experiments are repeated `R` times, with an input time budget of `T` minutes.
We use __all__ the `K` APIs in the latest version of WFD at the time of the experiments.  


Currently, in WFE the fuzzers are compared based on 5 metrics:

* _HTTP 2xx Coverage_: percentage of how many endpoints it was possible to make an HTTP call returning a 2xx status code.

* _Number of 500 Server Errors_: average number per API of _distinct_ endpoints in which it was possible to make at least one HTTP call returning a 500 status code. 

* _Line Coverage_: measured with JaCoCo. This is measured during the fuzzing session, and not when executing the generated tests (this latter would like be lower, as in black-box testing the info on coverage is unknown during the fuzzing session). 

* _Best On_: the number of APIxMetric combinations in which a fuzzer gave the best results, with no ties. Given `K` APIs (e.g., `K=36`) and `M` metrics (e.g., `M=3`), this score can be from 0 to up to `K*M` (e.g., `36*3=108`). This is based on the previous 3 metrics. 

* _Overall_: overall average of the average rankings of the other 4 compared metrics. 

Given `Z` compared fuzzers,
for each API, for each metric, we rank the fuzzers' performance.
Rank 1 is best, whereas rank `Z` is for the worst performance. 
In the table results, ranks are shown in `()` parentheses. 
Ties are solved with the average of the ranks. 

For each fuzzer, we also keep track of all the different types of faults they found, if those are reported with [WFC format](https://github.com/WebFuzzing/Commons).
However, as those values are self-reported by each fuzzer, particular care needs to be taken when comparing results.

### Latest Result Summary

|Tools | %2xx | #500 | %Lines | Best-On | Overall | 
|:---|---:|---:|---:|---:|---:|
|_cats_ | __72.6 (1.9)__ | __35.3 (1.6)__ | __50.4 (1.8)__ | __57 (1)__ | __1.6__ | 
|_evomaster_ | 58.2 (2.6) | 14.4 (3.2) | 43.7 (2.7) | 13 (3) | 2.9 | 
|_schemathesis_ | 69.3 (2.0) | 29.1 (1.7) | 49.7 (1.9) | 36 (2) | 1.9 | 
|_wuppiefuzz_ | 29.9 (3.5) | 4.4 (3.5) | 29.6 (3.7) | 1 (4) | 3.7 | 


### Experiment Data

* __0.1.0__, Nov'26 (R=10,T=10,K=56): [overall](data/26_11_16_10r_10m/overall.md), [2xx](data/26_11_16_10r_10m/comparisonAll2xx.md), [500](data/26_11_16_10r_10m/comparisonAll500.md), [lines](data/26_11_16_10r_10m/comparisonAllJaCoCo.md), [faults](data/26_11_16_10r_10m/comparisonFaults.md)
* __0.0.3__, Oct'26 (R=3,T=10,K=55): [overall](data/26_10_23_3r_10m/overall.md), [2xx](data/26_10_23_3r_10m/comparisonAll2xx.md), [500](data/26_10_23_3r_10m/comparisonAll500.md), [lines](data/26_10_23_3r_10m/comparisonAllJaCoCo.md)
* __0.0.2__, Sep'26 (R=3,T=2,K=36): [overall](data/26_09_09_3r_2m/overall.md), [2xx](data/26_09_09_3r_2m/comparisonAll2xx.md), [500](data/26_09_09_3r_2m/comparisonAll500.md), [lines](data/26_09_09_3r_2m/comparisonAllJaCoCo.md)
* __0.0.1__, Aug'26 (R=3,T=2,K=36): [overall](data/26_08_3r_2m/overall.md), [2xx](data/26_08_3r_2m/comparisonAll2xx.md), [500](data/26_08_3r_2m/comparisonAll500.md), [lines](data/26_08_3r_2m/comparisonAllJaCoCo.md)


## Adding New Fuzzers

We are keen to add new fuzzers to WFE.
You can make a PR, or drop us a message if you are interested. 

Adding a new fuzzer requires to create a new Docker file, in a way that should be easy to update when a new version of the fuzzer comes out. 
For example, instead of manually copy a binary file, it could be dowloand from GitHub release via `ADD`. 

The new `Dockerfile` needs to be added under `tools`. You can see the existing files there to use them as a reference.
A new entry to `docker build` the image needs to be added to `scripts/build.sh`, as well as adding a new entry in the `TOOLS` array in `scripts/run-tools`.  

Each fuzzer docker container is started in exactly the same way. 
Inputs (e.g., which OpenAPI schema to use) are provided via environment variables. 
Those are:

* __HOST__: the hostname where the API is running.
* __PORT__: the port of where the API is expecting a TCP connection.
* __SCHEMA_FILE_PATH__: file location of where the OpenAPI schema of the API is located. This will be automatically mounted to the container when it is started. 
* __TIME_SECONDS__: for how long the fuzzer is expected to run. Note that experiments will automatically have a grace period (e.g., 1 minute) before forcing a termination if the Docker container of the fuzzer is still running after that amount of time. 
* __OUTPUT_FOLDER__: where to save the results of the fuzzing (e.g., any generated test case). Such folder is automatically mounted in the Docker image, so that results can then be accessed under `<dir>/tests` once the experiments are finished. 
* __AUTH_FILE_PATH__: location of authentication information, in [WFC format](https://github.com/WebFuzzing/Commons), if the API requires it (if not, this will be empty).
* __EXTRA_CONFIGS__: any extra custom parameter, that needs to be manually set up in `scripts/run-tools.py`. This is only used when debugging different configurations of a fuzzer without the need of rebuilding the Docker images.  


When setting up the `Dockerfile` for a new tool, it is important to try to have it ideally as close as possible as its default version, with no specialized options. 
This is to mimic the "default" experience of a user trying to use such fuzzer, without having any depth knowledge of all of its optional parameters. 


## Creating Summary Tables and Plots

The folder `r-analysis` contains several scripts to generate figures and tables to analyze the results of the experiments generated with `run-tools.py`. 
All those files have documentation, specifying how to use them, and what kind of analysis they can provide. 

To simplify the analyses, we also provide two scripts to generate a preset types of analysis. 
Assuming the scripts generated by `run-tools.py` are somewhere inside a folder named `results` directly under the root of this project, doing in R a:

> source("results-init.R")

will scan all the experiment results under `results`, and create CSV files (e.g., `results/data_http_bb.csv`) gathering all the needed data from the experiments' results. 
Once those CSV files are created, you can run:

> source("results-analyze.R")

It will create a `generated_files` folder, with all the results of the analyses (e.g., tables in Latex and Markdown formats).  