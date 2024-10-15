import pandas as pd

import matplotlib.pyplot as plt

# Load the data from CSV files
pytorch_data = pd.read_csv('output/autodiff/gmm/10k_small/pytorch.csv', delimiter='\t')
mimir_data = pd.read_csv('output/autodiff/gmm/10k_small/mimir.csv', delimiter='\t')
enzyme_data = pd.read_csv('output/autodiff/gmm/10k_small/enzyme.csv', delimiter='\t')

# Calculate size of the data
pytorch_data['size'] = pytorch_data['d'] ** 2 + pytorch_data['k']
# Extract k and d from the file column e.g. gmm_d2_K5 -> d=2, k=5
mimir_data['d'] = mimir_data['file'].str.extract(r'gmm_d(\d+)_K\d+').astype(int)
mimir_data['k'] = mimir_data['file'].str.extract(r'gmm_d\d+_K(\d+)').astype(int)
mimir_data['size'] = mimir_data['d'] ** 2 + mimir_data['k']

enzyme_data['d'] = enzyme_data['file'].str.extract(r'gmm_d(\d+)_K\d+').astype(int)
enzyme_data['k'] = enzyme_data['file'].str.extract(r'gmm_d\d+_K(\d+)').astype(int)
enzyme_data['size'] = enzyme_data['d'] ** 2 + enzyme_data['k']

# Plot the data
plt.figure(figsize=(10, 4))

plt.plot(pytorch_data['size'], pytorch_data['PyTorch'], label='PyTorch 2.0')
plt.plot(mimir_data['size'], mimir_data['time'], label='MimIR')
plt.plot(enzyme_data['size'], enzyme_data['time'], label='Enzyme')

plt.xscale('log')
plt.yscale('log')

plt.xlabel('Size')
plt.ylabel('Time (ms)')
plt.title('Comparison of PyTorch, MimIR, and Enzyme')
plt.legend()

plt.savefig('output/autodiff/gmm.pdf')
