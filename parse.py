#!/usr/bin/env python3

# pip3 install pandas
# ./parse.py out kgp math

import pandas as pd


def parse(dir, apr, project):
    status                     = extract_array(dir, apr, project, extract_status, "stt")
    time                       = extract_array(dir, apr, project, extract_real_time, "time")
    n_total_variants           = extract_array(dir, apr, project, extract_n_total_variants, "v")
    n_syntax_valid_variants    = extract_array(dir, apr, project, extract_n_syntax_valid_variants, "v-sv")
    n_build_succeeded_variants = extract_array(dir, apr, project, extract_n_build_succeeded_variants, "v-bs")

    print_arrays([status,
                  time, n_total_variants,
                  n_syntax_valid_variants,
                  n_build_succeeded_variants])


def print_arrays(dfs):
    import re

    base = dfs.pop(0)
    head = list(base.columns.values)
    for df in dfs:
        base = base.join(df)
        head.extend(list(df.columns.values))

    head = map(lambda h: re.sub('\d+$', '', h) ,head)
    print("", *head, sep='\t')
    print(base[1:].to_csv(sep='\t'))


def extract_array(dir, apr, project, func, label):
    arr = create_2d_array(dir, apr, project)
    files = list_filtered_files(dir, apr, project)
    for file in files:
        id, seed = extract_id_seed(file, project)
        extract_data = func(file)
        arr[id][seed] = extract_data

    df = pd.DataFrame(arr)

    # rename column names
    df.columns = ["%s%d" % (label, i) for i in range(df.columns.size)]
    return df


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


def extract_n_build_succeeded_variants(file):
    ''' fileからのbuild_succeededバリアント数の抜き出し '''
    total, syntax_valid, build_succeeded = extract_n_variants(file)
    return build_succeeded

def extract_n_syntax_valid_variants(file):
    ''' fileからのsyntax_validバリアント数の抜き出し '''
    total, syntax_valid, build_succeeded = extract_n_variants(file)
    return syntax_valid

def extract_n_total_variants(file):
    ''' fileからの生成バリアント数の抜き出し '''
    total, syntax_valid, build_succeeded = extract_n_variants(file)
    return total


def extract_n_variants(file):
    ''' fileからのバリアント情報の抜き出し '''
    import re

    total = 0
    syntax_valid = 0
    build_succeed = 0

    for line in open(file):
        m = re.search('Variants: generated (\d+), syntax-valid (\d+), build-succeeded (\d+)', line)
        if m:
            total += int(m.group(1))
            syntax_valid += int(m.group(2))
            build_succeed += int(m.group(3))
            continue

        m = re.search('^NR_GENERATIONS=(\d+)', line)
        if m:
            total = m.group(1)

        m = re.search('^NR_RIGHT_COMPILATIONS=(\d+)', line)
        if m:
            build_succeed = m.group(1)

        # if total and build_succeed:
            # return (total, "", build_succeed)

    return (total, syntax_valid, build_succeed)
    # return "", "", ""


def extract_status(file):
    ''' fileからの実行結果ステータスの抜き出し '''
    import re

    is_astor = False
    contains_status = False

    status = set()
    for line in open(file):
        # kgp
        if re.search('GC overhead limit exceeded', line):
            status.add('e:heap')

        if re.search('Java heap space', line):
            status.add('e:heap')

        if re.search('KGenProgMain - enough solutions', line):
            status.add('found')

        if re.search('KGenProgMain - GA reached the time limit.', line):
            status.add('timeout')

        if re.search('^OUTPUT_STATUS=STOP_BY_PATCH_FOUND', line):
            status.add('found')

        # astor
        if re.search('fr.inria.main.evolution.AstorMain', line):
            is_astor = True

        if re.search('^OUTPUT_STATUS=', line):
            contains_status = True

        if re.search('^OUTPUT_STATUS=ERROR', line):
            status.add('e')

        if re.search('^OUTPUT_STATUS=MAX_GENERATION', line):
            status.add('maxgen')

    #if is_astor and not contains_status:
    #    status.add('e:timeout')

    return list(status)


def extract_real_time(file):
    ''' fileからの実時間の抜き出し '''
    import re

    # for line in open(file): # for faster
    for line in reversed(list(open(file))):
        m = re.search('^real +(.*)$', line)
        if m:
            return float(m.group(1))
    return 0


def extract_id_seed(file, project):
    ''' fileからのプロジェクトidと乱数シードの抜き出し '''
    import re

    m = re.search('.*%s(\d+)(\d+).*' % project, file)
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
