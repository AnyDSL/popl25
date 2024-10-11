import statistics
from collections import defaultdict
from scipy.stats import gmean as geomean

with open("results") as f:
  lines = [l.strip() for l in f.readlines()]

values = []
name = ""

benchs = defaultdict(lambda: dict())

found_bench_start = False

for line in lines:
    if not found_bench_start:
        if line.startswith("BENCHMARKING..."):
            found_bench_start = True
        continue
    if line == "":
        continue
    if line.startswith(">>>"):
        name = line[len(">>> ./"):].split(".")[0]
        values = []
        continue
    if not line.startswith("#"):
        std_dev = statistics.stdev(values)
        bench, lang = name.split("_")
        benchs[bench][lang] = (float(line.replace(",", ".")), std_dev)
        continue
    value = float(line.split()[1].replace(",", "."))  # Convert comma to dot for decimal point
    values.append(value)

print("Benchmark,Speedup,TimeC,StdDevC,TimeImpala,StdDevImpala")
speedups = []
for bench in benchs:
    res = benchs[bench]["c"][0]/benchs[bench]["impala"][0]
    speedups.append(res)
    print(f'{bench},{res},{benchs[bench]["c"][0]},{benchs[bench]["c"][1]},{benchs[bench]["impala"][0]},{benchs[bench]["impala"][1]}')
print(f"overall geomean speedup,{geomean(speedups)},,,,")
