#!/usr/bin/env python

## Script Build for Black-Box Experiments

import sys
import os
import stat
import pathlib
import shutil
import math
import subprocess
import re

# The version of Web Fuzzing Evaluations we are using in this study.
WFE_VERSION = "0.0.3"

# The version of Web Fuzzing Dataset we are using in this study.
WFD_VERSION = "4.3.0"


# Prefix use to determine the Docker images of the tools published in WFE
TOOL_NAME_PREFIX = "wfe"
# Reference used by tools to connect to "localhost" of the host machine, needed to connect to the SUTs
LOCALHOST = "host.docker.internal"
# Folder inside docker images to where the tools should write their results
DOCKER_OUTPUT_FOLDER = "/output"


### Named optional parameters
LABEL_tools = "tools"
LABEL_suts = "suts"
LABELS = [LABEL_tools,LABEL_suts]

N_PARAMS = 5

# recall sys.argv[0] is the script name
if len(sys.argv) < N_PARAMS:
    print("Usage:\n<nameOfScript>.py <dir> <minSeed> <maxSeed> <timeMinutes> named_param=? ... named_param=?")
    print("Available named parameters: " + str(LABELS))
    exit(1)

# When creating a new set of experiments, all needed files will be saved in a folder
BASE_DIR = os.path.abspath(sys.argv[1])

# Experiments are repeated a certain number of times, with different seed for the
# random generator (if option is available). This specifies the starting seed.
MIN_SEED = int(sys.argv[2])

# Max seed, included. For example, if running min=10 and max=39, each experiment is
# going to be repeated 30 times, starting from seed 10 to seed 39 (both included).
MAX_SEED = int(sys.argv[3])

#For how long tools should be run, in minutes. Some extra time is given automatically on top of this.
MAX_TIME_MINUTES = int(sys.argv[4])


### main input parameter validation
if MIN_SEED > MAX_SEED:
    print("ERROR: min seed is greater than max seed")
    exit(1)

# String to filter tools to be included.
# A string could refer to multiple tools separated by a `,` like a,b
# None represents all tools should be included.
# Default is None.
TOOL_FILTER = None

# An optional string to filter SUTs to be included based on their names
# A string could refer to multiple SUTs separated by a `,` like a,b
# Note that None represents all SUTs should be included
# and only consider unique ones, eg, create one experiment setting for a,a
# Default is None
SUT_FILTER = None


### Derived named variables ###
if len(sys.argv) > N_PARAMS:
    # There might be better ways to build such map in Python...
    options = sys.argv[N_PARAMS:len(sys.argv)]
    keys   = [x.lower() for x in list(map(lambda z: z.split("=")[0], options))]
    values = list(map(lambda z: z.split("=")[1], options))
    kv = dict(zip(keys,values))

    if LABEL_tools in kv:
        TOOL_FILTER = kv[LABEL_tools]

    if LABEL_suts in kv:
        SUT_FILTER = kv[LABEL_suts]

    for key in kv:
        if key not in LABELS:
            print("Undefined option: '" + key +"'. Available options: ")
            print(*LABELS)
            exit(1)


# WFD is going to be automatically installed via Docker
WFD_DIR = BASE_DIR + "/wfd"


# base seeds used for runs. TCP port bindings will be based on such seed.
# If running new experiments while some previous are still running, to avoid TCP port
# conflict, can use an higher base seed. Each run reserves 10 ports. So, if you run
# 500 jobs with starting seed 10000, you will end up using ports up to 15000
BASE_SEED = 10000


SRC_DIR = os.path.dirname(os.path.abspath(__file__))

MAX_TIME_SECONDS = MAX_TIME_MINUTES * 60
# Add an extra 20%, ie 12m on a 1h run
TIMEOUT_MINUTES = math.ceil(MAX_TIME_MINUTES * 1.2)

TIMEOUT_BIN = shutil.which("timeout") or shutil.which("gtimeout")
if TIMEOUT_BIN is None:
    raise Exception("Neither 'timeout' nor 'gtimeout' command found. On macOS, please run: 'brew install coreutils'")
TIMEOUT_COMMAND = f"\"{TIMEOUT_BIN}\" {TIMEOUT_MINUTES}m "

if not os.path.isdir(BASE_DIR):
    print("creating folder: " + BASE_DIR)
    os.makedirs(BASE_DIR)
else:
    print("ERROR: target folder already exists")
    exit(1)


class Tool:
    def __init__(self, name, label, extra_config):
        # the name of the tool, exactly the same as the folder names in the folder "tools"
        self.name = name
        # the label used to identify this tool, usually the same as 'name'.
        # But can be different when running same tool in different configurations
        self.label = label
        # extra configs given to tool, custom and specific to it.
        # this is to enable experimenting different configurations without need to build any custom Docker image
        self.extra_config = extra_config


class Sut:
    def __init__(self, name, auth, sleep, schemaformat, classfiles):
        self.name = name
        # whether it needs authentication info
        self.auth = auth
        # for how long script will sleep after Docker Compose is started...
        # to avoid fuzzing while API not initialized yet
        self.sleep = sleep
        # format (eg json/yaml) of OpenAPI schema in the benchmark
        self.schemaformat = schemaformat
        # relative location of class files, needed for JaCoCo computations
        self.classfiles = classfiles



SLEEP=180
YAML="yaml"
JSON="json"

SUTS = [
    Sut("adoptme",False,SLEEP,JSON,["jdk_21_maven/cs/rest/adoptme/target/classes"]),
    Sut("arimaa",True,SLEEP,JSON,["jdk_21_maven/cs/rest/arimaa/target/classes"]),
    Sut("bibliothek",False,SLEEP,JSON,["jdk_17_gradle/cs/rest/bibliothek/build/classes"]),
    Sut("blogapi",True, SLEEP,JSON,["jdk_8_maven/cs/rest/original/blogapi/target/classes"]),
    Sut("catwatch",False,SLEEP,JSON,["jdk_8_maven/cs/rest/original/catwatch/catwatch-backend/target/classes"]),
    Sut("commafeed",True,SLEEP,JSON,["jdk_25_maven/cs/rest/commafeed/commafeed-server/target/classes"]),
    Sut("cwa-verification",False,SLEEP,JSON,["jdk_11_maven/cs/rest/cwa-verification-server/target/classes"]),
    Sut("digitalbanking",False,SLEEP,JSON,["jdk_17_maven/cs/rest/digitalbanking/target/classes"]),
    Sut("erc20-rest-service",False,SLEEP,JSON,["jdk_8_gradle/cs/rest/erc20-rest-service/build/classes"]),
    Sut("familie-ba-sak",True,SLEEP,JSON,["jdk_17_maven/cs/rest/familie-ba-sak/target/classes"]),
    Sut("features-service",False,SLEEP,JSON,["jdk_8_maven/cs/rest/original/features-service/target/classes"]),
    Sut("flight-search-api",True,SLEEP,JSON,["jdk_21_maven/cs/rest/flight-search-api/target/classes"]),
    Sut("gdpr-kv",False,SLEEP,JSON,["jdk_21_gradle/cs/rest/gdpr-kv/build/classes"]),
    Sut("genome-nexus",False,SLEEP,JSON,["jdk_8_maven/cs/rest-gui/genome-nexus/component/target/classes",
                                   "jdk_8_maven/cs/rest-gui/genome-nexus/model/target/classes",
                                   "jdk_8_maven/cs/rest-gui/genome-nexus/persistence/target/classes",
                                   "jdk_8_maven/cs/rest-gui/genome-nexus/service/target/classes",
                                   "jdk_8_maven/cs/rest-gui/genome-nexus/web/target/classes"]),
    Sut("gestaohospital",False,SLEEP,JSON,["jdk_8_maven/cs/rest-gui/gestaohospital/target/classes"]),
    Sut("http-patch-spring",False,SLEEP,JSON,["jdk_11_maven/cs/rest/http-patch-spring/target/classes"]),
    Sut("jasper",True,SLEEP,JSON,["jdk_25_maven/cs/rest/jasper/target/classes"]),
    Sut("joinus",True,SLEEP,JSON,["jdk_21_maven/cs/rest/joinus/target/classes"]),
    Sut("kafka-rest",False,SLEEP,JSON,["jdk_17_maven/cs/rest/kafka-rest/kafka-rest/target/classes"]),
    Sut("komga",True,SLEEP,JSON,["jdk_17_gradle/cs/rest/komga/komga/build/classes"]),
    Sut("languagetool",False,SLEEP,JSON,["jdk_8_maven/cs/rest/original/languagetool/languagetool-core/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-gui-commons/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/all/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/ar/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/ast/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/be/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/br/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/ca/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/da/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/de/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/de-DE-x-simple-language/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/el/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/en/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/eo/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/es/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/fa/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/fr/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/ga/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/gl/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/is/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/it/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/ja/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/km/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/lt/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/ml/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/nl/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/pl/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/pt/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/ro/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/ru/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/sk/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/sl/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/sv/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/ta/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/tl/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/uk/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-language-modules/zh/target/classes",
                                   "jdk_8_maven/cs/rest/original/languagetool/languagetool-server/target/classes"]),
    Sut("lovemining",True,SLEEP,JSON,["jdk_21_maven/cs/rest/lovemining/target/classes"]),
    Sut("management-cassandra",False,SLEEP,JSON,["jdk_11_maven/cs/rest/management-cassandra/management-api-server/target/classes",
                             "jdk_11_maven/cs/rest/management-cassandra/management-api-common/target/classes"]),
    Sut("market",True,SLEEP,JSON,["jdk_11_maven/cs/rest-gui/market/market-core/target/classes",
                             "jdk_11_maven/cs/rest-gui/market/market-rest/target/classes",
                             "jdk_11_maven/cs/rest-gui/market/market-web/target/classes"]),
    Sut("microcks",True,SLEEP,JSON,["jdk_21_maven/cs/rest-gui/microcks/commons/model/target/classes",
                                    "jdk_21_maven/cs/rest-gui/microcks/commons/util/target/classes",
                                    "jdk_21_maven/cs/rest-gui/microcks/commons/util-el/target/classes",
                                    "jdk_21_maven/cs/rest-gui/microcks/distro/uber/target/classes",
                                    "jdk_21_maven/cs/rest-gui/microcks/distro/uber-async-minion/target/classes",
                                    "jdk_21_maven/cs/rest-gui/microcks/minions/async/target/classes",
                                    "jdk_21_maven/cs/rest-gui/microcks/webapp/target/classes"]),
    Sut("movies-xml",False,SLEEP,JSON,["jdk_21_maven/cs/rest/movies-xml/target/classes"]),
    Sut("notebook-manager",False,SLEEP,JSON,["jdk_8_maven/cs/rest/original/notebook-manager/target/classes"]),
    Sut("ocvn",True,SLEEP,JSON,["jdk_8_maven/cs/rest-gui/ocvn/persistence/target/classes",
                           "jdk_8_maven/cs/rest-gui/ocvn/persistence-mongodb/target/classes",
                           "jdk_8_maven/cs/rest-gui/ocvn/web/target/classes"]),
    Sut("ohsome-api",False,SLEEP,JSON,["jdk_17_maven/cs/rest/ohsome-api/target/classes"]),
    Sut("pay-publicapi",True,SLEEP,JSON,["jdk_11_maven/cs/rest/pay-publicapi/target/classes"]),
    Sut("person-controller",False,SLEEP,JSON,["jdk_21_maven/cs/rest/person-controller/target/classes"]),
    Sut("petclinic-rest",False,SLEEP,JSON,["jdk_17_maven/cs/rest/petclinic-rest/target/classes"]),
    Sut("pn-paper-tracker",False,SLEEP,YAML,["jdk_21_maven/cs/rest/pn-paper-tracker/target/classes"]),
    Sut("proxyprint",True,SLEEP,JSON,["jdk_8_maven/cs/rest/original/proxyprint/target/classes"]),
    Sut("quartz-manager",True,SLEEP,JSON,["jdk_11_maven/cs/rest-gui/quartz-manager/quartz-manager-parent/quartz-manager-common/target/classes",
                                          "jdk_11_maven/cs/rest-gui/quartz-manager/quartz-manager-parent/quartz-manager-starter-api/target/classes",
                                          "jdk_11_maven/cs/rest-gui/quartz-manager/quartz-manager-parent/quartz-manager-starter-persistence/target/classes",
                                          "jdk_11_maven/cs/rest-gui/quartz-manager/quartz-manager-parent/quartz-manager-starter-security/target/classes",
                                          "jdk_11_maven/cs/rest-gui/quartz-manager/quartz-manager-parent/quartz-manager-web-showcase/target/classes",]),
    Sut("redis-sample",False,SLEEP,JSON,["jdk_21_maven/cs/rest/redis-sample/target/classes"]),
    Sut("reservations-api",True,SLEEP,JSON,["jdk_11_gradle/cs/rest/reservations-api/build/classes"]),
    Sut("rest-ncs",False,SLEEP,JSON,["jdk_8_maven/cs/rest/artificial/ncs/target/classes"]),
    Sut("rest-news",False,SLEEP,JSON,["jdk_8_maven/cs/rest/artificial/news/target/classes"]),
    Sut("rest-scs",False,SLEEP,JSON,["jdk_8_maven/cs/rest/artificial/scs/target/classes"]),
    Sut("restcountries",False,SLEEP,YAML,["jdk_8_maven/cs/rest/original/restcountries/target/classes"]),
    Sut("scout-api",True,SLEEP,JSON,["jdk_8_maven/cs/rest/original/scout-api/api/target/classes",
                                "jdk_8_maven/cs/rest/original/scout-api/auth/target/classes",
                                "jdk_8_maven/cs/rest/original/scout-api/data-access/target/classes",
                                "jdk_8_maven/cs/rest/original/scout-api/data-batch-jobs/target/classes"]),
    Sut("session-service",False,SLEEP,JSON,["jdk_8_maven/cs/rest/original/session-service/target/classes"]),
    Sut("spring-actuator-demo",True,SLEEP,JSON,["jdk_8_maven/cs/rest/original/spring-actuator-demo/target/classes"]),
    Sut("spring-batch-rest",False,SLEEP,JSON,["jdk_8_maven/cs/rest/original/spring-batch-rest/api/target/classes",
                                              "jdk_8_maven/cs/rest/original/spring-batch-rest/util/target/classes"]),
    Sut("spring-ecommerce",True,SLEEP,JSON,["jdk_8_maven/cs/rest/original/spring-ecommerce/target/classes"]),
    Sut("spring-rest-example",False,SLEEP,JSON,["jdk_17_maven/cs/rest/spring-rest-example/target/classes"]),
    Sut("swagger-petstore",False,SLEEP,JSON,["jdk_8_maven/cs/rest/original/swagger-petstore/target/classes"]),
    Sut("testing-system",True,SLEEP,JSON,["jdk_21_maven/cs/rest/testing-system/target/classes"]),
    Sut("tiltaksgjennomforing",True,SLEEP,JSON,["jdk_17_maven/cs/rest/tiltaksgjennomforing/target/classes"]),
    Sut("traccar",True,SLEEP,JSON,["jdk_21_gradle/cs/rest/traccar/build/classes"]),
    Sut("tracking-system",True,SLEEP,JSON,["jdk_11_maven/cs/rest/tracking-system/target/classes"]),
    Sut("user-management",False,SLEEP,JSON,["jdk_8_maven/cs/rest/original/user-management/target/classes"]),
    Sut("webgoat",True,SLEEP,JSON,["jdk_21_maven/cs/rest-gui/webgoat/target/classes"]),
    Sut("youtube-mock",False,SLEEP,YAML,["jdk_8_maven/cs/rest/original/youtube-mock/target/classes"]),
]

if SUT_FILTER is not None:
    filteredsut = []
    for s in list(set(SUT_FILTER.split(","))):
        found = list(filter(lambda x: x.name.lower() == s.lower(), SUTS))
        if len(found) == 0:
            print("ERROR: cannot find the specified SUT "+s)
            exit(1)
        filteredsut.extend(found)
    SUTS = filteredsut


SCRIPT_DIR = BASE_DIR+"/scripts"
RESULT_SCRIPT_DIR = BASE_DIR+"/result_scripts"
LOGS_DIR   = BASE_DIR+"/logs"
TESTS_DIR  = BASE_DIR+"/tests"
# online: coverage during the fuzzing session
JACOCO_ONLINE_DIR = BASE_DIR+"/jacoco-online"
EXEC_ONLINE_DIR = BASE_DIR+"/exec-online"
# test: coverage during executing generated tests
JACOCO_TEST_DIR = BASE_DIR+"/jacoco-test"
EXEC_TEST_DIR = BASE_DIR+"/exec-test"
MODIFIED_AUTH = BASE_DIR + "/modified-auth"

# Do write on disk the content of 'code' as an executable bash script
def writeScript(basedir, code, port, tool_label, sut_name):
    script_path = basedir + "/" + tool_label  + "_" + sut_name + "_" + str(port) + ".sh"
    script = open(script_path, "w")
    script.write(code)

    st = os.stat(script_path)
    os.chmod(script_path, st.st_mode | stat.S_IEXEC)

def dockerId(port):
    return "id"+str(port)

# Custom code to wait for when SUT is up and running, and able to answer to HTTP requests
def getWaitForSutFunction():
    s  = "wait_for_sut() {\n"
    s += "    local host_port=\"$1\"\n"
    s += "    local max_wait=\"${2:-600}\"\n"
    s += "    local interval=10\n"
    s += "    local elapsed=0\n"
    s += "\n"
    s += "    echo \"Waiting for SUT on port $host_port (max: ${max_wait}s)...\"\n"
    s += "\n"
    s += "    while [ $elapsed -lt $max_wait ]; do\n"
    s += "        sleep $interval\n"
    s += "        elapsed=$((elapsed + interval))\n"
    s += "\n"
    s += "        http_code=$(curl -s -o /dev/null -w \"%{http_code}\" --connect-timeout 5 --max-time 10 \"http://localhost:$host_port\" 2>/dev/null)\n"
    s += "        if [ -n \"$http_code\" ] && [ \"$http_code\" -ge 100 ] 2>/dev/null; then\n"
    s += "            echo \"SUT is ready after ${elapsed}s (HTTP $http_code on port $host_port)\"\n"
    s += "            return 0\n"
    s += "        fi\n"
    s += "\n"
    s += "        echo \"Still waiting... ${elapsed}s / ${max_wait}s (port $host_port not responding)\"\n"
    s += "    done\n"
    s += "\n"
    s += "    echo \"WARNING: Timeout after ${max_wait}s, proceeding anyway...\"\n"
    s += "}\n\n"
    return s



def getScriptHead(port,tool_label,sut, exec_dir):
    s = ""
    s += "#!/bin/bash \n\n"
    s += "SUT=\"" + WFD_DIR + "/dockerfiles/"+sut.name+".yaml\" \n"
    s += "\n"

    s += getWaitForSutFunction()

    # These environment variables are read inside Docker Compose
    # Must be on same line of docker, so that why using \.
    # Note: there must be NOTHING after the \, not even empty space " "...
    s += "HOST_PORT="+str(port) + " \\\n"
    s += "JACOCO_PORT="+str(port+1) + " \\\n"
    s += "AUTH_PORT="+str(port+2) + " \\\n"
    s += "HOST_LOG_DIR=\"" + exec_dir +  "\" \\\n"
    s += "MITM_LOG_FILE=" + getFileNamePrefix(sut.name,tool_label,port) + "__minlog.csv \\\n"
    #  Start SUT with Docker Compose
    s += "docker-compose --project-name "+dockerId(port) + " -f $SUT up --build --force-recreate " \
        + getRedirectLog(getLogFile("sut",tool_label,sut.name,port)) + "  & \n\n"

    # Wait until HTTP endpoint on target port responds (or timeout)
    s += "wait_for_sut " + str(port) + " " + str(sut.sleep)
    s += "  " + getRedirectLog(getLogFile("startup-wait",tool_label,sut.name,port)) +"\n"
    s += "\n\n"

    return s

def getScriptFooter(port,tool_label,sut, exec_dir, jacoco_dir):
    s = "\n\n"

    exec_docker = "/execFiles"
    filename =  getFileNamePrefix(sut.name,tool_label,port) + "__jacoco"
    execFilePath = exec_docker + "/" + filename + ".exec"

    s += "docker run --rm -v \"" + exec_dir+"\":"+ exec_docker +"  \\\n"
    s += "  webfuzzing/wfd-jacoco:" + WFD_VERSION + " \\\n"
    s += "    dump  --address " + LOCALHOST + " --port "+str(port+1)+" \\\n"
    s += "    --destfile " + execFilePath + " \\\n"
    s += "  " + getRedirectLog(getLogFile("jacoco-dump",tool_label,sut.name,port)) +"\n"

    s += "\n"
    s += "sleep 30\n"
    s += "\n"

    # once fuzzer is completed, shut down Docker Compose
    s += "docker-compose -f $SUT down --remove-orphans"
    s += "  " + getRedirectLog(getLogFile("shutdown",tool_label,sut.name,port)) +"\n"
    s += "\n\n"

    s += "# unfortunately, 'down' is not reliable... can leave images and networks up and running\n"
    s += "sleep 30\n"
    id = dockerId(port)
    s += "docker ps -q --filter \"label=com.docker.compose.project="+id+"\" | xargs -r docker stop"
    s += "  " + getRedirectLog(getLogFile("shutdown",tool_label,sut.name,port)) +"\n"
    s += "\n\n"

    s += "sleep 30\n\n"

    s += "docker-compose --project-name " +  id + " -f $SUT rm -f"
    s += "  " + getRedirectLog(getLogFile("shutdown",tool_label,sut.name,port)) +"\n"
    s += "\n"

    s += "docker network rm "+ id+"_default "
    s += "  " + getRedirectLog(getLogFile("shutdown",tool_label,sut.name,port)) +"\n"
    s += "\n"
    s += "\n"


    jacoco_docker = "/resultsJacoco"

    s += "docker run --rm \\\n"
    s += " -v \"" + exec_dir+"\":"+ exec_docker +"  \\\n"
    s += " -v \"" + jacoco_dir+"\":"+ jacoco_docker +"  \\\n"
    s += " webfuzzing/wfd-jacoco:" + WFD_VERSION + " \\\n"
    s += "   report " + execFilePath+ " \\\n"
    for path in sut.classfiles:
        s += "    --classfiles /classfiles/" + path + " \\\n"
    s += "    --csv \"" + jacoco_docker + "/" + filename + ".csv\" \\\n"
    s += "  " + getRedirectLog(getLogFile("jacoco-report",tool_label,sut.name,port)) +"\n"

    return s


def getFileNamePrefix(sut_name,tool_label,port):
    return sut_name +"__" + tool_label +"__" + str(port)


def getDockerToolSetup(testdir,outputFolder,timeSeconds,host,port,sut,extra_config):

     schemasFolder = "/schemas"
     authFolder    = "/auth"
     authFile = sut.name + "-auth" + str(port) + ".yaml"
     authTarget = authFolder + "/" + authFile

     # here we connect on the host... an alternative would be to mount on same network of docker-compose
     # of the SUT... but that would be complicated, and harder for debugging
     s =  " --add-host="+LOCALHOST+":host-gateway \\\n"
     # let's make sure we can access the results of the fuzzing session, ie, generated files, if any
     s += " -v \""+testdir+"\":"+outputFolder + " \\\n"
     # schemas and auth configurations are mounted in :ro read-only
     s += " -v \"" + WFD_DIR + "/openapi\":" + schemasFolder + ":ro  \\\n"
     s += " -v \"" + MODIFIED_AUTH + "/" + authFile + "\":" + authTarget + ":ro \\\n"

     # env variables
     s += " -e OUTPUT_FOLDER=\"" + outputFolder + "\" \\\n"
     s += " -e TIME_SECONDS="+str(timeSeconds) + " \\\n"
     s += " -e HOST=\""+host + "\" \\\n"
     s += " -e PORT="+ str(port) + " \\\n"
     s += " -e SCHEMA_FILE_PATH=\"" + schemasFolder + "/" +sut.name + "." +sut.schemaformat + "\" \\\n"
     s += " -e EXTRA_CONFIGS=\"" + extra_config + "\" \\\n"

     if sut.auth:
        s += " -e AUTH_FILE_PATH=\"" + authTarget + "\" \\\n"

     return s


def getLogFile(config_label, tool_label, sut_name, port):
    return pathlib.PurePath(LOGS_DIR + "/"+ tool_label + "__" +  sut_name + "__" + str(port)+"__" +config_label + ".txt").as_posix()

def getRedirectLog(logs):
    # no point in generating full logs, as for debugging we just interested in the last bits before any crash.
    # needed to use "tail" because otherwise 10s of GBs of data can be generated!!!
    return  " 2>&1 | tail -n 1000 >> \""+logs+"\" 2>&1"


def createJobs():

    SELECTED_TOOLS = TOOLS

    if TOOL_FILTER is not None:
            filteredconfigs = []
            for c in list(set(TOOL_FILTER.split(","))):
                found = list(filter(lambda x: x.label.lower() == c.lower(), TOOLS))
                if len(found) == 0:
                    raise Exception("ERROR: cannot find the specified tool: "+c)
                filteredconfigs.extend(found)
            SELECTED_TOOLS = filteredconfigs

    port = BASE_SEED
    # 1 for SUT,  1 for JaCoCo TCP server and 1 optional for auth server
    delta = 3
    n = 0

    for sut in SUTS:

        createScriptForBase(sut, port)
        n = n + 1
        port = port + delta

        for seed in range(MIN_SEED, MAX_SEED + 1):

            for tool in SELECTED_TOOLS:

                createScriptForTool(tool, sut, port, seed)
                n = n + 1
                # TODO decide how to handle generated tests, besides Python
                # createPythonTestRunner(tool,sut, port)
                port = port + delta

    print("Number of used SUTs: " + str(len(SUTS)))
    print("Number of used tools: " + str(len(SELECTED_TOOLS)))
    print("Total number of experiment scripts: " + str(n))


def getTestDir(tool_label,sut_name,port):
    return pathlib.PurePath(TESTS_DIR + "/"+ tool_label  + "/" + sut_name + "/" + str(port)).as_posix()


def getReportTimeout(logs, piped):
    if piped:
        # first command in the pipe
        status = "${PIPESTATUS[0]}"
    else:
        # last command
        status = "$?"

    command =  "if [[ " + status + " -eq 124 ]]; then \n"
    command += "  echo \"###################################################################\" >> " + logs + " \n"
    command += "  echo \"### ERROR TIMEOUT: execution of tool was stopped due to timeout ###\" >> " + logs + " \n"
    command += "  echo \"###################################################################\" >> " + logs + " \n"
    command += "fi\n"
    return command


# Needed to get boot-time coverage
def createScriptForBase(sut, port):
    tool_label = "base"

    code = (getScriptHead(port, tool_label, sut, EXEC_ONLINE_DIR)
            # don't run any tool here
            + getScriptFooter(port, tool_label, sut, EXEC_ONLINE_DIR, JACOCO_ONLINE_DIR))
    writeScript(SCRIPT_DIR,code, port, tool_label, sut.name)


def createPythonTestRunner(tool,sut,port):

    TEST_RUNNER_LABEL = "tests-"

    testdir = getTestDir(tool.label,sut.name,port)
    logs = getLogFile("runningtests",TEST_RUNNER_LABEL+tool.label,sut.name,port)

    command = "py -m pytest \"" + testdir +"\" --junitxml=\"" + testdir +"/test-results.xml\" " +  getRedirectLog(logs)

    code = (getScriptHead(port, TEST_RUNNER_LABEL+tool.label, sut, EXEC_TEST_DIR)
            + command
            + getScriptFooter(port, TEST_RUNNER_LABEL+tool.label, sut, EXEC_TEST_DIR, JACOCO_TEST_DIR))
    writeScript(RESULT_SCRIPT_DIR,code, port, tool.label, sut)


def createScriptForTool(tool, sut, port, seed):

    logs = getLogFile("tool",tool.label,sut.name,port)
    testdir = getTestDir(tool.label,sut.name,port)

    if sut.auth:
        original = WFD_DIR + "/auth/"+ sut.name + "-auth.yaml"
        target   = MODIFIED_AUTH + "/" + sut.name + "-auth" + str(port) +".yaml"
        shutil.copy(original, target)
        replace_externalEndpointURL(target, "http://" + LOCALHOST + ":" + str(port+2) )

    ## start tool command
    command = ""
    command += TIMEOUT_COMMAND + " \\\n"
    command += "docker run --rm --memory=4096m --cpus=2 \\\n"
    command += getDockerToolSetup(testdir,DOCKER_OUTPUT_FOLDER,MAX_TIME_SECONDS,LOCALHOST,port,sut,tool.extra_config)
    command += " webfuzzing/"+TOOL_NAME_PREFIX+"-"+tool.name+":"+WFE_VERSION + " \\\n"
    command += getRedirectLog(logs)
    command += "\n\n"
    command += getReportTimeout(logs, True) + "\n\n"

    code = (getScriptHead(port, tool.label, sut, EXEC_ONLINE_DIR)
            + command
            + getScriptFooter(port, tool.label, sut, EXEC_ONLINE_DIR, JACOCO_ONLINE_DIR))
    writeScript(SCRIPT_DIR,code, port, tool.label, sut.name)


def install_WFD():

    foo = BASE_DIR + "/wfd"

    # Run the docker command
    result = subprocess.run(
        ["docker", "run", "--rm", "-v", foo+":/host-dir",
         "webfuzzing/wfd:"+WFD_VERSION, "cp", "-r", "/wfd/.", "/host-dir/"],
        capture_output=True,
        text=True
    )

    if result.returncode == 0:
        print("WFD files installed successfully!")
    else:
        print(f"Error: {result.stderr}")
        raise Exception(f"Docker command failed: {result.stderr}")


# There is a need to override the value of externalEndpointURL in WFC auth configurations.
# Some APIs have authentication services which are run on a different port than PORT.
# As the information in WFC is static, and such port here in the experiments are dynamic,
# there is a need to be able to override such values with the correct dynamic host:port.
def replace_externalEndpointURL(file_path, new_base_url):

    with open(file_path, 'r') as f:
            content = f.read()

    pattern = r'^([ \t]*externalEndpointURL:[ \t]*["\']?)(https?://[^/"\']+)(["\']?.*)$'

    def replace_url(match):
            return match.group(1) + new_base_url + match.group(3)

    new_content = re.sub(pattern, replace_url, content, flags=re.MULTILINE)

    with open(file_path, 'w') as f:
        f.write(new_content)


#############################################################################################
### Entry point of the script after input validation

# first, create needed folders
os.makedirs(LOGS_DIR)
os.makedirs(TESTS_DIR)
os.makedirs(SCRIPT_DIR)
os.makedirs(RESULT_SCRIPT_DIR)
os.makedirs(JACOCO_ONLINE_DIR)
os.makedirs(JACOCO_TEST_DIR)
os.makedirs(EXEC_ONLINE_DIR)
os.makedirs(EXEC_TEST_DIR)
os.makedirs(MODIFIED_AUTH)

install_WFD()

#############################################################################################
### Custom code for experiments
#
# tools to use. comment out the ones which should not be used for these experiments
TOOLS = [
    Tool("aratrl","aratrl",""),
    Tool("cats","cats",""),
    Tool("evomaster","evomaster",""),
    Tool("restler","restler",""),
    Tool("schemathesis","schemathesis",""),
    Tool("wuppiefuzz","wuppiefuzz","")
]

#############################################################################################
# main entry point: create all jobs
createJobs()
