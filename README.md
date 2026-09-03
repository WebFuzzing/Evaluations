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

This repository not only contains the scaffolding for running experiments on WFD, but also the results of these experiments, done at different points in time. 

When a new experiment is run, we check if any new version of any of the employed fuzzers is out, and update it accordingly.
This check is done for all fuzzers on the same day.

Experiments are repeated `R` times, with an input time budget of `T` minutes.
We use __all__ the `K` APIs in the latest version of WFD at the time of the experiments.  


Currently, in WFE the fuzzers are compared based on 5 metrics:

* HTTP 2xx Coverage: percentage of how many endpoints it was possible to make an HTTP call returning a 2xx status code.

* Number of 500 Server Errors: average number per API of _distinct_ endpoints in which it was possible to make at least one HTTP call returning a 500 status code. 

* Line Coverage: measured with JaCoCo. This is measured during the fuzzing session, and not when executing the generated tests (this latter would like be lower, as in black-box testing the info on coverage is unknown during the fuzzing session). 

* Best On: the number of APIxMetric combinations in which a fuzzer gave the best results, with no ties. Given `K` APIs (e.g., `K=36`) and `M` metrics (e.g., `M=3`), this score can be from 0 to up to `K*M` (e.g., `36*3=108`). This is based on the previous 3 metrics. 

* Overall: overall average of the average rankings of the other 4 compared metrics. 

Given `Z` compared fuzzers,
for each API, for each metric, we rank the fuzzers' performance.
Rank 1 is best, whereas rank `Z` is worst performances. 
In the table results, ranks are shown in `()` parentheses. 
Ties are solved with the average of the ranks. 

### Latest Result Summary

|Tools | %2xx | #500 | %Lines | Best-On | Overall | 
|:---|---:|---:|---:|---:|---:| 
|_aratrl_ | 13.7 (4.6) | 0.7 (4.0) | 23.0 (4.8) | 6 (3) | 4.1 | 
|_cats_ | 18.2 (4.2) | 1.4 (4.0) | 26.3 (4.0) | 1 (6) | 4.5 | 
|_evomaster_ | __51.7 (2.0)__ | __9.2 (2.7)__ | __43.7 (1.8)__ | __36 (1)__ | __1.9__ | 
|_restler_ | 24.0 (3.7) | 0.9 (4.1) | 28.4 (4.2) | 2 (5) | 4.3 | 
|_schemathesis_ | 37.9 (2.6) | 6.8 (2.8) | 39.4 (2.3) | 23 (2) | 2.4 | 
|_wuppiefuzz_ | 18.5 (3.9) | 2.6 (3.4) | 26.6 (3.8) | 4 (4) | 3.8 | 


### Experiment Data

* Aug'26 (R=3,T=2,K=36): [overall](data/26_08_3r_2m/overall.md), [2xx](data/26_08_3r_2m/comparisonAll2xx.md), [500](data/26_08_3r_2m/comparisonAll500.md), [lines](data/26_08_3r_2m/comparisonAllJaCoCo.md)


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
* __AUTH_EXTERNAL_OVERRIDE__: used if needing to override the value of `externalEndpointURL` in WFC auth configurations. Some APIs have authentication services which are run on a different port than __PORT__. As the information in WFC is static, and such port here in the experiments are dynamic, there is a need to be able to override such values. 
* __EXTRA_CONFIGS__: any extra custom parameter, that needs to be manually set up in `scripts/run-tools.py`. This is only used when debugging different configurations of a fuzzer without the need of rebuilding the Docker images.  


When setting up the `Dockerfile` for a new tool, it is important to try to have it ideally as close as possible as its default version, with no specialized options. 
This is to mimic the "default" experience of a user trying to use such fuzzer, without having any depth knowledge of all of its optional parameters. 


## Creating Summary Tables and Plots

TODO