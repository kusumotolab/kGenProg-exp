#!/usr/bin/env python3

# pip3 install pandas
# ./parse.py out kgp math

from pandas import *


def parse(dir, apr, project):
#    extract_real_time_array(dir, apr, project)
#    extract_status_array(dir, apr, project)
    extract_array(dir, apr, project, extract_real_time)
    extract_array(dir, apr, project, extract_status)
    extract_array(dir, apr, project, extract_n_variants)


def extract_array(dir, apr, project, f):
    arr = create_2d_array(dir, apr, project);
    files = list_filtered_files(dir, apr, project)
    for file in files:
        id, seed = extract_id_seed(file, project)
        extract_data = f(file)
        arr[id][seed] = extract_data

    print(pandas.DataFrame(arr).to_csv(sep='\t'))


def create_2d_array(dir, apr, project):
    list_filtered_files(dir, apr, project)

    maxId = 0
    maxSeed = 0

    files = list_filtered_files(dir, apr, project)
    for file in files:
        id, seed = extract_id_seed(file, project)

        maxId = max(maxId, id)
        maxSeed = max(maxSeed, seed)

    return [[""] * (maxSeed+1) for i in range(maxId+1)]


def list_filtered_files(dir, apr, project):
    import glob
    import fnmatch

    files = sorted(glob.glob(dir + '/*'))

    f1 = lambda f: fnmatch.fnmatch(f, '*%s*' % apr)
    f2 = lambda f: fnmatch.fnmatch(f, '*%s*' % project)
    f = lambda f: f1(f) and f2(f)
    return list(filter(f, files))


def extract_n_variants(file):
    import re

    for line in reversed(list(open(file))):
        m = re.search('KGenProgMain - Total Variants: generated (\d+), syntax-valid (\d+), build-succeeded (\d+)', line)
        if m:
            total = int(m.group(1))
            syntax_valid = int(m.group(2))
            build_succeed = int(m.group(3))
            return "%d %d %d" % (total, syntax_valid, build_succeed)


def extract_status(file):
    import re

    status = set()
    for line in reversed(list(open(file))):
        if re.search('java.lang.OutOfMemoryError: GC overhead limit exceeded', line):
            status.add('heap')

        if re.search('Java heap space', line):
            status.add('heap')

        if re.search('KGenProgMain - found enough solutions', line):
            status.add('found')

        if re.search('KGenProgMain - reached the time limit', line):
            status.add('timeout')


    return list(status)


def extract_real_time(file):
    import re

    for line in reversed(list(open(file))):
        m = re.search('^real +(.*)$', line)
        if m:
            return float(m.group(1))
    return 0


def extract_id_seed(file, project):
    import re

    m = re.search('.*%s(\d+)-(\d+).*' % project, file)
    if m:
        return int(m.group(1)), int(m.group(2))
    else:
        raise ValueError(file)


if __name__ == "__main__":
    import sys
    argv = sys.argv
    if (len(argv) != 4):
        print("usage: ./parse.py out kgp math")
        exit()

    parse(dir=argv[1], apr=argv[2], project=argv[3])
