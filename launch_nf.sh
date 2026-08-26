#!/usr/bin/env bash
#SBATCH --no-requeue
#SBATCH --mem 12G
#SBATCH -p genoa64
#SBATCH --qos pipelines
#SBATCH --time=12:00:00
#SBATCH --job-name SVmodeller
set -e
set -u

_term() {
        echo "Caught SIGTERM signal!"
        kill -s SIGTERM $pid
        wait $pid
}

trap _term TERM

export NXF_JVM_ARGS="-Xms2g -Xmx10g"
export NXF_SYNTAX_PARSER=v2
NXF_VER=26.04.1 "$@" & pid=$!

echo "Waiting for ${pid}"
wait $pid

exit 0
