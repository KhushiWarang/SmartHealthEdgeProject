import wfdb

# Record 100 annotations read karo
annotation = wfdb.rdann('../dataset/mitbih/100', 'atr')

print("Total annotation samples:", len(annotation.sample))

print("\nFirst 20 annotation sample positions:")
print(annotation.sample[:20])

print("\nFirst 20 annotation symbols:")
print(annotation.symbol[:20])