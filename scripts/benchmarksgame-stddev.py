import statistics
from collections import defaultdict
from scipy.stats import gmean as geomean

with open("results") as f:
  lines = [l.strip() for l in f.readlines()]

#lines = output.strip().split("\n")
print(lines)
values = []
name = ""

benchs = defaultdict(lambda: dict())

for line in lines:
    if line.startswith(">>>"):
        name = line[len(">>> ./"):].split(".")[0]
        values = []
        continue
    if not line.startswith("#"):
        std_dev = statistics.stdev(values)
        print(f"{name}: Standard Deviation: {std_dev}")
        bench, lang = name.split("_")
        benchs[bench][lang] = float(line.replace(",", "."))
        continue
    value = float(line.split()[1].replace(",", "."))  # Convert comma to dot for decimal point
    values.append(value)

speedups = []
for bench in benchs:
    res = benchs[bench]["c"]/benchs[bench]["impala"]
    speedups.append(res)
    print(f"{bench}: {res}")
print(f"geomean speedup: {geomean(speedups)}")
