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

    print_arrays([status, \
                  time, n_total_variants, \
                  n_syntax_valid_variants, \
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
    arr = create_2d_array(dir, apr, project);
    files = list_filtered_files(dir, apr, project)
    for file in files:
        id, seed, mutationNum, crossoverNum, crossoverType, parent1Type, parent2Type = extract_various_data(file, project)
        #id, seed = extract_id_seed(file, project)
        extract_data = func(file)
        index = get_index(mutationNum, crossoverNum, crossoverType, parent1Type, parent2Type, seed)
        arr[id][index] = extract_data

    df = pd.DataFrame(arr)

    # rename column names 
    df.columns = ["%s%d" % (label, i) for i in range(df.columns.size)]
    return df

def get_index(mutationNum, crossoverNum, crossoverType, parent1Type, parent2Type, seed):
    box = (seed - 1) * 9;
    if 0 == crossoverNum: return 0 + box
    elif 'Random' == crossoverType and 'Elite' == parent1Type and 'Elite' == parent2Type: return 1 + box;
    elif 'Random' == crossoverType and 'Elite' == parent1Type and 'GeneSimilarity' == parent2Type: return 2  + box;
    elif 'Random' == crossoverType and 'Elite' == parent1Type and 'Random' == parent2Type: return 3  + box;
    elif 'Random' == crossoverType and 'Elite' == parent1Type and 'TestComplementary' == parent2Type: return 4  + box;
    elif 'Random' == crossoverType and 'Random' == parent1Type and 'Elite' == parent2Type: return 5  + box;
    elif 'Random' == crossoverType and 'Random' == parent1Type and 'GeneSimilarity' == parent2Type: return 6  + box;
    elif 'Random' == crossoverType and 'Random' == parent1Type and 'Random' == parent2Type: return 7  + box;
    elif 'Random' == crossoverType and 'Random' == parent1Type and 'TestComplementary' == parent2Type: return 8  + box;
#    elif 'SinglePoint' == crossoverType and 'Elite' == parent1Type and 'Elite' == parent2Type: return 9;
#    elif 'SinglePoint' == crossoverType and 'Elite' == parent1Type and 'GeneSimilarity' == parent2Type: return 10;
#    elif 'SinglePoint' == crossoverType and 'Elite' == parent1Type and 'Random' == parent2Type: return 11;
#    elif 'SinglePoint' == crossoverType and 'Elite' == parent1Type and 'TestComplementary' == parent2Type: return 12;
#    elif 'SinglePoint' == crossoverType and 'Random' == parent1Type and 'Elite' == parent2Type: return 13;
#    elif 'SinglePoint' == crossoverType and 'Random' == parent1Type and 'GeneSimilarity' == parent2Type: return 14;
#    elif 'SinglePoint' == crossoverType and 'Random' == parent1Type and 'Random' == parent2Type: return 15;
#    elif 'SinglePoint' == crossoverType and 'Random' == parent1Type and 'TestComplementary' == parent2Type: return 16;
#    elif 'Uniform' == crossoverType and 'Elite' == parent1Type and 'Elite' == parent2Type: return 17;
#    elif 'Uniform' == crossoverType and 'Elite' == parent1Type and 'GeneSimilarity' == parent2Type: return 18;
#    elif 'Uniform' == crossoverType and 'Elite' == parent1Type and 'Random' == parent2Type: return 19;
#    elif 'Uniform' == crossoverType and 'Elite' == parent1Type and 'TestComplementary' == parent2Type: return 20;
#    elif 'Uniform' == crossoverType and 'Random' == parent1Type and 'Elite' == parent2Type: return 21;
#    elif 'Uniform' == crossoverType and 'Random' == parent1Type and 'GeneSimilarity' == parent2Type: return 22;
#    elif 'Uniform' == crossoverType and 'Random' == parent1Type and 'Random' == parent2Type: return 23;
#    elif 'Uniform' == crossoverType and 'Random' == parent1Type and 'TestComplementary' == parent2Type: return 24;
    else:
        print('error')
        return 100
    

def create_2d_array(dir, apr, project):
    list_filtered_files(dir, apr, project)

    maxId = 0
    maxSeed = 36

    files = list_filtered_files(dir, apr, project)
    for file in files:
        id, seed, mutationNum, crossoverNum, crossoverType, parent1Type, parent2Type = extract_various_data(file, project)        
        maxId = max(maxId, id)

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

    generated = 0;
    syntax_valid = 0;
    build_succeeded = 0;

    for line in open(file):        
        m = re.search('Variants: generated (\d+), syntax-valid (\d+), build-succeeded (\d+)', line)        
        if m:
            generated += int(m.group(1))
            syntax_valid += int(m.group(2))
            build_succeeded += int(m.group(3))

    return generated, syntax_valid, build_succeeded


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

        elif re.search('Java heap space', line):
            status.add('e:heap')

        elif re.search('KGenProgMain - enough solutions have been found', line):
            status.add('found')

        elif re.search('KGenProgMain - GA reached the time limit', line):
            status.add('timeout')

        elif re.search('KGenProgMain - GA reached the maximum generation', line):
            status.add('maxgen')

        else:
            pass

    if len(status) is 0:
        status.add('killed')

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


def extract_various_data(file, project):
    ''' fileからのプロジェクトid，乱数シード，変異数，交叉数，交叉種別，第一親選択方法，第二親選択方法の抜き出し '''
    import re

    m = re.search('.*%s(\d+)-(\d+)-(\d+)-(\d+)-(\w+)-(\w+)-(\w+).*' % project, file)
    if m:
        return int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4)), m.group(5), m.group(6), m.group(7)
    else:
        raise ValueError(file)


if __name__ == "__main__":
    import sys
    argv = sys.argv
    if (len(argv) != 4):
        print("usage: ./parse.py out kgp math")
        exit()

    parse(dir=argv[1], apr=argv[2], project=argv[3])
