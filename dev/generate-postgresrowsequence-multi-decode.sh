#!/bin/bash

set -eu

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function gen() {
    how_many=$1

    if [[ $how_many -ne 1 ]] ; then
        echo ""
    fi

    echo "    @inlinable"
    echo "    @_alwaysEmitIntoClient"
    echo -n "    public func decode<T0: PostgresDecodable"
    for ((n = 1; n<$how_many; n +=1)); do
        echo -n ", T$(($n)): PostgresDecodable"
    done

    echo -n ", JSONDecoder: PostgresJSONDecoder>(_: (T0"
    for ((n = 1; n<$how_many; n +=1)); do
        echo -n ", T$(($n))"
    done
    echo -n ").Type, context: PostgresDecodingContext<JSONDecoder>, file: String = #file, line: Int = #line) "

    echo -n "-> AsyncThrowingMapSequence<PostgresRowSequence, (T0"
    for ((n = 1; n<$how_many; n +=1)); do
        echo -n ", T$(($n))"
    done
    echo ")> {"

    echo "        self.map { row in"

    if [[ $how_many -eq 1 ]] ; then
        echo "            try row.decode(T0.self, context: context, file: file, line: line)"
    else
        echo -n "            try row.decode((T0"

        for ((n = 1; n<$how_many; n +=1)); do
            echo -n ", T$n"
        done
        echo ").self, context: context, file: file, line: line)"

    fi

    echo "        }"
    echo "    }"
}

grep -q "ByteBuffer" "${BASH_SOURCE[0]}" || {
    echo >&2 "ERROR: ${BASH_SOURCE[0]}: file or directory not found (this should be this script)"
    exit 1
}

{
cat <<"EOF"
/// NOTE: THIS FILE IS AUTO-GENERATED BY dev/generate-postgresrowsequence-multi-decode.sh
EOF
echo

echo "#if swift(>=5.5) && canImport(_Concurrency)"
echo "extension PostgresRowSequence {"

# note:
# - widening the inverval below (eg. going from {1..15} to {1..25}) is Semver minor
# - narrowing the interval below is SemVer _MAJOR_!
for n in {1..15}; do
    gen "$n"
done
echo "}"
echo "#endif"
} > "$here/../Sources/PostgresNIO/New/PostgresRowSequence-multi-decode.swift"
